import 'dart:math' as math;

import 'package:kutu_asset_picker/src/constants/asset_picker_sizes.dart';
import 'package:kutu_asset_picker/src/source/picker_asset.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

/// The preview box for the crop step: the asset's own aspect ratio with the
/// long edge clamped to [maxLongEdge], and never upscaled.
///
/// Matching the asset's ratio is deliberate. `AssetSource.thumbnail` is free to
/// fit *or* fill into the box it is handed, and those differ whenever the box's
/// ratio differs from the asset's — which would silently letterbox or crop the
/// exact frame the author is composing. An aspect-matched box makes the two
/// behaviours identical, so the preview cannot disagree with the export.
ThumbSize previewThumbSize(
  PickerAsset asset, {
  int maxLongEdge = AssetPickerSizes.previewLongEdge,
}) {
  if (asset.width <= 0 || asset.height <= 0) {
    return ThumbSize.square(maxLongEdge);
  }
  final longEdge = math.max(asset.width, asset.height);
  if (longEdge <= maxLongEdge) return ThumbSize(asset.width, asset.height);
  final factor = maxLongEdge / longEdge;
  return ThumbSize(
    math.max(1, (asset.width * factor).round()),
    math.max(1, (asset.height * factor).round()),
  );
}
