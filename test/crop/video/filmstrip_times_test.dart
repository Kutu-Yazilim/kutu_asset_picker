import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/src/crop/video/filmstrip_times.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

void main() {
  group('filmstripTimes', () {
    test('samples the centre of each equal slice', () {
      final times = filmstripTimes(
        const DurationRange(start: Duration.zero, end: Duration(seconds: 4)),
        4,
      );

      expect(times, const [
        Duration(milliseconds: 500),
        Duration(milliseconds: 1500),
        Duration(milliseconds: 2500),
        Duration(milliseconds: 3500),
      ]);
    });

    test('is offset by the range start', () {
      final times = filmstripTimes(
        const DurationRange(
            start: Duration(seconds: 10), end: Duration(seconds: 12)),
        2,
      );

      expect(times, const [
        Duration(milliseconds: 10500),
        Duration(milliseconds: 11500),
      ]);
    });

    test('never samples the exact final instant, which decoders often refuse',
        () {
      final times = filmstripTimes(
        const DurationRange(start: Duration.zero, end: Duration(seconds: 3)),
        3,
      );

      expect(times.last, lessThan(const Duration(seconds: 3)));
    });

    test('returns nothing for a non-positive count', () {
      expect(
        filmstripTimes(
          const DurationRange(start: Duration.zero, end: Duration(seconds: 3)),
          0,
        ),
        isEmpty,
      );
      expect(
        filmstripTimes(
          const DurationRange(start: Duration.zero, end: Duration(seconds: 3)),
          -2,
        ),
        isEmpty,
      );
    });

    test('a zero-length range still yields count entries, all at the start',
        () {
      final times = filmstripTimes(
        const DurationRange(
            start: Duration(seconds: 5), end: Duration(seconds: 5)),
        3,
      );

      expect(times, const [
        Duration(seconds: 5),
        Duration(seconds: 5),
        Duration(seconds: 5),
      ]);
    });
  });
}
