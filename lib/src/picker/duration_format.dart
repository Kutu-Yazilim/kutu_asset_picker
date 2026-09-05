/// Formats a media duration as `m:ss`, or `h:mm:ss` once it passes an hour.
///
/// Pure, so the grid cell has no formatting logic of its own (Flutter rule 6),
/// and so the edge cases are unit-tested rather than eyeballed.
String formatPickerDuration(Duration duration) {
  final int totalSeconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
  final int hours = totalSeconds ~/ 3600;
  final int minutes = (totalSeconds % 3600) ~/ 60;
  final int seconds = totalSeconds % 60;
  final String paddedSeconds = seconds.toString().padLeft(2, '0');

  if (hours == 0) {
    return '$minutes:$paddedSeconds';
  }
  return '$hours:${minutes.toString().padLeft(2, '0')}:$paddedSeconds';
}
