import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/picker/slow_motion_flatten_step.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:kutu_media_transform/testing.dart';

void main() {
  late Directory tempDir;
  late File source;

  /// What the *gallery* says, which for a slow-motion clip is the played-back
  /// duration the user saw.
  PickerAsset clip(Duration? galleryDuration) => PickerAsset(
        id: 'slow-1',
        type: PickerMediaType.video,
        width: 1080,
        height: 1920,
        createdAt: DateTime(2026, 8, 4),
        duration: galleryDuration,
      );

  /// What the *file* says, which for an un-flattened slow-motion clip is a
  /// fraction of it.
  VideoInfo fileInfo(Duration duration) => VideoInfo(
        duration: duration,
        codedWidth: 1920,
        codedHeight: 1080,
        rotationDegrees: 90,
        isHdr: false,
        hasAudio: true,
      );

  FakeMediaTransform fakeWith(Duration fileDuration) {
    final fake = FakeMediaTransform(videoInfo: fileInfo(fileDuration));
    addTearDown(fake.dispose);
    return fake;
  }

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('kutu_slow_motion_step');
    source = File('${tempDir.path}/slow.mov')..writeAsBytesSync([1, 2, 3]);
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  Future<File?> flatten(
    FakeMediaTransform transform,
    PickerAsset asset, {
    void Function(double)? onProgress,
    TransformCancelToken? cancelToken,
  }) =>
      SlowMotionFlattenStep(transform: transform).flatten(
        asset: asset,
        source: source,
        settings: const VideoEncodeSettings(),
        onProgress: onProgress,
        cancelToken: cancelToken,
      );

  test('a file whose timeline already matches the gallery is left alone',
      () async {
    final transform = fakeWith(const Duration(seconds: 12));

    expect(await flatten(transform, clip(const Duration(seconds: 12))), isNull);
    expect(transform.videoExports, isEmpty);
    expect(transform.probedPaths, [source.path]);
  });

  test('a skew inside the tolerance is metadata noise, not slow motion',
      () async {
    // 200 ms < SlowMotionFlattener.durationTolerance. Container durations and
    // gallery metadata disagree by a few frames constantly.
    final transform = fakeWith(const Duration(seconds: 12, milliseconds: 200));

    expect(await flatten(transform, clip(const Duration(seconds: 12))), isNull);
    expect(transform.videoExports, isEmpty);
  });

  test('a 4x skew is rewritten, whole and uncropped', () async {
    final transform = fakeWith(const Duration(seconds: 3));

    final flattened =
        await flatten(transform, clip(const Duration(seconds: 12)));

    expect(flattened, isNotNull);
    expect(flattened!.path, isNot(source.path));
    expect(flattened.existsSync(), isTrue);
    // A flatten is a straight re-encode: no crop, no trim. The framing belongs
    // to the crop step and the range to the trim rail, both of which run later
    // and both of which assume a timeline that is already correct.
    expect(transform.videoExports.single.crop.isFull, isTrue);
    expect(transform.videoExports.single.trim.start, Duration.zero);
    expect(transform.videoExports.single.trim.end, const Duration(seconds: 3));
  });

  test('an image is never probed, let alone transcoded', () async {
    final transform = fakeWith(const Duration(seconds: 3));
    final photo = PickerAsset(
      id: 'pic',
      type: PickerMediaType.image,
      width: 4032,
      height: 3024,
      createdAt: DateTime(2026, 8, 4),
    );

    expect(await flatten(transform, photo), isNull);
    expect(transform.probedPaths, isEmpty);
  });

  test('a video with no gallery duration is left alone', () async {
    // contract §3: duration is null for videos with absent metadata. There is
    // nothing to compare against, and transcoding on a guess would re-encode
    // every such clip for nothing.
    final transform = fakeWith(const Duration(seconds: 3));

    expect(await flatten(transform, clip(null)), isNull);
    expect(transform.probedPaths, isEmpty);
  });

  test('progress reaches the caller, because this wait needs a face', () async {
    final transform = fakeWith(const Duration(seconds: 3));
    transform.onExportVideo = (report) async => report(0.5);
    final seen = <double>[];

    await flatten(
      transform,
      clip(const Duration(seconds: 12)),
      onProgress: seen.add,
    );

    expect(seen, [0, 0.5, 1]);
  });

  test('a cancelled flatten throws instead of returning the raw file',
      () async {
    final transform = fakeWith(const Duration(seconds: 3));
    final token = TransformCancelToken()..cancel();

    await expectLater(
      flatten(transform, clip(const Duration(seconds: 12)), cancelToken: token),
      throwsA(
        isA<TransformException>()
            .having((e) => e.failure, 'failure', TransformFailure.cancelled),
      ),
    );
  });
}
