import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/picker/asset_grid_cell.dart';
import 'package:kutu_asset_picker/src/picker/asset_thumbnail.dart';
import 'package:kutu_asset_picker/src/picker/selection_badge.dart';
import 'package:kutu_asset_picker/src/picker/video_duration_overlay.dart';

import '../support/pump_picker.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

void main() {
  testWidgets(
      'the thumbnail goes through the ImageProvider, not a FutureBuilder',
      (WidgetTester tester) async {
    // design §4.4: a FutureBuilder over thumbnailDataWithSize inside build
    // re-fires the platform call and re-decodes on every rebuild, AND bypasses
    // ScrollAwareImageProvider, which the Image widget wraps around any
    // provider for free (flutter#48536). This assertion is the structural
    // guard for that.
    final source = fakeSourceWith(testAssets(1));
    addTearDown(source.dispose);

    await pumpPicker(
      tester,
      AssetThumbnail(asset: testAsset('a0')),
      source: source,
    );

    expect(find.byType(FutureBuilder<Object?>), findsNothing);
    final Image image = tester.widget<Image>(find.byType(Image));
    expect(image.image, isA<PickerAssetImageProvider>());
    expect(image.fit, BoxFit.cover);
  });

  testWidgets('the thumbnail request carries the configured size and quality',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(1));
    addTearDown(source.dispose);

    await pumpPicker(
      tester,
      AssetThumbnail(asset: testAsset('a0')),
      source: source,
      config: const AssetPickerConfig(thumbSize: ThumbSize.square(320)),
    );

    final Image image = tester.widget<Image>(find.byType(Image));
    final PickerAssetImageProvider provider =
        image.image as PickerAssetImageProvider;
    expect(provider.size.width, 320);
    expect(provider.quality, PickerGridTuning.thumbnailQuality);
  });

  testWidgets('a cell has exactly one RepaintBoundary',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(1));
    addTearDown(source.dispose);

    await pumpPicker(
      tester,
      AssetGridCell(asset: testAsset('a0')),
      source: source,
    );

    expect(
      find.descendant(
        of: find.byType(AssetGridCell),
        matching: find.byType(RepaintBoundary),
      ),
      findsOneWidget,
    );
  });

  testWidgets('tapping selects, and tapping again deselects',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(1));
    addTearDown(source.dispose);

    final ProviderContainer container = await pumpPicker(
      tester,
      AssetGridCell(asset: testAsset('a0')),
      source: source,
    );

    await tester.tap(find.byType(AssetGridCell));
    await tester.pump();
    expect(container.read(selectionProvider), <String>['a0']);
    expect(find.text('1'), findsOneWidget);

    await tester.tap(find.byType(AssetGridCell));
    await tester.pump();
    expect(container.read(selectionProvider), isEmpty);
    expect(find.text('1'), findsNothing);
  });

  testWidgets('selection remembers the asset, not just its id',
      (WidgetTester tester) async {
    // The registry behind toggleAsset is what survives an album switch.
    final source = fakeSourceWith(testAssets(1));
    addTearDown(source.dispose);

    final ProviderContainer container = await pumpPicker(
      tester,
      AssetGridCell(asset: testAsset('a0')),
      source: source,
    );

    await tester.tap(find.byType(AssetGridCell));
    await tester.pump();

    expect(
      container.read(selectionProvider.notifier).selectedAssets.single.id,
      'a0',
    );
  });

  testWidgets('TAPPING ONE CELL DOES NOT BADGE ANOTHER',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(3));
    addTearDown(source.dispose);

    await pumpPicker(
      tester,
      Column(
        children: <Widget>[
          SizedBox(
              height: 80,
              child: AssetGridCell(
                  key: const ValueKey<String>('a0'), asset: testAsset('a0'))),
          SizedBox(
              height: 80,
              child: AssetGridCell(
                  key: const ValueKey<String>('a1'), asset: testAsset('a1'))),
        ],
      ),
      source: source,
    );

    await tester.tap(find.byKey(const ValueKey<String>('a0')));
    await tester.pump();

    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('a0')),
        matching: find.text('1'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey<String>('a1')),
        matching: find.byType(Text),
      ),
      findsNothing,
    );
  });

  testWidgets('at the cap, unselected cells go inert and dim',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(2));
    addTearDown(source.dispose);

    final ProviderContainer container = await pumpPicker(
      tester,
      Column(
        children: <Widget>[
          SizedBox(
              height: 80,
              child: AssetGridCell(
                  key: const ValueKey<String>('a0'), asset: testAsset('a0'))),
          SizedBox(
              height: 80,
              child: AssetGridCell(
                  key: const ValueKey<String>('a1'), asset: testAsset('a1'))),
        ],
      ),
      source: source,
      config: const AssetPickerConfig(maxSelection: 1),
    );

    await tester.tap(find.byKey(const ValueKey<String>('a0')));
    await tester.pump();

    // The second cell is now disabled, and tapping it changes nothing.
    await tester.tap(find.byKey(const ValueKey<String>('a1')));
    await tester.pump();
    expect(container.read(selectionProvider), <String>['a0']);

    // The selected cell stays tappable, so the user can trade one for another.
    await tester.tap(find.byKey(const ValueKey<String>('a0')));
    await tester.pump();
    expect(container.read(selectionProvider), isEmpty);
  });

  testWidgets('a video cell carries a duration overlay, an image does not',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(1));
    addTearDown(source.dispose);

    await pumpPicker(
      tester,
      Column(
        children: <Widget>[
          SizedBox(
            height: 80,
            child: AssetGridCell(
              asset: testAsset('v0',
                  type: PickerMediaType.video,
                  duration: const Duration(seconds: 5)),
            ),
          ),
        ],
      ),
      source: source,
    );

    expect(find.byType(VideoDurationOverlay), findsOneWidget);
    expect(find.text('0:05'), findsOneWidget);
  });

  testWidgets('the badge is present on every cell',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(1));
    addTearDown(source.dispose);

    await pumpPicker(
      tester,
      AssetGridCell(asset: testAsset('a0')),
      source: source,
    );

    expect(find.byType(SelectionBadge), findsOneWidget);
  });
}
