import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'trim_math.dart';
import 'video_crop_constants.dart';
import 'video_playback_controller.dart';
import '../../theme/asset_picker_theme_scope.dart';

/// The playhead, riding the filmstrip in trim mode.
///
/// Absent until the clip has been played once. After that it stays — through
/// a pause and through a scrub — because it is the mark the author drags a
/// handle towards. Cover mode has no separate playhead: the cursor itself
/// follows playback there.
///
/// Never in the hit test: a handle underneath must win every drag.
class PlayheadOverlay extends ConsumerWidget {
  /// Creates a [PlayheadOverlay].
  const PlayheadOverlay({
    super.key,
    required this.assetId,
    required this.total,
    required this.trackWidth,
  });

  /// The playhead key.
  static const Key playheadKey = Key('playhead');

  /// The asset id.
  final String assetId;

  /// The total.
  final Duration total;

  /// The track width.
  final double trackWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playhead = ref.watch(
      videoPlaybackControllerProvider(assetId, total)
          .select((state) => state.playhead),
    );
    return IgnorePointer(
      child: Stack(
        children: [
          if (playhead != null)
            Positioned(
              left: fractionOfTime(playhead, total) * trackWidth -
                  VideoCropConstants.playheadWidth / 2,
              top: 0,
              bottom: 0,
              width: VideoCropConstants.playheadWidth,
              child: DecoratedBox(
                key: playheadKey,
                decoration: BoxDecoration(
                  color: context.pickerTheme.chipSelectedFill,
                  borderRadius: BorderRadius.circular(
                    VideoCropConstants.playheadWidth,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
