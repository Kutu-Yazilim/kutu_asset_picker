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
  static const double railTile = 56;
  static const double railTileBorder = 2;

  static const double chipRow = 52;
  static const double chipHeight = 32;
  static const double appBarHeight = 56;

  /// Breathing room between the crop window and the edges of the stage.
  static const double cropStageInset = 16;

  static const double thirdsLineWidth = 1;
  static const double windowBorderWidth = 1.5;
}
