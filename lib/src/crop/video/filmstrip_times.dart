import 'package:kutu_media_transform/kutu_media_transform.dart';

/// [count] sample times evenly spread across [range].
///
/// Each sample sits at the *centre* of its slice rather than at its leading
/// edge, so the strip never asks for the exact final instant of a clip — a
/// time many decoders return nothing for.
List<Duration> filmstripTimes(DurationRange range, int count) {
  if (count <= 0) return const <Duration>[];
  final span = range.duration.inMicroseconds;
  return List<Duration>.generate(
    count,
    (index) =>
        range.start +
        Duration(microseconds: (span * (index + 0.5) / count).round()),
  );
}
