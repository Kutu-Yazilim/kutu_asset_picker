import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/picker/asset_grid.dart';
import 'package:kutu_asset_picker/src/picker/permission_denied_view.dart';
import 'package:kutu_asset_picker/testing.dart';

import '../support/pump_picker.dart';

void main() {
  testWidgets(
      'THE PICKER RESOLVES ITS OWN PROVIDERS UNDER A HOST APP\'S ROOT SCOPE',
      (WidgetTester tester) async {
    // The bug this pins, found on the first run inside PatikaX: a host app
    // that already has a root ProviderScope — every Riverpod app does — made
    // `AssetPickerScope`'s `ProviderScope(overrides: …)` a CHILD scope. A
    // provider that is not itself overridden resolves at the ROOT unless it
    // declares `dependencies`, so `assetPickerPermissionProvider` was read
    // from the host's container, where the injection providers throw by
    // design. The gate rendered that error as "photo access is off" and the
    // OS was never asked. The example app has no root scope, and every test
    // harness put the overrides at the root, which is why nothing caught it.
    final FakeAssetSource source = fakeSourceWith(testAssets(2));
    addTearDown(source.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AssetPickerScope(
            config: const AssetPickerConfig(),
            source: source,
            onCompleted: (AssetPickerResult _) {},
            onCancelled: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PermissionDeniedView), findsNothing,
        reason: 'the fake source granted full access; "denied" here means '
            'the permission provider resolved in the wrong scope');
    expect(find.byType(AssetGrid), findsOneWidget);
  });

  testWidgets('and still works with no host scope at all', (tester) async {
    // The example app's shape, which is the one that always worked.
    final FakeAssetSource source = fakeSourceWith(testAssets(2));
    addTearDown(source.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: AssetPickerScope(
          config: const AssetPickerConfig(),
          source: source,
          onCompleted: (AssetPickerResult _) {},
          onCancelled: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AssetGrid), findsOneWidget);
  });
}
