import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/injection_providers.dart';
import 'playback_toggle_chip.dart';
import 'scrubber_mode_toggle.dart';
import 'trim_range_label.dart';
import 'video_bar_visibility.dart';
import 'video_crop_constants.dart';
import 'video_scrubber.dart';
import '../../theme/asset_picker_theme_scope.dart';

/// The video controls: the trim/cover toggle, play/pause, the kept range, the
/// scrubber.
///
/// Lives in the band `CropStage` reserves **under** the crop window, never
/// over the footage. It used to float inside the crop area and fade out while
/// the image was dragged (spec §2.7 as first written); the fade was the
/// mitigation for occluding the bottom of the frame being framed, and it is
/// gone with the occlusion — controls that blink while the author pans would
/// be a defect of their own now that they cover nothing.
///
/// The band is reserved at a known height before this widget exists, which is
/// why the toggle row is fixed at [VideoCropConstants.barRowHeight] rather
/// than intrinsic: the bar's height is [VideoCropConstants.barHeight], a
/// constant derived from its parts, and the stage trusts it.
class VideoControlBar extends ConsumerWidget {
  /// Creates a [VideoControlBar].
  const VideoControlBar({
    super.key,
    required this.assetId,
    required this.total,
    required this.srcPath,
  });

  /// The asset id.
  final String assetId;

  /// The total.
  final Duration total;

  /// The src path.
  final String srcPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!showsVideoBar(ref.watch(assetPickerConfigProvider))) {
      return const SizedBox.shrink();
    }
    final theme = context.pickerTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.surface
            .withValues(alpha: VideoCropConstants.barSurfaceOpacity),
        borderRadius: BorderRadius.circular(theme.chipRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(VideoCropConstants.barPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: VideoCropConstants.barRowHeight,
              child: Row(
                children: [
                  const ScrubberModeToggle(),
                  const SizedBox(width: VideoCropConstants.toggleGap),
                  // The play chip and the range are one right-aligned group
                  // that scales down rather than overflows when a narrow
                  // screen or a large text scale leaves the row short.
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PlaybackToggleChip(assetId: assetId, total: total),
                          const SizedBox(width: VideoCropConstants.toggleGap),
                          TrimRangeLabel(assetId: assetId, total: total),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: VideoCropConstants.barContentGap),
            VideoScrubber(assetId: assetId, total: total, srcPath: srcPath),
          ],
        ),
      ),
    );
  }
}
