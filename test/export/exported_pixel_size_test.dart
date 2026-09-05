import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/src/export/exported_pixel_size.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

void main() {
  group('exportedPixelSize', () {
    test('a full rect with no cap is the source size', () {
      expect(
        exportedPixelSize(
          crop: const CropRect.full(),
          sourceWidth: 4000,
          sourceHeight: 3000,
        ),
        (width: 4000, height: 3000),
      );
    });

    test('a partial rect takes that fraction of the source', () {
      expect(
        exportedPixelSize(
          crop: const CropRect(left: 0.25, top: 0, right: 0.75, bottom: 1),
          sourceWidth: 4000,
          sourceHeight: 2000,
        ),
        (width: 2000, height: 2000),
      );
    });

    test('maxLongEdge scales the whole rect down uniformly', () {
      expect(
        exportedPixelSize(
          crop: const CropRect.full(),
          sourceWidth: 4000,
          sourceHeight: 3000,
          maxLongEdge: 2000,
        ),
        (width: 2000, height: 1500),
      );
    });

    test('maxLongEdge never upscales', () {
      expect(
        exportedPixelSize(
          crop: const CropRect.full(),
          sourceWidth: 800,
          sourceHeight: 600,
          maxLongEdge: 4000,
        ),
        (width: 800, height: 600),
      );
    });

    test('the cap applies to the SOURCE at decode, not to the crop', () {
      // Both platforms cap at decode (ImageDecoder.setTargetSize /
      // kCGImageSourceThumbnailMaxPixelSize), so a 4000x3000 source capped at
      // 1000 decodes to 1000x750 and the 0.75-wide full-height crop of THAT is
      // 750x750. Cropping first and capping the crop afterwards would allocate
      // the full-resolution bitmap this design exists to avoid.
      expect(
        exportedPixelSize(
          crop: const CropRect(left: 0.125, top: 0, right: 0.875, bottom: 1),
          sourceWidth: 4000,
          sourceHeight: 3000,
          maxLongEdge: 1000,
        ),
        (width: 750, height: 750),
      );
    });

    test(
        'delegates rounding to the canonical rule: even extents, never below 2',
        () {
      // The exact values are pinned by kutu_media_transform's nine-row golden
      // table, asserted identically in Dart, Kotlin and Swift. This function
      // only has to compose the two stages in the right order, so what is
      // asserted here are the invariants the encoders actually depend on —
      // duplicating the golden rows would create the second rounding rule this
      // change exists to remove.
      final ({int width, int height}) thirdOfASquare = exportedPixelSize(
        crop: const CropRect(left: 0, top: 0, right: 0.3333, bottom: 1),
        sourceWidth: 1000,
        sourceHeight: 1000,
      );
      expect(thirdOfASquare.width.isEven, isTrue);
      expect(thirdOfASquare.height.isEven, isTrue);
      expect(thirdOfASquare.width, greaterThanOrEqualTo(2));

      final ({int width, int height}) sliver = exportedPixelSize(
        crop: const CropRect(left: 0, top: 0, right: 0.0001, bottom: 0.0001),
        sourceWidth: 100,
        sourceHeight: 100,
      );
      expect(sliver.width, greaterThanOrEqualTo(2));
      expect(sliver.height, greaterThanOrEqualTo(2));
      expect(sliver.width.isEven, isTrue);
      expect(sliver.height.isEven, isTrue);
    });
  });
}
