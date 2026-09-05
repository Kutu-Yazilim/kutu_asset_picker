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

    test('effectiveInitialAspect falls back to the first configured aspect',
        () {
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
        () => const AssetPickerConfig(aspects: <CropAspect>[])
            .effectiveInitialAspect,
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

  group('CropAspect, as the chip row uses it', () {
    test('two aspects with the same numbers and label are equal', () {
      // The chip row decides which chip is selected with ==, so identity
      // equality would leave every chip unselected.
      expect(
        const CropAspect(x: 1, y: 1, label: CropAspectLabel.square),
        CropAspect.square,
      );
      expect(
        const CropAspect(x: 1, y: 1, label: CropAspectLabel.square).hashCode,
        CropAspect.square.hashCode,
      );
      expect(CropAspect.square == CropAspect.portrait45, isFalse);
    });

    test('a custom ratio carries its own numbers and the custom label', () {
      // aspectChipLabel prints these numbers, because a custom ratio has no
      // copy key of its own.
      const CropAspect aspect = CropAspect.custom(3, 2);

      expect(aspect.x, 3);
      expect(aspect.y, 2);
      expect(aspect.label, CropAspectLabel.custom);
      expect(aspect.ratio, closeTo(1.5, 1e-12));
    });

    test('a list of aspects preserves the order the menu renders in', () {
      const AssetPickerConfig config = AssetPickerConfig(
        aspects: <CropAspect>[
          CropAspect.banner31,
          CropAspect.square,
          CropAspect.story916,
        ],
      );

      expect(config.aspects.first, CropAspect.banner31);
      expect(config.aspects.last, CropAspect.story916);
    });
  });

  group('the crop step reads these off the config', () {
    test('effectiveInitialAspect is the ratio a fresh asset opens on', () {
      // CropStates.stateOf returns CropState.unsized(effectiveInitialAspect)
      // for an asset nobody has framed yet, so this getter is the opening
      // framing of every asset in the batch.
      const AssetPickerConfig explicit = AssetPickerConfig(
        aspects: <CropAspect>[CropAspect.square, CropAspect.story916],
        initialAspect: CropAspect.story916,
      );
      const AssetPickerConfig implicit = AssetPickerConfig(
        aspects: <CropAspect>[CropAspect.banner31, CropAspect.square],
      );

      expect(explicit.effectiveInitialAspect, CropAspect.story916);
      expect(implicit.effectiveInitialAspect, CropAspect.banner31);
    });

    test('a single-entry aspects list is the forced-ratio mode', () {
      // The chip row still renders the one chip, so the author can see what
      // shape they are composing for.
      const AssetPickerConfig config =
          AssetPickerConfig(aspects: <CropAspect>[CropAspect.square]);

      expect(config.aspects, hasLength(1));
      expect(config.effectiveInitialAspect, CropAspect.square);
    });

    test('allowPerAssetAspect defaults on and can be collapsed', () {
      // False collapses the aspect to one shared value for the whole batch and
      // hides Apply to all, which would then have nothing to do (spec §2.4).
      expect(const AssetPickerConfig().allowPerAssetAspect, isTrue);
      expect(
        const AssetPickerConfig(allowPerAssetAspect: false).allowPerAssetAspect,
        isFalse,
      );
    });

    test('cropSurface is settable independently of pickerSurface', () {
      // spec §2.6: an avatar picker is a lightweight sheet while a post
      // composer is a full page, and the two steps are configured separately.
      // AssetPickerView switches CropStepHost on this field (Task 16).
      const AssetPickerConfig mixed = AssetPickerConfig(
        pickerSurface: PickerSurface.sheet,
        cropSurface: PickerSurface.page,
      );

      expect(mixed.pickerSurface, PickerSurface.sheet);
      expect(mixed.cropSurface, PickerSurface.page);
      expect(const AssetPickerConfig().cropSurface, PickerSurface.page);
    });

    test('cropOverlayShape defaults to a rectangle', () {
      // circle is the avatar case; the exported rect is still the square that
      // bounds it, because a JPEG has no alpha to spare.
      expect(
        const AssetPickerConfig().cropOverlayShape,
        CropOverlayShape.rectangle,
      );
      expect(
        const AssetPickerConfig(cropOverlayShape: CropOverlayShape.circle)
            .cropOverlayShape,
        CropOverlayShape.circle,
      );
    });

    test('enableCrop can be turned off, and keepOriginals turned on', () {
      // enableCrop: false skips the crop step but still routes the source
      // through the transform seam (spec §7.5); keepOriginals populates
      // PickedAsset.originalFile.
      const AssetPickerConfig config =
          AssetPickerConfig(enableCrop: false, keepOriginals: true);

      expect(config.enableCrop, isFalse);
      expect(config.keepOriginals, isTrue);
      expect(const AssetPickerConfig().enableCrop, isTrue);
      expect(const AssetPickerConfig().keepOriginals, isFalse);
    });
  });
}
