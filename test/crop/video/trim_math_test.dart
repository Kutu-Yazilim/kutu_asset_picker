import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/src/crop/video/trim_math.dart';
import 'package:kutu_asset_picker/src/crop/video/video_crop_constants.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

void main() {
  const total = Duration(seconds: 30);
  const cap = Duration(seconds: 10);

  group('initialTrim', () {
    test('keeps the whole clip when there is no cap', () {
      final trim = initialTrim(total, null);

      expect(trim.start, Duration.zero);
      expect(trim.end, total);
    });

    test('keeps the whole clip when the cap is longer than the clip', () {
      final trim = initialTrim(const Duration(seconds: 4), cap);

      expect(trim.end, const Duration(seconds: 4));
    });

    test('takes the leading cap-length window when the clip is longer', () {
      final trim = initialTrim(total, cap);

      expect(trim.start, Duration.zero);
      expect(trim.end, cap);
    });
  });

  group('trimWithStart', () {
    test('moves the in point and leaves the out point alone', () {
      const current =
          DurationRange(start: Duration.zero, end: Duration(seconds: 8));

      final next =
          trimWithStart(current, const Duration(seconds: 3), total, null);

      expect(next.start, const Duration(seconds: 3));
      expect(next.end, const Duration(seconds: 8));
    });

    test('refuses to cross the out point, leaving the minimum window', () {
      const current =
          DurationRange(start: Duration.zero, end: Duration(seconds: 8));

      final next =
          trimWithStart(current, const Duration(seconds: 20), total, null);

      expect(next.start,
          const Duration(seconds: 8) - VideoCropConstants.minTrimDuration);
      expect(next.duration, VideoCropConstants.minTrimDuration);
    });

    test('never goes negative', () {
      const current =
          DurationRange(start: Duration(seconds: 5), end: Duration(seconds: 8));

      final next =
          trimWithStart(current, const Duration(seconds: -4), total, null);

      expect(next.start, Duration.zero);
    });

    test('drags the out point along when widening past the cap', () {
      const current = DurationRange(
          start: Duration(seconds: 15), end: Duration(seconds: 25));

      final next =
          trimWithStart(current, const Duration(seconds: 5), total, cap);

      expect(next.start, const Duration(seconds: 5));
      expect(next.end, const Duration(seconds: 15));
      expect(next.duration, cap);
    });
  });

  group('trimWithEnd', () {
    test('moves the out point and leaves the in point alone', () {
      const current =
          DurationRange(start: Duration(seconds: 2), end: Duration(seconds: 8));

      final next =
          trimWithEnd(current, const Duration(seconds: 12), total, null);

      expect(next.start, const Duration(seconds: 2));
      expect(next.end, const Duration(seconds: 12));
    });

    test('clamps to the end of the clip', () {
      const current =
          DurationRange(start: Duration(seconds: 2), end: Duration(seconds: 8));

      final next =
          trimWithEnd(current, const Duration(seconds: 90), total, null);

      expect(next.end, total);
    });

    test('refuses to cross the in point, leaving the minimum window', () {
      const current =
          DurationRange(start: Duration(seconds: 6), end: Duration(seconds: 8));

      final next =
          trimWithEnd(current, const Duration(seconds: 1), total, null);

      expect(next.end,
          const Duration(seconds: 6) + VideoCropConstants.minTrimDuration);
      expect(next.duration, VideoCropConstants.minTrimDuration);
    });

    test('drags the in point along when widening past the cap', () {
      const current = DurationRange(
          start: Duration(seconds: 2), end: Duration(seconds: 11));

      final next =
          trimWithEnd(current, const Duration(seconds: 20), total, cap);

      expect(next.end, const Duration(seconds: 20));
      expect(next.start, const Duration(seconds: 10));
      expect(next.duration, cap);
    });
  });

  group('clampCoverAt', () {
    const trim =
        DurationRange(start: Duration(seconds: 4), end: Duration(seconds: 9));

    test('passes an in-range time through', () {
      expect(clampCoverAt(const Duration(seconds: 6), trim),
          const Duration(seconds: 6));
    });

    test('pulls an earlier time up to the in point', () {
      expect(clampCoverAt(Duration.zero, trim), const Duration(seconds: 4));
    });

    test('pushes a later time down to the out point', () {
      expect(clampCoverAt(const Duration(seconds: 25), trim),
          const Duration(seconds: 9));
    });
  });

  group('time and fraction conversion', () {
    test('round-trips a mid-clip time', () {
      expect(timeAtFraction(0.5, total), const Duration(seconds: 15));
      expect(fractionOfTime(const Duration(seconds: 15), total), 0.5);
    });

    test('clamps out-of-range fractions on both sides', () {
      expect(timeAtFraction(-1, total), Duration.zero);
      expect(timeAtFraction(4, total), total);
    });

    test('survives a zero-length clip instead of dividing by zero', () {
      expect(fractionOfTime(const Duration(seconds: 3), Duration.zero), 0);
    });

    test('fractionOfDx is a plain ratio and survives a zero width', () {
      expect(fractionOfDx(30, 120), 0.25);
      expect(fractionOfDx(-30, 120), -0.25);
      expect(fractionOfDx(30, 0), 0);
    });
  });

  group('resumePoint', () {
    const trim = DurationRange(
      start: Duration(seconds: 10),
      end: Duration(seconds: 20),
    );

    test('resumes from a playhead inside the kept range', () {
      expect(
        resumePoint(const Duration(seconds: 15), trim),
        const Duration(seconds: 15),
      );
      expect(resumePoint(trim.start, trim), trim.start);
    });

    test('restarts from the in point when there is no playhead', () {
      expect(resumePoint(null, trim), trim.start);
    });

    test('restarts from the in point when the playhead has left the range', () {
      // The out point itself counts as outside: resuming there would loop on
      // the very first poll.
      expect(resumePoint(trim.end, trim), trim.start);
      expect(resumePoint(const Duration(seconds: 30), trim), trim.start);
      expect(resumePoint(const Duration(seconds: 2), trim), trim.start);
    });
  });

  group('trimShifted', () {
    const total = Duration(seconds: 40);
    const current = DurationRange(
      start: Duration(seconds: 10),
      end: Duration(seconds: 20),
    );

    test('carries both ends by the same amount, keeping the duration', () {
      final next = trimShifted(current, const Duration(seconds: 15), total);

      expect(next.start, const Duration(seconds: 25));
      expect(next.end, const Duration(seconds: 35));
      expect(next.duration, current.duration);
    });

    test('stops at the end of the clip without shrinking', () {
      final next = trimShifted(current, const Duration(seconds: 30), total);

      expect(next.end, total);
      expect(next.start, const Duration(seconds: 30));
      expect(next.duration, current.duration);
    });

    test('stops at the start of the clip without shrinking', () {
      final next = trimShifted(current, const Duration(seconds: -30), total);

      expect(next.start, Duration.zero);
      expect(next.end, const Duration(seconds: 10));
    });

    test('a range as long as the clip cannot move at all', () {
      const whole = DurationRange(start: Duration.zero, end: total);

      expect(trimShifted(whole, const Duration(seconds: 5), total), whole);
    });
  });
}
