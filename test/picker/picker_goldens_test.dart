import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/picker/asset_grid_cell.dart';
import 'package:kutu_asset_picker/src/picker/limited_access_body.dart';
import 'package:kutu_asset_picker/src/picker/permission_denied_view.dart';
import 'package:kutu_asset_picker/src/picker/selection_badge.dart';
import 'package:kutu_asset_picker/testing.dart';

import '../support/pump_picker.dart';

/// Both directions of every surface. A token that reads fine on white and
/// disappears on black is the failure mode goldens are cheapest at catching.
const Map<String, bool> _modes = <String, bool>{'light': false, 'dark': true};

/// Tears the picker down inside the test and pumps once, so the auto-dispose
/// timer Riverpod schedules for the per-cell `selectionIndex` family fires
/// here rather than being reported as pending after the tree is gone.
Future<void> _unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  // pump() only flushes microtasks; the zero-length timer needs fake time.
  await tester.pumpAndSettle();
}

Future<void> _expectGolden(WidgetTester tester, String name) => expectLater(
    find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));

void main() {
  testWidgets('selection badge, empty and numbered',
      (WidgetTester tester) async {
    for (final MapEntry<String, bool> mode in _modes.entries) {
      final FakeAssetSource source = fakeSourceWith(testAssets(1));
      addTearDown(source.dispose);

      await pumpPicker(
        tester,
        const Center(child: SelectionBadge(index: 0)),
        source: source,
        theme: mode.value ? ThemeData.dark() : ThemeData.light(),
      );
      await tester.pumpAndSettle();
      await _expectGolden(tester, 'selection_badge_empty_${mode.key}');

      await pumpPicker(
        tester,
        const Center(child: SelectionBadge(index: 3)),
        source: source,
        theme: mode.value ? ThemeData.dark() : ThemeData.light(),
      );
      await tester.pumpAndSettle();
      await _expectGolden(tester, 'selection_badge_numbered_${mode.key}');
    }
    await _unmount(tester);
  });

  testWidgets('grid cell: unselected, selected, and cap-reached',
      (WidgetTester tester) async {
    for (final MapEntry<String, bool> mode in _modes.entries) {
      final FakeAssetSource source = fakeSourceWith(testAssets(2));
      addTearDown(source.dispose);

      final ProviderContainer container = await pumpPicker(
        tester,
        Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child: AssetGridCell(asset: testAsset('a0')),
          ),
        ),
        source: source,
        config: const AssetPickerConfig(maxSelection: 1),
        theme: mode.value ? ThemeData.dark() : ThemeData.light(),
      );
      await tester.pumpAndSettle();
      await _expectGolden(tester, 'grid_cell_unselected_${mode.key}');

      container.read(selectionProvider.notifier).toggleAsset(testAsset('a0'));
      await tester.pumpAndSettle();
      await _expectGolden(tester, 'grid_cell_selected_${mode.key}');
    }
    await _unmount(tester);
  });

  testWidgets('grid cell at the cap is dimmed and inert',
      (WidgetTester tester) async {
    for (final MapEntry<String, bool> mode in _modes.entries) {
      final FakeAssetSource source = fakeSourceWith(testAssets(2));
      addTearDown(source.dispose);

      final ProviderContainer container = await pumpPicker(
        tester,
        Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child: AssetGridCell(asset: testAsset('a1')),
          ),
        ),
        source: source,
        config: const AssetPickerConfig(maxSelection: 1),
        theme: mode.value ? ThemeData.dark() : ThemeData.light(),
      );
      // 'a0' fills the cap, so the cell under test is the disabled one.
      container.read(selectionProvider.notifier).toggleAsset(testAsset('a0'));
      await tester.pumpAndSettle();

      await _expectGolden(tester, 'grid_cell_cap_reached_${mode.key}');
    }
    await _unmount(tester);
  });

  testWidgets('the denied state', (WidgetTester tester) async {
    for (final MapEntry<String, bool> mode in _modes.entries) {
      final FakeAssetSource source = fakeSourceWith(
        const <PickerAsset>[],
        permission: PickerPermission.denied,
      );
      addTearDown(source.dispose);

      await pumpPicker(
        tester,
        const PermissionDeniedView(),
        source: source,
        theme: mode.value ? ThemeData.dark() : ThemeData.light(),
      );
      await tester.pumpAndSettle();

      await _expectGolden(tester, 'permission_denied_${mode.key}');
    }
    await _unmount(tester);
  });

  testWidgets('the limited state, bar and empty view together',
      (WidgetTester tester) async {
    for (final MapEntry<String, bool> mode in _modes.entries) {
      final FakeAssetSource source = fakeSourceWith(
        const <PickerAsset>[],
        permission: PickerPermission.limited,
      );
      addTearDown(source.dispose);

      await pumpPicker(
        tester,
        const LimitedAccessBody(),
        source: source,
        theme: mode.value ? ThemeData.dark() : ThemeData.light(),
      );
      await tester.pumpAndSettle();

      await _expectGolden(tester, 'limited_empty_${mode.key}');
    }
    await _unmount(tester);
  });
}
