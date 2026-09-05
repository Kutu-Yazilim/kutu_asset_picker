import 'package:kutu_media_transform/kutu_media_transform.dart';

/// Fixed pixel dimensions. Flutter rule 3 — no magic numbers in widgets.
abstract final class AssetPickerSizes {
  const AssetPickerSizes._();

  /// Long edge of the image handed to the crop viewport. Big enough that a
  /// pinch to the 8× ceiling still shows detail, small enough that ten of them
  /// do not evict the whole grid from the image cache.
  static const int previewLongEdge = 1440;

  /// Box the cover frame is extracted into.
  static const ThumbSize coverFrame = ThumbSize.square(1080);

  /// The asset rail is permanent and its height never changes — that is the
  /// whole point of spec §2.7's layout decision, so the crop area does not
  /// resize as the author tabs between a photo and a video.
  static const double railHeight = 76;

  /// The rail tile.
  static const double railTile = 56;

  /// Pixel size requested for a rail thumbnail. Flat and clamped, deliberately
  /// larger than [railTile] logical px so it survives a 3× device pixel ratio
  /// without a second cache entry per density (spec §4.4).
  static const int railTileThumb = 160;

  /// The rail tile border.
  static const double railTileBorder = 2;

  /// The chip row.
  static const double chipRow = 52;

  /// The chip height.
  static const double chipHeight = 32;

  /// The app bar height.
  static const double appBarHeight = 56;

  /// Breathing room between the crop window and the edges of the stage.
  static const double cropStageInset = 16;

  /// The thirds line width.
  static const double thirdsLineWidth = 1;

  /// The window border width.
  static const double windowBorderWidth = 1.5;
}
