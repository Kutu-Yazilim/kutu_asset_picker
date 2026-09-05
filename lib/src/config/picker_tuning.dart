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

  /// The cell radius.
  static const double cellRadius = 4;

  /// The sheet radius.
  static const double sheetRadius = 16;

  /// The badge diameter.
  static const double badgeDiameter = 24;

  /// The badge border width.
  static const double badgeBorderWidth = 1.5;

  /// The badge inset.
  static const double badgeInset = 6;

  /// The duration chip radius.
  static const double durationChipRadius = 4;

  /// The duration chip padding.
  static const EdgeInsets durationChipPadding =
      EdgeInsets.symmetric(horizontal: 4, vertical: 1);

  /// The duration chip inset.
  static const double durationChipInset = 4;

  /// The disabled overlay opacity.
  static const double disabledOverlayOpacity = 0.55;

  /// The duration chip background opacity.
  static const double durationChipBackgroundOpacity = 0.6;

  /// The selected strip height.
  static const double selectedStripHeight = 76;

  /// The selected strip tile size.
  static const double selectedStripTileSize = 64;

  /// The selected strip spacing.
  static const double selectedStripSpacing = 8;

  /// The selected strip padding.
  static const EdgeInsets selectedStripPadding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 6);

  /// The footer padding.
  static const EdgeInsets footerPadding = EdgeInsets.all(12);

  /// The state padding.
  static const EdgeInsets statePadding = EdgeInsets.all(24);

  /// The state spacing.
  static const double stateSpacing = 12;

  /// The state icon size.
  static const double stateIconSize = 40;

  /// The limited bar padding.
  static const EdgeInsets limitedBarPadding =
      EdgeInsets.symmetric(horizontal: 12, vertical: 8);

  /// The sheet initial extent.
  static const double sheetInitialExtent = 0.7;

  /// The sheet min extent.
  static const double sheetMinExtent = 0.4;

  /// The sheet max extent.
  static const double sheetMaxExtent = 0.95;

  /// The camera icon size.
  static const double cameraIconSize = 28;

  /// The progress stroke width.
  static const double progressStrokeWidth = 2;
}

/// Animation and debounce durations.
abstract final class PickerDurations {
  const PickerDurations._();

  /// The badge animation.
  static const Duration badgeAnimation = Duration(milliseconds: 120);

  /// The overlay fade.
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
