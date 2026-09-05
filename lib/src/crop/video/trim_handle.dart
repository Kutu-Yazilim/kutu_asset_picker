import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'trim_math.dart';
import 'video_crop_constants.dart';
import 'video_trim_controller.dart';
import '../../theme/asset_picker_theme_scope.dart';

enum TrimHandleSide { start, end }

/// One draggable end of the trim range.
///
/// Reports its drag as a *delta fraction* of the track rather than an absolute
/// position, because the handle moves with the value it sets: an absolute read
/// of `localPosition` inside a moving box chases itself.
class TrimHandle extends ConsumerWidget {
  const TrimHandle({
    super.key,
    required this.assetId,
    required this.total,
    required this.trackWidth,
    required this.side,
  });

  final String assetId;
  final Duration total;
  final double trackWidth;
  final TrimHandleSide side;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.pickerTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (details) {
        final controller =
            ref.read(videoTrimControllerProvider(assetId, total).notifier);
        final delta = fractionOfDx(details.delta.dx, trackWidth);
        switch (side) {
          case TrimHandleSide.start:
            controller.nudgeStart(delta);
          case TrimHandleSide.end:
            controller.nudgeEnd(delta);
        }
      },
      onHorizontalDragEnd: (_) => ref
          .read(videoTrimControllerProvider(assetId, total).notifier)
          .endDrag(),
      child: SizedBox(
        width: VideoCropConstants.handleWidth,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: theme.onSurface,
            borderRadius: BorderRadius.circular(theme.chipRadius),
          ),
          child: Center(
            child: SizedBox(
              width: VideoCropConstants.handleGripWidth,
              height: VideoCropConstants.handleGripHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.onSurfaceMuted,
                  borderRadius:
                      BorderRadius.circular(VideoCropConstants.handleGripWidth),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
