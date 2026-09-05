import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

void main() {
  group('CropAspect', () {
    test('exposes the five named shapes with the right ratios', () {
      expect(CropAspect.square.ratio, 1.0);
      expect(CropAspect.portrait45.ratio, closeTo(0.8, 1e-9));
      expect(CropAspect.landscape169.ratio, closeTo(16 / 9, 1e-9));
      expect(CropAspect.story916.ratio, closeTo(9 / 16, 1e-9));
      expect(CropAspect.banner31.ratio, closeTo(3.0, 1e-9));
    });

    test('labels each named shape', () {
      expect(CropAspect.square.label, CropAspectLabel.square);
      expect(CropAspect.portrait45.label, CropAspectLabel.portrait);
      expect(CropAspect.landscape169.label, CropAspectLabel.landscape);
      expect(CropAspect.story916.label, CropAspectLabel.story);
      expect(CropAspect.banner31.label, CropAspectLabel.banner);
    });

    test('custom carries the custom label and compares by value', () {
      const CropAspect a = CropAspect.custom(21, 9);
      const CropAspect b = CropAspect.custom(21, 9);
      expect(a.label, CropAspectLabel.custom);
      expect(a.ratio, closeTo(21 / 9, 1e-9));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(CropAspect.square)));
    });
  });

  group('AssetPickerConfig', () {
    test('defaults match the contract', () {
      const AssetPickerConfig config = AssetPickerConfig();

      expect(config.mediaTypes,
          <PickerMediaType>{PickerMediaType.image, PickerMediaType.video});
      expect(config.minSelection, 1);
      expect(config.maxSelection, 10);
      expect(config.aspects, <CropAspect>[
        CropAspect.square,
        CropAspect.portrait45,
        CropAspect.landscape169,
      ]);
      expect(config.initialAspect, isNull);
      expect(config.allowPerAssetAspect, isTrue);
      expect(config.cropOverlayShape, CropOverlayShape.rectangle);
      expect(config.gridColumns, 3);
      expect(config.cellAspectRatio, 1.0);
      expect(config.gridSpacing, 2.0);
      expect(config.pickerSurface, PickerSurface.page);
      expect(config.cropSurface, PickerSurface.page);
      expect(config.enableCamera, isTrue);
      expect(config.enableCrop, isTrue);
      expect(config.enableTrim, isTrue);
      expect(config.enableCoverFrame, isTrue);
      expect(config.maxVideoDuration, isNull);
      expect(config.maxSourceMegapixels, isNull);
      expect(config.keepOriginals, isFalse);
      expect(config.thumbSize.width, 200);
      expect(config.thumbSize.height, 200);
    });

    test('effectiveInitialAspect falls back to the first configured aspect', () {
      const AssetPickerConfig config = AssetPickerConfig(
        aspects: <CropAspect>[CropAspect.story916, CropAspect.square],
      );
      expect(config.effectiveInitialAspect, CropAspect.story916);
    });

    test('effectiveInitialAspect honours an explicit initialAspect', () {
      const AssetPickerConfig config = AssetPickerConfig(
        aspects: <CropAspect>[CropAspect.story916, CropAspect.square],
        initialAspect: CropAspect.square,
      );
      expect(config.effectiveInitialAspect, CropAspect.square);
    });

    test('a single-entry aspect list is the forced-ratio mode', () {
      const AssetPickerConfig config = AssetPickerConfig(
        aspects: <CropAspect>[CropAspect.banner31],
      );
      expect(config.aspects, hasLength(1));
      expect(config.effectiveInitialAspect, CropAspect.banner31);
    });

    test('rejects a selection range that cannot be satisfied', () {
      expect(
        () => AssetPickerConfig(minSelection: 3, maxSelection: 2),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => AssetPickerConfig(minSelection: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => AssetPickerConfig(gridColumns: 0),
        throwsA(isA<AssertionError>()),
      );
      // A const constructor cannot assert on a collection's length, so an
      // empty aspect list surfaces at first use rather than at construction.
      expect(
        () => const AssetPickerConfig(aspects: <CropAspect>[]).effectiveInitialAspect,
        throwsA(isA<StateError>()),
      );
    });

    test('carries the encode settings from kutu_media_transform', () {
      const AssetPickerConfig config = AssetPickerConfig(
        imageEncode: ImageEncodeSettings(quality: 85, maxLongEdge: 2048),
        videoEncode: VideoEncodeSettings(maxLongEdge: 1080),
      );
      expect(config.imageEncode.quality, 85);
      expect(config.imageEncode.maxLongEdge, 2048);
      expect(config.videoEncode.maxLongEdge, 1080);
    });
  });

  group('tuning constants', () {
    test('the grid page size is large enough to fill a screen of cells', () {
      // A 3-column grid on a tall phone shows ~24 cells; a page must overshoot
      // so the first scroll does not immediately hit a loading gap.
      expect(PickerGridTuning.pageSize, greaterThanOrEqualTo(60));
    });

    test('the image cache ceiling is stated in bytes, not entries', () {
      // design §4.4: at 200x200x4 = 160 KB per thumbnail the 100 MiB byte cap
      // binds at ~655 thumbnails, well before the 1000-entry count cap, so the
      // byte cap is the one to tune.
      expect(PickerGridTuning.imageCacheCeilingBytes, 256 * 1024 * 1024);
      expect(PickerGridTuning.bytesPerPixel, 4);
    });
  });
}
