import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/src/picker/duration_format.dart';

void main() {
  test('formats sub-minute durations with a padded seconds field', () {
    expect(formatPickerDuration(const Duration(seconds: 7)), '0:07');
    expect(formatPickerDuration(Duration.zero), '0:00');
    expect(formatPickerDuration(const Duration(seconds: 59)), '0:59');
  });

  test('formats minutes without padding the leading field', () {
    expect(
        formatPickerDuration(const Duration(minutes: 1, seconds: 23)), '1:23');
    expect(
        formatPickerDuration(const Duration(minutes: 12, seconds: 5)), '12:05');
  });

  test('adds an hours field only past an hour', () {
    expect(
      formatPickerDuration(const Duration(hours: 1, minutes: 2, seconds: 3)),
      '1:02:03',
    );
    expect(formatPickerDuration(const Duration(minutes: 59, seconds: 59)),
        '59:59');
  });

  test('rounds sub-second remainders down rather than showing 0:00.9', () {
    expect(formatPickerDuration(const Duration(milliseconds: 1900)), '0:01');
  });

  test('a negative duration clamps to zero instead of rendering nonsense', () {
    expect(formatPickerDuration(const Duration(seconds: -5)), '0:00');
  });
}
