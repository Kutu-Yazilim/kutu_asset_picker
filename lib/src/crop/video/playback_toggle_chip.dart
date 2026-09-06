import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'video_crop_constants.dart';
import 'video_playback_controller.dart';
import '../../text/asset_picker_text_scope.dart';
import '../../theme/asset_picker_theme_scope.dart';

/// Play ↔ pause, on the control bar.
///
/// Inert until the player has initialised — there is no picture to play
/// before then — and one bar row tall, so the bar's height stays the constant
/// `CropStage` reserves for it.
class PlaybackToggleChip extends ConsumerWidget {
  /// Creates a [PlaybackToggleChip].
  const PlaybackToggleChip({
    super.key,
    required this.assetId,
    required this.total,
  });

  /// The asset id.
  final String assetId;

  /// The total.
  final Duration total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.pickerTheme;
    final text = context.pickerText;
    final playback = ref.watch(videoPlaybackControllerProvider(assetId, total));
    return Tooltip(
      message: playback.isPlaying ? text.cropPause : text.cropPlay,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: playback.isReady
            ? ref
                .read(videoPlaybackControllerProvider(assetId, total).notifier)
                .toggle
            : null,
        child: SizedBox.square(
          dimension: VideoCropConstants.barRowHeight,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: playback.isPlaying
                  ? theme.chipSelectedFill
                  : theme.chipUnselectedFill,
              borderRadius: BorderRadius.circular(theme.chipRadius),
            ),
            child: Icon(
              playback.isPlaying ? Icons.pause : Icons.play_arrow,
              size: VideoCropConstants.playbackIconSize,
              color: !playback.isReady
                  ? theme.onSurfaceMuted
                  : playback.isPlaying
                      ? theme.chipSelectedText
                      : theme.chipUnselectedText,
            ),
          ),
        ),
      ),
    );
  }
}
