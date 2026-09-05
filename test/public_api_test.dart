import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/testing.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;
import 'package:kutu_asset_picker/src/result/asset_picker_result.dart';

void main() {
  test('every value type a consumer configures is exported', () {
    const AssetPickerConfig config = AssetPickerConfig(
      mediaTypes: <PickerMediaType>{PickerMediaType.image},
      minSelection: 2,
      maxSelection: 4,
      aspects: <CropAspect>[CropAspect.square, CropAspect.custom(21, 9)],
      cropOverlayShape: CropOverlayShape.circle,
      pickerSurface: PickerSurface.sheet,
      thumbSize: ThumbSize.square(200),
    );

    expect(config.effectiveInitialAspect, CropAspect.square);
    expect(config.mediaTypes.single, PickerMediaType.image);
    expect(PickerPermission.limited.hasAccess, isTrue);
    expect(PickerGridTuning.thumbnailQuality, 85);
    expect(PickerChromeSizes.cellRadius, greaterThan(0));
  });

  test('the source seam and its value types are exported', () {
    const PickerAlbum album =
        PickerAlbum(id: 'all', name: 'Recent', assetCount: 1, isAll: true);
    final PickerAsset asset = PickerAsset(
      id: 'a0',
      type: PickerMediaType.image,
      width: 10,
      height: 10,
      createdAt: DateTime.utc(2026, 8, 4),
    );

    expect(album.isAll, isTrue);
    expect(asset.duration, isNull);
    expect(PhotoManagerAssetSource(), isA<AssetSource>());
    expect(const AssetReady(), isA<AssetAvailability>());
  });

  test('the theme and the text delegate are exported and overridable', () {
    const AssetPickerTheme theme = AssetPickerTheme(cellRadius: 9);
    const AssetPickerText text = AssetPickerTextEn();

    expect(theme.copyWith(sheetRadius: 3).cellRadius, 9);
    expect(text.pickerNext, isNotEmpty);
    expect(text.pickerRemove, isNotEmpty);
    expect(text.pickerEmptyLimited, isNot(text.pickerEmptyLibrary));
  });

  test('EVERY PROVIDER A HOST MUST OVERRIDE IS REACHABLE FROM THE BARREL', () {
    // Contract §9. A host that cannot name these from the public entry point
    // cannot mount the picker at all.
    final FakeAssetSource source = FakeAssetSource();
    addTearDown(source.dispose);

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        assetPickerConfigProvider.overrideWithValue(const AssetPickerConfig()),
        assetSourceProvider.overrideWithValue(source),
        pickerCameraDelegateProvider.overrideWithValue(null),
        pickerSettingsOpenerProvider.overrideWithValue(() async {}),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(assetSourceProvider), same(source));
    expect(container.read(mediaTransformProvider), isA<MediaTransform>());
    expect(container.read(selectionProvider), isEmpty);
    expect(container.read(selectionCapReachedProvider), isFalse);
    expect(container.read(selectionIndexProvider('a0')), 0);
    expect(container.read(currentAlbumProvider), isNull);
    expect(container.read(pickerCommitProvider).running, isFalse);
    expect(container.read(pickerLibraryEmptyProvider), isFalse);
  });

  testWidgets('THE EMBEDDABLE WIDGET MOUNTS WITH NO src/ IMPORT ANYWHERE',
      (WidgetTester tester) async {
    // The one thing every other test in this package deliberately does not
    // prove, because they all reach into src/ to get at internals.
    final FakeAssetSource source = FakeAssetSource(
      albumList: const <PickerAlbum>[
        PickerAlbum(id: 'all', name: 'Recent', assetCount: 0, isAll: true),
      ],
      assetsByAlbum: <String, List<PickerAsset>>{'all': const <PickerAsset>[]},
    );
    addTearDown(source.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          assetPickerConfigProvider
              .overrideWithValue(const AssetPickerConfig()),
          assetSourceProvider.overrideWithValue(source),
        ],
        child: MaterialApp(
          home: AssetPickerView(onCompleted: (AssetPickerResult _) {}),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(PickerGridStep), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
