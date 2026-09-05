import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../widgets/crop_viewport.dart';
import 'crop_gesture_activity_detector.dart';
import 'floating_video_bar.dart';
import 'video_crop_constants.dart';
import 'video_display_size.dart';
import 'video_preview_player.dart';
import 'video_preview_source.dart';

/// A video under the crop window, with its controls floating over it.
///
/// The viewport is the FIRST child of a fill-expanded [Stack], centred, and the
/// bar is `Positioned` over it. The bar therefore costs the crop area nothing:
/// the window is exactly the [window] `CropStage` laid out, which is exactly
/// the window the photo branch is handed. That is the whole point of spec §2.7
/// — tabbing between a photo and a video must not resize anything.
class VideoCropStack extends ConsumerWidget {
  const VideoCropStack({
    super.key,
    required this.assetId,
    required this.preview,
    required this.window,
  });

  final String assetId;
  final VideoPreviewSource preview;

  /// The crop window `CropStage` computed for the focused aspect.
  final Size window;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(videoPreviewPlayerProvider(assetId)).value;
    return Stack(
      fit: StackFit.expand,
      alignment: Alignment.center,
      children: [
        Center(
          child: CropGestureActivityDetector(
            child: CropViewport(
              assetId: assetId,
              // The ROTATED size, never the coded one: `video_player` applies
              // the rotation tag for display, so crop_math must be given what
              // the author sees (spec §7.4 invariant 1).
              imageSize: videoDisplaySize(preview.info),
              window: window,
              // The player is just a widget, so the ClipRect + Transform stack
              // above it is byte-for-byte the one the photo path uses.
              child: player == null
                  ? const SizedBox.expand()
                  : VideoPlayer(player),
            ),
          ),
        ),
        Positioned(
          left: VideoCropConstants.barInset,
          right: VideoCropConstants.barInset,
          bottom: VideoCropConstants.barInset,
          child: FloatingVideoBar(
            assetId: assetId,
            total: preview.info.duration,
            srcPath: preview.file.path,
          ),
        ),
      ],
    );
  }
}
