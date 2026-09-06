import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'trim_handle.dart';
import 'trim_math.dart';
import 'video_crop_constants.dart';
import 'video_trim_controller.dart';
import '../../theme/asset_picker_theme_scope.dart';

/// The trim mode of the scrubber: two handles, the dimming that shows what
/// the export will throw away, and the kept zone between the handles as a
/// grab surface of its own.
///
/// Dragging the zone carries the whole range, length intact — the author who
/// kept 0:10–0:20 and now wants 0:30–0:40 slides it once instead of moving
/// each end. The zone sits *under* the handles in the stack and is inset by
/// their width, so a finger landing on a handle still resizes rather than
/// slides; the bars along its top and bottom join the handles into one frame,
/// which is what says it is a thing to take hold of.
class TrimHandlesOverlay extends ConsumerWidget {
  /// Creates a [TrimHandlesOverlay].
  const TrimHandlesOverlay({
    super.key,
    required this.assetId,
    required this.total,
    required this.trackWidth,
  });

  /// The leading mask key.
  static const Key leadingMaskKey = Key('trim-leading-mask');

  /// The trailing mask key.
  static const Key trailingMaskKey = Key('trim-trailing-mask');

  /// The kept zone's grab surface.
  static const Key rangeKey = Key('trim-range');

  /// The asset id.
  final String assetId;

  /// The total.
  final Duration total;

  /// The track width.
  final double trackWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.pickerTheme;
    final trim = ref.watch(videoTrimControllerProvider(assetId, total)).trim;
    final startX = fractionOfTime(trim.start, total) * trackWidth;
    final endX = fractionOfTime(trim.end, total) * trackWidth;
    final mask =
        theme.cropMask.withValues(alpha: VideoCropConstants.maskOpacity);
    return Stack(
      children: [
        Positioned(
          key: leadingMaskKey,
          left: 0,
          top: 0,
          bottom: 0,
          width: startX,
          child: ColoredBox(color: mask),
        ),
        Positioned(
          key: trailingMaskKey,
          left: endX,
          top: 0,
          bottom: 0,
          right: 0,
          child: ColoredBox(color: mask),
        ),
        Positioned(
          left: startX + VideoCropConstants.handleWidth / 2,
          width: math.max(0, endX - startX - VideoCropConstants.handleWidth),
          top: 0,
          bottom: 0,
          child: GestureDetector(
            key: rangeKey,
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) => ref
                .read(videoTrimControllerProvider(assetId, total).notifier)
                .nudgeRange(fractionOfDx(details.delta.dx, trackWidth)),
            onHorizontalDragEnd: (_) => ref
                .read(videoTrimControllerProvider(assetId, total).notifier)
                .endDrag(),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.symmetric(
                  horizontal: BorderSide(
                    color: theme.onSurface,
                    width: VideoCropConstants.rangeFrameWidth,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: startX - VideoCropConstants.handleWidth / 2,
          top: 0,
          bottom: 0,
          child: TrimHandle(
            assetId: assetId,
            total: total,
            trackWidth: trackWidth,
            side: TrimHandleSide.start,
          ),
        ),
        Positioned(
          left: endX - VideoCropConstants.handleWidth / 2,
          top: 0,
          bottom: 0,
          child: TrimHandle(
            assetId: assetId,
            total: total,
            trackWidth: trackWidth,
            side: TrimHandleSide.end,
          ),
        ),
      ],
    );
  }
}
