import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'trim_math.dart';
import 'video_crop_constants.dart';
import 'video_trim_controller.dart';
import '../../theme/asset_picker_theme_scope.dart';

/// The cover mode of the scrubber: one cursor, constrained to the trim range.
///
/// The frames underneath are the same [FilmstripStrip] the trim mode uses, and
/// the seek goes through the same coalescer — the whole of "cover picking" is
/// this overlay swapping in for the handles.
class CoverCursorOverlay extends ConsumerWidget {
  /// Creates a [CoverCursorOverlay].
  const CoverCursorOverlay({
    super.key,
    required this.assetId,
    required this.total,
    required this.trackWidth,
  });

  /// The cursor key.
  static const Key cursorKey = Key('cover-cursor');

  /// The asset id.
  final String assetId;

  /// The total.
  final Duration total;

  /// The track width.
  final double trackWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.pickerTheme;
    final trimState = ref.watch(videoTrimControllerProvider(assetId, total));
    final mask =
        theme.cropMask.withValues(alpha: VideoCropConstants.maskOpacity);
    final startX = fractionOfTime(trimState.trim.start, total) * trackWidth;
    final endX = fractionOfTime(trimState.trim.end, total) * trackWidth;
    final cursorX = fractionOfTime(trimState.coverAt, total) * trackWidth;
    return Stack(
      children: [
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: startX,
          child: ColoredBox(color: mask),
        ),
        Positioned(
          left: endX,
          top: 0,
          bottom: 0,
          right: 0,
          child: ColoredBox(color: mask),
        ),
        Positioned(
          left: cursorX - VideoCropConstants.coverCursorWidth / 2,
          top: 0,
          bottom: 0,
          child: GestureDetector(
            key: cursorKey,
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) => ref
                .read(videoTrimControllerProvider(assetId, total).notifier)
                .nudgeCover(fractionOfDx(details.delta.dx, trackWidth)),
            onHorizontalDragEnd: (_) => ref
                .read(videoTrimControllerProvider(assetId, total).notifier)
                .endDrag(),
            child: SizedBox(
              width: VideoCropConstants.handleWidth,
              child: Center(
                child: SizedBox(
                  width: VideoCropConstants.coverCursorWidth,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: theme.cropWindowBorder,
                      borderRadius: BorderRadius.circular(theme.chipRadius),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
