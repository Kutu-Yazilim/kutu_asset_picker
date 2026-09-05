import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/crop/video/video_rejection.dart';
import 'package:kutu_asset_picker/src/picker/video_selection_guard.dart';

void main() {
  PickerAsset video(Duration? duration) => PickerAsset(
        id: 'v',
        type: PickerMediaType.video,
        width: 1080,
        height: 1920,
        createdAt: DateTime(2026, 8, 4),
        duration: duration,
      );

  final image = PickerAsset(
    id: 'i',
    type: PickerMediaType.image,
    width: 4032,
    height: 3024,
    createdAt: DateTime(2026, 8, 4),
  );

  const capped = AssetPickerConfig(maxVideoDuration: Duration(seconds: 60));

  test('an image is never rejected on duration', () {
    expect(videoSelectionRejection(image, capped), isNull);
  });

  test('a video under the cap passes', () {
    expect(
      videoSelectionRejection(video(const Duration(seconds: 59)), capped),
      isNull,
    );
  });

  test('a video exactly at the cap passes', () {
    expect(
      videoSelectionRejection(video(const Duration(seconds: 60)), capped),
      isNull,
    );
  });

  test('a video over the cap is rejected with the cap in the message', () {
    final rejection =
        videoSelectionRejection(video(const Duration(seconds: 61)), capped);

    expect(
      rejection,
      isA<VideoTooLong>()
          .having((r) => r.max, 'max', const Duration(seconds: 60)),
    );
  });

  test('no cap means no rejection', () {
    expect(
      videoSelectionRejection(
        video(const Duration(hours: 3)),
        const AssetPickerConfig(),
      ),
      isNull,
    );
  });

  test('a null duration is NOT rejected — the video must not vanish', () {
    // Android returns a null MediaStore duration for some downloads and
    // third-party recorders (spec §4.5). Refusing those would hide real files.
    expect(videoSelectionRejection(video(null), capped), isNull);
  });
}
