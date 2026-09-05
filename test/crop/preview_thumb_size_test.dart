import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/src/config/crop_aspect.dart';
import 'package:kutu_asset_picker/src/crop/aspect_chip_label.dart';
import 'package:kutu_asset_picker/src/crop/focused_asset_resolver.dart';
import 'package:kutu_asset_picker/src/crop/preview_thumb_size.dart';
import 'package:kutu_asset_picker/src/crop/reorder_target.dart';
import 'package:kutu_asset_picker/src/source/picker_asset.dart';
import 'package:kutu_asset_picker/src/source/picker_media_type.dart';
import 'package:kutu_asset_picker/src/text/asset_picker_text_en.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

PickerAsset asset(String id, {int width = 4000, int height = 3000}) =>
    PickerAsset(
      id: id,
      type: PickerMediaType.image,
      width: width,
      height: height,
      createdAt: DateTime.utc(2026, 8, 4),
    );

void main() {
  group('previewThumbSize', () {
    test('keeps the asset ratio and clamps the long edge', () {
      // An aspect-matched box is the point: AssetSource.thumbnail is free to
      // fit OR fill into the box it is given, and the two differ whenever the
      // box's ratio differs from the asset's — which would silently letterbox
      // or crop the very frame the author is composing.
      expect(
        previewThumbSize(asset('a', width: 4000, height: 3000),
            maxLongEdge: 1440),
        const ThumbSize(1440, 1080),
      );
      expect(
        previewThumbSize(asset('b', width: 3000, height: 4000),
            maxLongEdge: 1440),
        const ThumbSize(1080, 1440),
      );
    });

    test('does not upscale a source that is already small', () {
      expect(
        previewThumbSize(asset('c', width: 600, height: 400),
            maxLongEdge: 1440),
        const ThumbSize(600, 400),
      );
    });

    test('a degenerate asset falls back to a square box', () {
      expect(
        previewThumbSize(asset('d', width: 0, height: 0), maxLongEdge: 1440),
        const ThumbSize.square(1440),
      );
    });

    test('never returns a zero edge', () {
      final size = previewThumbSize(asset('e', width: 10000, height: 3),
          maxLongEdge: 100);

      expect(size.width, 100);
      expect(size.height, greaterThanOrEqualTo(1));
    });
  });

  group('aspectChipLabel', () {
    const text = AssetPickerTextEn();

    test('uses the delegate for the named ratios', () {
      expect(aspectChipLabel(CropAspect.square, text), '1:1');
      expect(aspectChipLabel(CropAspect.portrait45, text), '4:5');
      expect(aspectChipLabel(CropAspect.landscape169, text), '16:9');
      expect(aspectChipLabel(CropAspect.story916, text), '9:16');
      expect(aspectChipLabel(CropAspect.banner31, text), '3:1');
    });

    test('prints the numbers for a custom ratio', () {
      // The delegate cannot know a custom ratio's digits, so the chip renders
      // them instead of the useless word "Custom".
      expect(aspectChipLabel(const CropAspect.custom(3, 2), text), '3:2');
      expect(aspectChipLabel(const CropAspect.custom(2.5, 1), text), '2.5:1');
    });
  });

  group('normalizedReorderTarget', () {
    test('a downward move loses the index the item vacated', () {
      // ReorderableListView reports newIndex in the PRE-removal coordinate
      // space, so dragging item 0 to the end of a 3-item list arrives as 3.
      expect(normalizedReorderTarget(0, 3), 2);
      expect(normalizedReorderTarget(0, 1), 0);
    });

    test('an upward move is already in list coordinates', () {
      expect(normalizedReorderTarget(2, 0), 0);
      expect(normalizedReorderTarget(2, 1), 1);
    });
  });

  group('resolveFocusedAsset', () {
    final assets = [asset('a'), asset('b'), asset('c')];

    test('returns the explicitly focused asset', () {
      expect(resolveFocusedAsset(assets, 'b')?.id, 'b');
    });

    test('falls back to the first when nothing is focused', () {
      expect(resolveFocusedAsset(assets, null)?.id, 'a');
    });

    test('falls back to the first when the focus was deselected', () {
      expect(resolveFocusedAsset(assets, 'gone')?.id, 'a');
    });

    test('returns null for an empty selection', () {
      expect(resolveFocusedAsset(const [], 'a'), isNull);
    });
  });
}
