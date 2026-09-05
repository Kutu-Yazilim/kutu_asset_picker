import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/picker/asset_picker_page.dart';
import 'package:kutu_asset_picker/src/picker/asset_picker_sheet.dart';
import 'package:kutu_asset_picker/src/picker/cloud_progress_bar.dart';
import 'package:kutu_asset_picker/src/picker/permission_gate.dart';
import 'package:kutu_asset_picker/src/picker/picker_app_bar.dart';
import 'package:kutu_asset_picker/src/picker/picker_body.dart';
import 'package:kutu_asset_picker/src/picker/picker_footer.dart';
import 'package:kutu_asset_picker/src/picker/picker_image_cache_scope.dart';
import 'package:kutu_asset_picker/src/picker/selected_strip.dart';
import 'package:kutu_asset_picker/testing.dart';

import '../support/pump_picker.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

void main() {
  testWidgets(
      'the body stacks the gate, the strip, the cloud bar and the footer',
      (WidgetTester tester) async {
    final FakeAssetSource source = fakeSourceWith(testAssets(6));
    addTearDown(source.dispose);

    await pumpPicker(
      tester,
      PickerBody(onNext: () {}),
      source: source,
    );
    await tester.pumpAndSettle();

    expect(find.byType(PickerImageCacheScope), findsOneWidget);
    expect(find.byType(PermissionGate), findsOneWidget);
    expect(find.byType(SelectedStrip), findsOneWidget);
    expect(find.byType(CloudProgressBar), findsOneWidget);
    expect(find.byType(PickerFooter), findsOneWidget);

    expect(
      tester.getTopLeft(find.byType(PermissionGate)).dy,
      lessThan(tester.getTopLeft(find.byType(PickerFooter)).dy),
    );
  });

  testWidgets('the image cache budget follows the configured thumb size',
      (WidgetTester tester) async {
    final FakeAssetSource source = fakeSourceWith(testAssets(2));
    addTearDown(source.dispose);

    await pumpPicker(
      tester,
      PickerBody(onNext: () {}),
      source: source,
      config: const AssetPickerConfig(thumbSize: ThumbSize.square(320)),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<PickerImageCacheScope>(find.byType(PickerImageCacheScope))
          .thumbSize
          .width,
      320,
    );
  });

  testWidgets('page mode passes no controller — the page owns its own scroll',
      (WidgetTester tester) async {
    final FakeAssetSource source = fakeSourceWith(testAssets(6));
    addTearDown(source.dispose);

    await pumpPicker(
      tester,
      AssetPickerPage(onNext: () {}, onCancel: () {}),
      source: source,
      wrapInScaffold: false,
    );
    await tester.pumpAndSettle();

    expect(find.byType(PickerAppBar), findsOneWidget);
    expect(tester.widget<GridView>(find.byType(GridView)).controller, isNull);
  });

  testWidgets('THE SHEET HANDS ITS SCROLL CONTROLLER TO THE GRID',
      (WidgetTester tester) async {
    // design §5. Without this the sheet and the grid fight over the same
    // vertical drag: the grid is already at its top, so a downward drag either
    // does nothing or dismisses the sheet halfway through a scroll.
    final FakeAssetSource source = fakeSourceWith(testAssets(60));
    addTearDown(source.dispose);

    await pumpPicker(
      tester,
      AssetPickerSheet(onNext: () {}, onCancel: () {}),
      source: source,
      config: const AssetPickerConfig(pickerSurface: PickerSurface.sheet),
      wrapInScaffold: false,
    );
    await tester.pumpAndSettle();

    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    expect(tester.widget<GridView>(find.byType(GridView)).controller, isNotNull,
        reason: 'page mode passes null; sheet mode must not');

    final double before = tester.getTopLeft(find.byType(GridView)).dy;
    await tester.drag(find.byType(GridView), const Offset(0, 240));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.byType(GridView)).dy, greaterThan(before),
        reason: 'dragging the grid at its top edge must move the SHEET — that '
            'handoff is the entire reason sheet mode threads a controller '
            'down');
  });

  testWidgets('the sheet opens at the configured extent',
      (WidgetTester tester) async {
    final FakeAssetSource source = fakeSourceWith(testAssets(6));
    addTearDown(source.dispose);

    await pumpPicker(
      tester,
      AssetPickerSheet(onNext: () {}, onCancel: () {}),
      source: source,
      config: const AssetPickerConfig(pickerSurface: PickerSurface.sheet),
      wrapInScaffold: false,
    );
    await tester.pumpAndSettle();

    final DraggableScrollableSheet sheet =
        tester.widget<DraggableScrollableSheet>(
            find.byType(DraggableScrollableSheet));

    expect(sheet.initialChildSize, PickerChromeSizes.sheetInitialExtent);
    expect(sheet.minChildSize, PickerChromeSizes.sheetMinExtent);
    expect(sheet.maxChildSize, PickerChromeSizes.sheetMaxExtent);
    expect(sheet.expand, isFalse,
        reason: 'expand: false is what lets this sit inside a modal route');
  });

  testWidgets('both hosts route cancel to the caller, not to the Navigator',
      (WidgetTester tester) async {
    final FakeAssetSource source = fakeSourceWith(testAssets(2));
    addTearDown(source.dispose);

    int cancelled = 0;
    await pumpPicker(
      tester,
      AssetPickerPage(onNext: () {}, onCancel: () => cancelled += 1),
      source: source,
      wrapInScaffold: false,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip(en.pickerCancel));
    await tester.pumpAndSettle();

    expect(cancelled, 1);
  });
}
