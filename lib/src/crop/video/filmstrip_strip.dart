import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

import 'filmstrip_frame_tile.dart';
import 'filmstrip_frames.dart';
import '../../theme/asset_picker_theme_scope.dart';

/// The frames behind the scrubber, spanning the **whole** clip.
///
/// The whole clip on purpose: the handles slide over it to select a sub-range,
/// so a strip showing only the current range would move under its own handles.
class FilmstripStrip extends ConsumerWidget {
  /// Creates a [FilmstripStrip].
  const FilmstripStrip({super.key, required this.srcPath, required this.total});

  /// The src path.
  final String srcPath;

  /// The total.
  final Duration total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.pickerTheme;
    final frames = ref.watch(
      filmstripFramesProvider(
        filmstripRequestFor(
          srcPath,
          DurationRange(start: Duration.zero, end: total),
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(theme.chipRadius),
      child: frames.when(
        loading: () => ColoredBox(color: theme.cropMask),
        error: (_, __) => ColoredBox(color: theme.cropMask),
        data: (bytes) => Row(
          children: [
            for (final frame in bytes)
              Expanded(child: FilmstripFrameTile(bytes: frame)),
          ],
        ),
      ),
    );
  }
}
