import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/picker/asset_picker_page.dart';
import 'package:kutu_asset_picker/src/picker/asset_picker_sheet.dart';

import '../support/pump_picker.dart';
import 'package:kutu_asset_picker/src/source/fake_asset_source.dart';
import 'package:kutu_asset_picker/src/result/asset_picker_result.dart';
import 'package:kutu_asset_picker/src/view/picker_step_controller.dart';
import 'package:kutu_asset_picker/src/crop/crop_providers.dart';

void main() {
  testWidgets('the page surface hosts the grid step in a scaffold',
      (WidgetTester tester) async {
    final FakeAssetSource source = fakeSourceWith(testAssets(4));
    addTearDown(source.dispose);

    await pumpPicker(
      tester,
      PickerGridStep(onNext: () {}, onCancel: () {}),
      source: source,
      wrapInScaffold: false,
    );
    await tester.pumpAndSettle();

    expect(find.byType(AssetPickerPage), findsOneWidget);
    expect(find.byType(AssetPickerSheet), findsNothing);
  });

  testWidgets('the sheet surface hosts the grid step in a draggable sheet',
      (WidgetTester tester) async {
    final FakeAssetSource source = fakeSourceWith(testAssets(4));
    addTearDown(source.dispose);

    await pumpPicker(
      tester,
      PickerGridStep(onNext: () {}, onCancel: () {}),
      source: source,
      config: const AssetPickerConfig(pickerSurface: PickerSurface.sheet),
      wrapInScaffold: false,
    );
    await tester.pumpAndSettle();

    expect(find.byType(AssetPickerSheet), findsOneWidget);
    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(find.byType(AssetPickerPage), findsNothing);
  });

  testWidgets('the view mounts the grid step and nothing else',
      (WidgetTester tester) async {
    final FakeAssetSource source = fakeSourceWith(testAssets(4));
    addTearDown(source.dispose);

    await pumpPicker(
      tester,
      AssetPickerView(onCompleted: (AssetPickerResult _) {}),
      source: source,
      wrapInScaffold: false,
    );
    await tester.pumpAndSettle();

    expect(find.byType(PickerGridStep), findsOneWidget);
  });

  testWidgets('cancel reaches the host callback', (WidgetTester tester) async {
    final FakeAssetSource source = fakeSourceWith(testAssets(2));
    addTearDown(source.dispose);

    int cancelled = 0;
    await pumpPicker(
      tester,
      AssetPickerView(
        onCompleted: (AssetPickerResult _) {},
        onCancelled: () => cancelled += 1,
      ),
      source: source,
      wrapInScaffold: false,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(en.pickerCancel));
    await tester.pumpAndSettle();

    expect(cancelled, 1);
  });

  testWidgets('THE VIEW BRINGS NO ProviderScope OF ITS OWN',
      (WidgetTester tester) async {
    // Contract §9: the host owns the scope. A view that created one would
    // shadow the consumer's overrides and quietly run on a different config
    // than the one they configured.
    final FakeAssetSource source = fakeSourceWith(testAssets(2));
    addTearDown(source.dispose);

    await pumpPicker(
      tester,
      AssetPickerView(onCompleted: (AssetPickerResult _) {}),
      source: source,
      wrapInScaffold: false,
    );
    await tester.pumpAndSettle();

    expect(find.byType(ProviderScope), findsNothing);
  });

  testWidgets('NEXT ADVANCES TO THE CROP STEP INSTEAD OF COMPLETING',
      (WidgetTester tester) async {
    final FakeAssetSource source = fakeSourceWith(testAssets(4));
    addTearDown(source.dispose);

    AssetPickerResult? delivered;
    final ProviderContainer container = await pumpPicker(
      tester,
      AssetPickerView(
        onCompleted: (AssetPickerResult result) => delivered = result,
      ),
      source: source,
      wrapInScaffold: false,
    );
    await tester.pumpAndSettle();

    container.read(selectionProvider.notifier)
      ..toggleAsset(testAsset('a2'))
      ..toggleAsset(testAsset('a0'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(en.pickerNext));
    await tester.pumpAndSettle();

    // The result arrives from the export controller, not from Next.
    expect(delivered, isNull);
    expect(container.read(pickerStepControllerProvider), AssetPickerStep.crop);
    expect(find.byType(PickerGridStep), findsNothing);
  });

  testWidgets('THE CROP STEP EDITS THE SELECTION IN SELECTION ORDER',
      (WidgetTester tester) async {
    final FakeAssetSource source = fakeSourceWith(testAssets(4));
    addTearDown(source.dispose);

    final ProviderContainer container = await pumpPicker(
      tester,
      AssetPickerView(onCompleted: (AssetPickerResult _) {}),
      source: source,
      wrapInScaffold: false,
    );
    await tester.pumpAndSettle();

    container.read(selectionProvider.notifier)
      ..toggleAsset(testAsset('a0'))
      ..toggleAsset(testAsset('a1'))
      ..reorder(1, 0);
    await tester.pumpAndSettle();

    await tester.tap(find.text(en.pickerNext));
    await tester.pumpAndSettle();

    expect(
      container.read(selectedAssetsProvider).map((PickerAsset a) => a.id),
      <String>['a1', 'a0'],
    );
  });
}
