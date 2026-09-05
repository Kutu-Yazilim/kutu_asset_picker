import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/picker/selected_strip.dart';
import 'package:kutu_asset_picker/src/picker/selected_strip_tile.dart';

import '../support/pump_picker.dart';

ReorderableListView _list(WidgetTester tester) =>
    tester.widget<ReorderableListView>(find.byType(ReorderableListView));

void main() {
  testWidgets('an empty selection renders nothing',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(3));
    addTearDown(source.dispose);

    await pumpPicker(tester, const SelectedStrip(), source: source);

    expect(find.byType(SelectedStripTile), findsNothing);
    expect(find.byType(ReorderableListView), findsNothing);
  });

  testWidgets('one tile per selected asset, in selection order',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(3));
    addTearDown(source.dispose);

    final ProviderContainer container =
        await pumpPicker(tester, const SelectedStrip(), source: source);
    container.read(selectionProvider.notifier)
      ..toggleAsset(testAsset('a2'))
      ..toggleAsset(testAsset('a0'));
    await tester.pumpAndSettle();

    expect(find.byType(SelectedStripTile), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.byKey(const ValueKey<String>('a2'))).dx,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey<String>('a0'))).dx),
      reason: 'the strip is selection order, not library order',
    );
  });

  testWidgets('REORDER USES THE PRE-REMOVAL INDEX CONVENTION',
      (WidgetTester tester) async {
    // ReorderableListView reports the destination as an insertion point in the
    // list BEFORE the dragged item is removed, so a forward move is always one
    // index too high. Selection.reorder owns that correction; re-applying it
    // here would land the item one slot short — which reads as a flaky drag,
    // not as a bug.
    final source = fakeSourceWith(testAssets(3));
    addTearDown(source.dispose);

    final ProviderContainer container =
        await pumpPicker(tester, const SelectedStrip(), source: source);
    container.read(selectionProvider.notifier)
      ..toggleAsset(testAsset('a0'))
      ..toggleAsset(testAsset('a1'))
      ..toggleAsset(testAsset('a2'));
    await tester.pumpAndSettle();

    _list(tester).onReorderItem!(0, 1);
    await tester.pumpAndSettle();

    expect(container.read(selectionProvider), <String>['a1', 'a0', 'a2']);

    _list(tester).onReorderItem!(2, 0);
    await tester.pumpAndSettle();

    expect(container.read(selectionProvider), <String>['a2', 'a1', 'a0']);
  });

  testWidgets('a reorder is visible in the strip immediately',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(2));
    addTearDown(source.dispose);

    final ProviderContainer container =
        await pumpPicker(tester, const SelectedStrip(), source: source);
    container.read(selectionProvider.notifier)
      ..toggleAsset(testAsset('a0'))
      ..toggleAsset(testAsset('a1'));
    await tester.pumpAndSettle();

    _list(tester).onReorderItem!(1, 0);
    await tester.pumpAndSettle();

    expect(
      tester.getTopLeft(find.byKey(const ValueKey<String>('a1'))).dx,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey<String>('a0'))).dx),
    );
  });

  testWidgets('the remove affordance deselects that asset only',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(3));
    addTearDown(source.dispose);

    final ProviderContainer container =
        await pumpPicker(tester, const SelectedStrip(), source: source);
    container.read(selectionProvider.notifier)
      ..toggleAsset(testAsset('a0'))
      ..toggleAsset(testAsset('a1'))
      ..toggleAsset(testAsset('a2'));
    await tester.pumpAndSettle();

    await tester.tap(find.descendant(
      of: find.byKey(const ValueKey<String>('a1')),
      matching: find.byTooltip(en.pickerRemove),
    ));
    await tester.pumpAndSettle();

    expect(container.read(selectionProvider), <String>['a0', 'a2']);
    expect(find.byType(SelectedStripTile), findsNWidgets(2));
  });

  testWidgets('removing the last selected asset empties the strip',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(1));
    addTearDown(source.dispose);

    final ProviderContainer container =
        await pumpPicker(tester, const SelectedStrip(), source: source);
    container.read(selectionProvider.notifier).toggleAsset(testAsset('a0'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(en.pickerRemove));
    await tester.pumpAndSettle();

    expect(container.read(selectionProvider), isEmpty);
    expect(find.byType(ReorderableListView), findsNothing);
  });

  testWidgets(
      'the strip has a fixed height, so the grid never resizes under it',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(2));
    addTearDown(source.dispose);

    final ProviderContainer container =
        await pumpPicker(tester, const SelectedStrip(), source: source);
    container.read(selectionProvider.notifier).toggleAsset(testAsset('a0'));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(SelectedStrip)).height,
        PickerChromeSizes.selectedStripHeight);
  });
}
