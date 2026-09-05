import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/picker/asset_grid.dart';
import 'package:kutu_asset_picker/src/picker/limited_access_bar.dart';
import 'package:kutu_asset_picker/src/picker/limited_access_body.dart';
import 'package:kutu_asset_picker/src/picker/limited_empty_view.dart';
import 'package:kutu_asset_picker/testing.dart';

import '../support/pump_picker.dart';

Future<ProviderContainer> _pumpLimited(
  WidgetTester tester,
  List<PickerAsset> assets,
) async {
  final FakeAssetSource source = fakeSourceWith(
    assets,
    permission: PickerPermission.limited,
  );
  addTearDown(source.dispose);

  final ProviderContainer container = await pumpPicker(
    tester,
    const LimitedAccessBody(),
    source: source,
  );
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('the bar is permanent — it sits above a populated grid too',
      (WidgetTester tester) async {
    // design §2.10: limited is a designed state rendering THE SAME grid, not a
    // degraded fallback screen.
    await _pumpLimited(tester, testAssets(6));

    expect(find.byType(LimitedAccessBar), findsOneWidget);
    expect(find.byType(AssetGrid), findsOneWidget);
    expect(find.byType(LimitedEmptyView), findsNothing);
    expect(find.text(en.pickerLimitedBanner), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(LimitedAccessBar)).dy,
      lessThan(tester.getTopLeft(find.byType(AssetGrid)).dy),
    );
  });

  testWidgets('Manage selection presents the OS UI and re-queries albums',
      (WidgetTester tester) async {
    final FakeAssetSource source = fakeSourceWith(
      testAssets(6),
      permission: PickerPermission.limited,
    );
    addTearDown(source.dispose);

    await pumpPicker(tester, const LimitedAccessBody(), source: source);
    await tester.pumpAndSettle();
    expect(source.albumQueries, hasLength(1));

    await tester.tap(find.text(en.pickerManageSelection));
    await tester.pumpAndSettle();

    expect(source.manageLimitedSelectionCalls, 1);
    expect(source.albumQueries, hasLength(2),
        reason: 'presentLimited leaves album lists and counts stale '
            '(design §4.2)');
  });

  testWidgets('THE LIMITED EMPTY STATE NEVER SAYS NO PHOTOS FOUND',
      (WidgetTester tester) async {
    // design §4.2: neither OS reports which media kinds are in a limited
    // selection. Request images, have the user grant only videos, and the
    // platform returns `limited` plus zero results — indistinguishable from an
    // empty library. This test fails the moment someone "helpfully" swaps the
    // copy for the full-access empty string or hardcodes a friendlier line.
    await _pumpLimited(tester, const <PickerAsset>[]);

    expect(find.byType(LimitedEmptyView), findsOneWidget);
    expect(find.text(en.pickerEmptyLimited), findsOneWidget);
    expect(find.text(en.pickerEmptyLibrary), findsNothing);

    final Iterable<String> rendered = tester
        .widgetList<Text>(find.byType(Text))
        .map((Text widget) => (widget.data ?? '').toLowerCase());

    expect(rendered.any((String line) => line.contains('no photos')), isFalse);
    expect(rendered.any((String line) => line.contains('no videos')), isFalse);
    expect(rendered.any((String line) => line.contains('empty')), isFalse);
    expect(
        rendered.any((String line) => line.contains('nothing found')), isFalse);
  });

  testWidgets('the empty state offers Manage selection, and it works',
      (WidgetTester tester) async {
    final FakeAssetSource source = fakeSourceWith(
      const <PickerAsset>[],
      permission: PickerPermission.limited,
    );
    addTearDown(source.dispose);

    await pumpPicker(tester, const LimitedAccessBody(), source: source);
    await tester.pumpAndSettle();

    // Once in the bar, once as the empty state's own primary action.
    expect(find.text(en.pickerManageSelection), findsNWidgets(2));

    await tester.tap(find.descendant(
      of: find.byType(LimitedEmptyView),
      matching: find.text(en.pickerManageSelection),
    ));
    await tester.pumpAndSettle();

    expect(source.manageLimitedSelectionCalls, 1);
  });

  testWidgets(
      'adding items through the OS UI turns the empty state into a grid',
      (WidgetTester tester) async {
    final FakeAssetSource source = fakeSourceWith(
      const <PickerAsset>[],
      permission: PickerPermission.limited,
    );
    addTearDown(source.dispose);

    await pumpPicker(tester, const LimitedAccessBody(), source: source);
    await tester.pumpAndSettle();
    expect(find.byType(LimitedEmptyView), findsOneWidget);

    // The user grants two more items while they are away.
    source.assetsByAlbum['all'] = testAssets(2);
    source.albumList = const <PickerAlbum>[
      PickerAlbum(id: 'all', name: 'Recent', assetCount: 2, isAll: true),
    ];

    await tester.tap(find.text(en.pickerManageSelection).first);
    await tester.pumpAndSettle();

    expect(find.byType(LimitedEmptyView), findsNothing);
    expect(find.byType(AssetGrid), findsOneWidget);
  });

  testWidgets('the bar reads its colours from the theme',
      (WidgetTester tester) async {
    const Color brand = Color(0xFF00A86B);
    final FakeAssetSource source = fakeSourceWith(
      testAssets(2),
      permission: PickerPermission.limited,
    );
    addTearDown(source.dispose);

    await pumpPicker(
      tester,
      const LimitedAccessBar(),
      source: source,
      theme: ThemeData(
        extensions: const <ThemeExtension<dynamic>>[
          AssetPickerTheme(surface: brand),
        ],
      ),
    );

    expect(
      tester
          .widget<ColoredBox>(find.descendant(
            of: find.byType(LimitedAccessBar),
            matching: find.byType(ColoredBox),
          ))
          .color,
      brand,
    );
  });
}
