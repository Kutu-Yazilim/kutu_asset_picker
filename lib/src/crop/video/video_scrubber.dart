import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cover_cursor_overlay.dart';
import 'filmstrip_strip.dart';
import 'scrubber_mode.dart';
import 'trim_handles_overlay.dart';
import 'video_crop_constants.dart';

/// One filmstrip, two modes.
///
/// The strip, its geometry and its seek path are shared; the mode only decides
/// which overlay sits on top. That is what "the cover picker is a second mode
/// on the same scrubber infrastructure" means concretely (spec §6.3).
class VideoScrubber extends ConsumerWidget {
  const VideoScrubber({
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
    final mode = ref.watch(scrubberModeControllerProvider);
    return SizedBox(
      height: VideoCropConstants.filmstripHeight,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          fit: StackFit.expand,
          children: [
            FilmstripStrip(srcPath: srcPath, total: total),
            if (mode == ScrubberMode.trim)
              TrimHandlesOverlay(
                assetId: assetId,
                total: total,
                trackWidth: constraints.maxWidth,
              ),
            if (mode == ScrubberMode.cover)
              CoverCursorOverlay(
                assetId: assetId,
                total: total,
                trackWidth: constraints.maxWidth,
              ),
          ],
        ),
      ),
    );
  }
}
