import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/src/config/picker_tuning.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_durations.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_limits.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_quality.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_radii.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_sizes.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_spacing.dart';

void main() {
  group('AssetPickerSizes', () {
    test('the preview long edge leaves headroom for the zoom ceiling', () {
      // A preview decoded at the crop window's own size would be interpolated
      // mush at 8x. 1440 keeps detail without ten of them evicting the whole
      // grid from the image cache.
      expect(AssetPickerSizes.previewLongEdge, 1440);
      expect(AssetPickerSizes.previewLongEdge, greaterThan(1080));
    });

    test('the cover frame is extracted square, at poster resolution', () {
      expect(AssetPickerSizes.coverFrame.width, 1080);
      expect(AssetPickerSizes.coverFrame.height, 1080);
    });

    test('a rail tile fits inside the rail with room for its border', () {
      // The rail height is fixed for the life of the crop step (spec §2.7), so
      // a tile that did not fit would clip rather than grow the rail.
      expect(
        AssetPickerSizes.railTile + 2 * AssetPickerSizes.railTileBorder,
        lessThan(AssetPickerSizes.railHeight),
      );
    });

    test('a chip fits inside the chip row', () {
      expect(AssetPickerSizes.chipHeight, lessThan(AssetPickerSizes.chipRow));
    });
  });

  group('AssetPickerSpacing', () {
    test('the four steps ascend', () {
      expect(AssetPickerSpacing.xs, lessThan(AssetPickerSpacing.sm));
      expect(AssetPickerSpacing.sm, lessThan(AssetPickerSpacing.md));
      expect(AssetPickerSpacing.md, lessThan(AssetPickerSpacing.lg));
    });
  });

  group('AssetPickerRadii', () {
    test('only the chip radius is declared here', () {
      // cellRadius and sheetRadius belong to slice 3 and the resolved theme
      // still falls back to those. Duplicating them here is how two numbers
      // that are meant to be one number drift apart.
      expect(AssetPickerRadii.chip, greaterThan(0));
      expect(PickerChromeSizes.cellRadius, greaterThan(0));
      expect(PickerChromeSizes.sheetRadius, greaterThan(0));
    });

    test('a chip is a pill, not a rounded box', () {
      expect(
        AssetPickerRadii.chip,
        greaterThanOrEqualTo(AssetPickerSizes.chipHeight / 2),
      );
    });
  });

  group('AssetPickerDurations', () {
    test('the thirds fade is short enough to read as a guide', () {
      expect(
        AssetPickerDurations.thirdsFade.inMilliseconds,
        lessThanOrEqualTo(200),
      );
      expect(AssetPickerDurations.thirdsFade, greaterThan(Duration.zero));
    });

    test('the fling fallback is a last resort, and is finite', () {
      expect(AssetPickerDurations.flingFallback, greaterThan(Duration.zero));
      expect(AssetPickerDurations.flingFallback.inMilliseconds, lessThan(1000));
    });
  });

  group('AssetPickerLimits', () {
    test('the zoom ceiling is a multiple of the cover scale, above 1', () {
      // Past roughly 8x a 12 MP source is showing individual sensor pixels and
      // the export would be upsampling.
      expect(AssetPickerLimits.maxZoomFactor, 8);
    });

    test('the fling physics match InteractiveViewer, so decel feels native',
        () {
      expect(AssetPickerLimits.flingDrag, closeTo(0.0000135, 1e-12));
      expect(AssetPickerLimits.flingMotionless, 10);
      expect(
        AssetPickerLimits.minFlingVelocity,
        greaterThan(AssetPickerLimits.flingMotionless),
      );
    });
  });

  group('AssetPickerQuality', () {
    test('quality is pinned, never inherited', () {
      // photo_manager's ThumbnailOption defaults to 95 and the
      // thumbnailDataWithSize overload to 100 — inheriting is a coin flip and
      // a doubled cache footprint for no visible gain (spec §4.4).
      expect(AssetPickerQuality.thumbnail, 85);
      expect(AssetPickerQuality.preview, 90);
      expect(
        AssetPickerQuality.preview,
        greaterThan(AssetPickerQuality.thumbnail),
      );
    });

    test('the grid thumbnail quality agrees with slice 3s', () {
      expect(AssetPickerQuality.thumbnail, PickerGridTuning.thumbnailQuality);
    });
  });
}
