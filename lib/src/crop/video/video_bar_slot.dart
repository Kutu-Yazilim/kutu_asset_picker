import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../source/picker_asset.dart';
import '../../source/picker_media_type.dart';
import 'video_control_bar.dart';
import 'video_crop_constants.dart';
import 'video_preview_source.dart';

/// The band under the crop window that holds the video controls.
///
/// `CropStage` reserves it at [VideoCropConstants.barSlotHeight] for every
/// asset in a session that contains a video, and this widget fills it — or
/// deliberately does not. Under a photo it is empty, which is what keeps the
/// crop window the same size whichever asset is focused (spec §2.7). Under a
/// video it waits on the same preview source the viewport does, and shows the
/// bar once the clip has been probed; while the probe is loading, or has
/// refused the clip, there is no duration to trim against and so no bar.
class VideoBarSlot extends ConsumerWidget {
  /// Creates a [VideoBarSlot].
  const VideoBarSlot({super.key, required this.asset});

  /// The focused asset.
  final PickerAsset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (asset.type != PickerMediaType.video) return const SizedBox.shrink();
    final preview = ref.watch(videoPreviewSourceProvider(asset.id)).value;
    if (preview == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: VideoCropConstants.barInset),
      child: VideoControlBar(
        assetId: asset.id,
        total: preview.info.duration,
        srcPath: preview.file.path,
      ),
    );
  }
}
