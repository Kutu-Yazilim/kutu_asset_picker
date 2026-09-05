import 'package:flutter/widgets.dart';

/// Grid and paging tuning. Flutter rule 3: no magic numbers in widgets.
abstract final class PickerGridTuning {
  const PickerGridTuning._();

  /// Assets fetched per page. A 3-column grid on a tall phone shows roughly 24
  /// cells, so this overshoots by ~3.5 screens and the first fling does not
  /// stall on a fetch.
  static const int pageSize = 90;

  /// How close to the end of the list a scroll gets before the next page is
  /// requested, in logical pixels.
  static const double loadMoreThreshold = 600;

  /// `GridView.cacheExtent`. Modest on purpose (design §4.4): a large cache
  /// extent decodes far ahead of the viewport and is a common source of
  /// thumbnail-grid jank.
  static const double cacheExtent = 480;

  /// Bytes per decoded pixel (RGBA8888), used to size the image cache budget.
  static const int bytesPerPixel = 4;

  /// Hard ceiling for `ImageCache.maximumSizeBytes` while the picker is open,
  /// so an unusually large `thumbSize` cannot ask for an absurd budget.
  static const int imageCacheCeilingBytes = 256 * 1024 * 1024;

  /// Thumbnail JPEG quality, pinned explicitly.
  ///
  /// `ThumbnailOption`'s default is 95 and the `thumbnailDataWithSize`
  /// overload's is 100 — inheriting either is a coin flip (design §4.4).
  static const int thumbnailQuality = 85;
}

/// Fixed chrome geometry.
abstract final class PickerChromeSizes {
  const PickerChromeSizes._();

  static const double cellRadius = 4;
  static const double sheetRadius = 16;

  static const double badgeDiameter = 24;
  static const double badgeBorderWidth = 1.5;
  static const double badgeInset = 6;

  static const double durationChipRadius = 4;
  static const EdgeInsets durationChipPadding =
      EdgeInsets.symmetric(horizontal: 4, vertical: 1);
  static const double durationChipInset = 4;

  static const double disabledOverlayOpacity = 0.55;
  static const double durationChipBackgroundOpacity = 0.6;

  static const double selectedStripHeight = 76;
  static const double selectedStripTileSize = 64;
  static const double selectedStripSpacing = 8;
  static const EdgeInsets selectedStripPadding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 6);

  static const EdgeInsets footerPadding = EdgeInsets.all(12);
  static const EdgeInsets statePadding = EdgeInsets.all(24);
  static const double stateSpacing = 12;
  static const double stateIconSize = 40;

  static const EdgeInsets limitedBarPadding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 8);

  static const double sheetInitialExtent = 0.7;
  static const double sheetMinExtent = 0.4;
  static const double sheetMaxExtent = 0.95;

  static const double cameraIconSize = 28;
  static const double progressStrokeWidth = 2;
}

/// Animation and debounce durations.
abstract final class PickerDurations {
  const PickerDurations._();

  static const Duration badgeAnimation = Duration(milliseconds: 120);
  static const Duration overlayFade = Duration(milliseconds: 150);
}

/// Stable widget keys the grid relies on.
abstract final class PickerGridKeys {
  const PickerGridKeys._();

  /// The camera tile's `ValueKey` value. `findChildIndexCallback` needs to
  /// recognise it, and no asset id can collide with it because platform ids
  /// never contain a space.
  static const String cameraTile = 'kutu picker camera tile';
}
