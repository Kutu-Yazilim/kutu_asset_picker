import 'package:flutter/widgets.dart';
import 'dart:typed_data';

/// One extracted frame in the strip.
///
/// `gaplessPlayback` because the strip is re-extracted when the source path
/// changes, and a flash to blank between two strips reads as a glitch.
class FilmstripFrameTile extends StatelessWidget {
  const FilmstripFrameTile({super.key, required this.bytes});

  final Uint8List bytes;

  @override
  Widget build(BuildContext context) => Image.memory(
        bytes,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        filterQuality: FilterQuality.low,
      );
}
