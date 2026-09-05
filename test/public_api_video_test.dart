import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';

void main() {
  test('the video rejection model is public, so a consumer can switch on it',
      () {
    const VideoRejection tooLong =
        VideoRejection.tooLong(Duration(seconds: 60));
    const VideoRejection tooLarge = VideoRejection.tooLarge(1024);

    expect(
      switch (tooLong) {
        VideoTooLong(:final max) => max,
        VideoTooLarge() => null,
      },
      const Duration(seconds: 60),
    );
    expect(
      switch (tooLarge) {
        VideoTooLong() => null,
        VideoTooLarge(:final maxBytes) => maxBytes,
      },
      1024,
    );
  });

  test('the exceptions a consumer can catch are public', () {
    expect(
      const VideoRejectedException(VideoRejection.tooLarge(1)),
      isA<Exception>(),
    );
    expect(const VideoUnavailableException('x'), isA<Exception>());
  });

  test('the scrubber mode is public', () {
    expect(ScrubberMode.values, [ScrubberMode.trim, ScrubberMode.cover]);
  });

  test('the byte ceiling is on the config', () {
    expect(const AssetPickerConfig(maxVideoBytes: 42).maxVideoBytes, 42);
    expect(const AssetPickerConfig().maxVideoBytes, isNull);
  });
}
