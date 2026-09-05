import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/injection_providers.dart';
import 'crop_gesture_activity.dart';
import 'scrubber_mode_toggle.dart';
import 'trim_range_label.dart';
import 'video_bar_visibility.dart';
import 'video_crop_constants.dart';
import 'video_scrubber.dart';
import '../../theme/asset_picker_theme_scope.dart';

/// The video controls, floating *inside* the crop area.
///
/// Spec §2.7: the asset rail at the bottom of the crop step is permanent and
/// fixed, so the trim controls cannot be a second stacked rail — that would
/// give the crop area a different height for photos and videos and the image
/// would visibly resize as the author tabs between them. Instead this bar is
/// `Positioned` over the footage, which costs an occluded strip at the bottom
/// of the frame being framed. The fade is the mitigation: it disappears the
/// moment a finger lands on the footage and returns on release.
class FloatingVideoBar extends ConsumerWidget {
  const FloatingVideoBar({
    super.key,
    required this.assetId,
    required this.total,
    required this.srcPath,
  });

  final String assetId;
  final Duration total;
  final String srcPath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!showsFloatingVideoBar(ref.watch(assetPickerConfigProvider))) {
      return const SizedBox.shrink();
    }
    final theme = context.pickerTheme;
    final dragging = ref.watch(cropIsBeingDraggedProvider);
    return IgnorePointer(
      ignoring: dragging,
      child: AnimatedOpacity(
        opacity: dragging
            ? VideoCropConstants.barOpacityDragging
            : VideoCropConstants.barOpacityIdle,
        duration: VideoCropConstants.barFadeDuration,
        child: DecoratedBox(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const ScrubberModeToggle(),
                    TrimRangeLabel(assetId: assetId, total: total),
                  ],
                ),
                const SizedBox(height: VideoCropConstants.barContentGap),
                VideoScrubber(assetId: assetId, total: total, srcPath: srcPath),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
