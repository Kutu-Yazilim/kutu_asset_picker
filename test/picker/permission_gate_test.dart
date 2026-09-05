import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/picker/asset_grid.dart';
import 'package:kutu_asset_picker/src/picker/empty_library_view.dart';
import 'package:kutu_asset_picker/src/picker/full_access_body.dart';
import 'package:kutu_asset_picker/src/picker/limited_access_bar.dart';
import 'package:kutu_asset_picker/src/picker/limited_access_body.dart';
import 'package:kutu_asset_picker/src/picker/limited_empty_view.dart';
import 'package:kutu_asset_picker/src/picker/permission_denied_view.dart';
import 'package:kutu_asset_picker/src/picker/permission_gate.dart';
import 'package:kutu_asset_picker/testing.dart';

import '../support/pump_picker.dart';

Future<ProviderContainer> _pumpGate(
  WidgetTester tester, {
  required PickerPermission permission,
  List<PickerAsset> assets = const <PickerAsset>[],
}) async {
  final FakeAssetSource source = fakeSourceWith(assets, permission: permission);
  addTearDown(source.dispose);

  final ProviderContainer container =
      await pumpPicker(tester, const PermissionGate(), source: source);
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('full access renders the grid', (WidgetTester tester) async {
    await _pumpGate(
      tester,
      permission: PickerPermission.full,
      assets: testAssets(6),
    );

    expect(find.byType(FullAccessBody), findsOneWidget);
    expect(find.byType(AssetGrid), findsOneWidget);
    expect(find.byType(LimitedAccessBar), findsNothing);
    expect(find.byType(PermissionDeniedView), findsNothing);
  });

  testWidgets('LIMITED ACCESS RENDERS THE GRID, NOT A FALLBACK SCREEN',
      (WidgetTester tester) async {
    // design §2.10, and the reason wechat_assets_picker#684 has open Play
    // Store rejections attached to it: limited is a designed state.
    await _pumpGate(
      tester,
      permission: PickerPermission.limited,
      assets: testAssets(6),
    );

    expect(find.byType(LimitedAccessBody), findsOneWidget);
    expect(find.byType(AssetGrid), findsOneWidget);
    expect(find.byType(LimitedAccessBar), findsOneWidget);
    expect(find.byType(PermissionDeniedView), findsNothing);
  });

  testWidgets('denied renders the rationale and nothing else',
      (WidgetTester tester) async {
    await _pumpGate(tester, permission: PickerPermission.denied);

    expect(find.byType(PermissionDeniedView), findsOneWidget);
    expect(find.byType(AssetGrid), findsNothing);
    expect(find.text(en.pickerOpenSettings), findsOneWidget);
  });

  testWidgets('THE TWO EMPTY STATES ARE DIFFERENT SCREENS',
      (WidgetTester tester) async {
    // Full access with an empty library is a fact and says so. Limited access
    // with zero results is NOT a fact — it may be a media-kind mismatch the OS
    // refuses to report (design §4.2) — so the two cannot share a screen.
    await _pumpGate(tester, permission: PickerPermission.full);

    expect(find.byType(EmptyLibraryView), findsOneWidget);
    expect(find.byType(LimitedEmptyView), findsNothing);
    expect(find.text(en.pickerEmptyLibrary), findsOneWidget);

    await _pumpGate(tester, permission: PickerPermission.limited);

    expect(find.byType(LimitedEmptyView), findsOneWidget);
    expect(find.byType(EmptyLibraryView), findsNothing);
    expect(find.text(en.pickerEmptyLimited), findsOneWidget);
  });

  testWidgets('a slow permission check shows a spinner, not an empty grid',
      (WidgetTester tester) async {
    final FakeAssetSource source = fakeSourceWith(testAssets(6))
      ..queryDelay = const Duration(milliseconds: 50);
    addTearDown(source.dispose);

    await pumpPicker(tester, const PermissionGate(), source: source);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(EmptyLibraryView), findsNothing);

    await tester.pumpAndSettle();
  });

  testWidgets('granting access from the denied state swaps in the grid',
      (WidgetTester tester) async {
    final FakeAssetSource source = fakeSourceWith(
      testAssets(4),
      permission: PickerPermission.denied,
    );
    addTearDown(source.dispose);

    final ProviderContainer container =
        await pumpPicker(tester, const PermissionGate(), source: source);
    await tester.pumpAndSettle();
    expect(find.byType(PermissionDeniedView), findsOneWidget);

    source.permission = PickerPermission.full;
    container.read(permissionActionsProvider.notifier).recheck();
    await tester.pumpAndSettle();

    expect(find.byType(PermissionDeniedView), findsNothing);
    expect(find.byType(AssetGrid), findsOneWidget);
  });

  testWidgets('the scroll controller is threaded through to the grid',
      (WidgetTester tester) async {
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);
    final FakeAssetSource source = fakeSourceWith(testAssets(6));
    addTearDown(source.dispose);

    await pumpPicker(
      tester,
      PermissionGate(scrollController: controller),
      source: source,
    );
    await tester.pumpAndSettle();

    expect(tester.widget<GridView>(find.byType(GridView)).controller,
        same(controller));
  });
}
