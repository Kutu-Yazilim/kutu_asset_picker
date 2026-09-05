import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../source/picker_asset.dart';
import '../video/video_crop_surface.dart';
import 'image_crop_surface.dart';
import '../../source/picker_media_type.dart';

/// Whichever crop surface the focused asset needs.
///
/// Both arms are handed the same [window], which is the whole reason the crop
/// area cannot change size between a photo and a video (spec §2.7).
class CropMediaSurface extends ConsumerWidget {
  /// Creates a [CropMediaSurface].
  const CropMediaSurface(
      {super.key, required this.asset, required this.window});

  /// The asset.
  final PickerAsset asset;

  /// The window.
  final Size window;

  @override
  Widget build(BuildContext context, WidgetRef ref) => switch (asset.type) {
        PickerMediaType.image => ImageCropSurface(asset: asset, window: window),
        PickerMediaType.video =>
          VideoCropSurface(assetId: asset.id, window: window),
      };
}
