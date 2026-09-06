import 'package:kutu_media_transform/kutu_media_transform.dart';

import 'video_crop_constants.dart';

Duration _clamp(Duration value, Duration min, Duration max) {
  if (max < min) return min;
  if (value < min) return min;
  if (value > max) return max;
  return value;
}

/// The trim a freshly-opened video starts with: the whole clip, or its leading
/// [maxDuration] when the clip is longer than the cap.
DurationRange initialTrim(Duration total, Duration? maxDuration) {
  final end = maxDuration == null || maxDuration >= total ? total : maxDuration;
  return DurationRange(start: Duration.zero, end: end);
}

/// Move the in point.
///
/// The out point stays put, except that widening the window past [maxDuration]
/// drags it left — the window slides rather than silently exceeding the cap.
DurationRange trimWithStart(
  DurationRange current,
  Duration start,
  Duration total,
  Duration? maxDuration,
) {
  final latest = current.end - VideoCropConstants.minTrimDuration;
  final nextStart = _clamp(start, Duration.zero, latest);
  var nextEnd = current.end;
  if (maxDuration != null && nextEnd - nextStart > maxDuration) {
    nextEnd = _clamp(
      nextStart + maxDuration,
      nextStart + VideoCropConstants.minTrimDuration,
      total,
    );
  }
  return DurationRange(start: nextStart, end: nextEnd);
}

/// Move the out point. Mirror of [trimWithStart].
DurationRange trimWithEnd(
  DurationRange current,
  Duration end,
  Duration total,
  Duration? maxDuration,
) {
  final earliest = current.start + VideoCropConstants.minTrimDuration;
  final nextEnd = _clamp(end, earliest, total);
  var nextStart = current.start;
  if (maxDuration != null && nextEnd - nextStart > maxDuration) {
    nextStart = _clamp(
      nextEnd - maxDuration,
      Duration.zero,
      nextEnd - VideoCropConstants.minTrimDuration,
    );
  }
  return DurationRange(start: nextStart, end: nextEnd);
}

/// A cover frame only ever lives inside the kept range.
Duration clampCoverAt(Duration proposed, DurationRange trim) =>
    _clamp(proposed, trim.start, trim.end);

/// Where playback resumes: the playhead while it is inside the kept range,
/// otherwise the in point.
///
/// The out point itself counts as outside — resuming there would loop on the
/// very first poll.
Duration resumePoint(Duration? playhead, DurationRange trim) =>
    playhead != null && playhead >= trim.start && playhead < trim.end
        ? playhead
        : trim.start;

/// Time at fraction.
Duration timeAtFraction(double fraction, Duration total) => Duration(
      microseconds: (total.inMicroseconds * fraction.clamp(0.0, 1.0)).round(),
    );

/// Fraction of time.
double fractionOfTime(Duration time, Duration total) =>
    total.inMicroseconds == 0
        ? 0
        : (time.inMicroseconds / total.inMicroseconds).clamp(0.0, 1.0);

/// Horizontal drag distance as a fraction of the scrubber's width.
///
/// Signed and unclamped on purpose — it is a *delta*, and the trim functions
/// above own all the clamping.
double fractionOfDx(double dx, double width) => width <= 0 ? 0 : dx / width;
