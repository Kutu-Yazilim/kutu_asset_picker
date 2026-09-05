import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../source/picker_asset.dart';
import '../picker_asset_size.dart';
import 'crop_asset_image.dart';
import 'crop_viewport.dart';

/// The crop area for a still.
///
/// Lifted out of `CropStage` unchanged so the photo branch and the video branch
/// have the same shape: each is handed the window the stage laid out and each
/// fills it. This is a move, not a rewrite — the gesture surface, the clamp and
/// the chrome all still belong to `CropViewport` and `CropStage`.
class ImageCropSurface extends ConsumerWidget {
  const ImageCropSurface(
      {super.key, required this.asset, required this.window});

  final PickerAsset asset;

  /// The crop window `CropStage`'s `LayoutBuilder` computed. Passed down rather
  /// than recomputed here: the stage owns the available space, and two places
  /// deriving the same window is two places for them to disagree.
  final Size window;

  @override
  Widget build(BuildContext context, WidgetRef ref) => CropViewport(
        assetId: asset.id,
        imageSize: pickerAssetSize(asset),
        window: window,
        child: CropAssetImage(asset: asset),
      );
}
