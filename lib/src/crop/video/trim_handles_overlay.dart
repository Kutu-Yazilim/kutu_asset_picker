import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'trim_handle.dart';
import 'trim_math.dart';
import 'video_crop_constants.dart';
import 'video_trim_controller.dart';
import '../../theme/asset_picker_theme_scope.dart';

/// The trim mode of the scrubber: two handles plus the dimming that shows what
/// the export will throw away.
class TrimHandlesOverlay extends ConsumerWidget {
  const TrimHandlesOverlay({
    super.key,
    required this.assetId,
    required this.total,
    required this.trackWidth,
  });

  static const Key leadingMaskKey = Key('trim-leading-mask');
  static const Key trailingMaskKey = Key('trim-trailing-mask');

  final String assetId;
  final Duration total;
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
