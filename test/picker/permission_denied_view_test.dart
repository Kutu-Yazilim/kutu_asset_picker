import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/picker/permission_denied_view.dart';

import '../support/pump_picker.dart';

void main() {
  testWidgets('states the rationale and offers the way out',
      (WidgetTester tester) async {
    final source = fakeSourceWith(
      testAssets(0),
      permission: PickerPermission.denied,
    );
    addTearDown(source.dispose);

    await pumpPicker(tester, const PermissionDeniedView(), source: source);

    expect(find.text(en.pickerPermissionDeniedTitle), findsOneWidget);
    expect(find.text(en.pickerPermissionDeniedBody), findsOneWidget);
    expect(find.text(en.pickerOpenSettings), findsOneWidget);
  });

  testWidgets('open settings runs the injected opener and re-checks',
      (WidgetTester tester) async {
    final source = fakeSourceWith(
      testAssets(0),
      permission: PickerPermission.denied,
    );
    addTearDown(source.dispose);

    int opened = 0;
    final ProviderContainer container = await pumpPicker(
      tester,
      const PermissionDeniedView(),
      source: source,
      extraOverrides: <Override>[
        pickerSettingsOpenerProvider.overrideWithValue(() async {
          opened += 1;
          source.permission = PickerPermission.full;
        }),
      ],
    );
    await container.read(assetPickerPermissionProvider.future);

    await tester.tap(find.text(en.pickerOpenSettings));
    await tester.pumpAndSettle();

    expect(opened, 1);
    expect(await container.read(assetPickerPermissionProvider.future),
        PickerPermission.full);
  });

  testWidgets('A RESUME RE-CHECKS PERMISSION WITH NO TAP AT ALL',
      (WidgetTester tester) async {
    // The user can reach Settings through the app switcher, flip the grant and
    // come back without ever touching this screen's button. Without the
    // lifecycle hook they return to a denied screen that is now lying to them.
    final source = fakeSourceWith(
      testAssets(0),
      permission: PickerPermission.denied,
    );
    addTearDown(source.dispose);

    final ProviderContainer container =
        await pumpPicker(tester, const PermissionDeniedView(), source: source);
    expect(await container.read(assetPickerPermissionProvider.future),
        PickerPermission.denied);
    expect(source.permissionRequests, hasLength(1));

    source.permission = PickerPermission.limited;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(await container.read(assetPickerPermissionProvider.future),
        PickerPermission.limited);
    expect(source.permissionRequests, hasLength(2));
  });

  testWidgets('an inactive or paused lifecycle event re-checks nothing',
      (WidgetTester tester) async {
    final source = fakeSourceWith(
      testAssets(0),
      permission: PickerPermission.denied,
    );
    addTearDown(source.dispose);

    final ProviderContainer container =
        await pumpPicker(tester, const PermissionDeniedView(), source: source);
    await container.read(assetPickerPermissionProvider.future);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();

    expect(source.permissionRequests, hasLength(1),
        reason: 'leaving the app is not a permission event; coming back is');
  });

  testWidgets('the observer is removed when the view goes away',
      (WidgetTester tester) async {
    final source = fakeSourceWith(
      testAssets(0),
      permission: PickerPermission.denied,
    );
    addTearDown(source.dispose);

    final ProviderContainer container =
        await pumpPicker(tester, const PermissionDeniedView(), source: source);
    await container.read(assetPickerPermissionProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: Scaffold(body: SizedBox.shrink())),
      ),
    );
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(source.permissionRequests, hasLength(1),
        reason: 'a leaked WidgetsBindingObserver keeps re-requesting '
            'permission for a screen that no longer exists');
  });

  testWidgets('the colours come from the theme, never from Colors.*',
      (WidgetTester tester) async {
    const Color brand = Color(0xFF00A86B);
    final source = fakeSourceWith(
      testAssets(0),
      permission: PickerPermission.denied,
    );
    addTearDown(source.dispose);

    await pumpPicker(
      tester,
      const PermissionDeniedView(),
      source: source,
      theme: ThemeData(
        extensions: const <ThemeExtension<dynamic>>[
          AssetPickerTheme(onSurfaceMuted: brand),
        ],
      ),
    );

    expect(
      tester
          .widget<Icon>(find.descendant(
            of: find.byType(PermissionDeniedView),
            matching: find.byType(Icon),
          ))
          .color,
      brand,
    );
  });
}
