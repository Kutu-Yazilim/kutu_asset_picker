import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/crop/video/video_display_size.dart';
import 'package:kutu_asset_picker/src/export/video_export_step.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:kutu_media_transform/testing.dart';

void main() {
  const window = Size(300, 300);
  const sourceInfo = VideoInfo(
    duration: Duration(seconds: 30),
    codedWidth: 1920,
    codedHeight: 1080,
    rotationDegrees: 90,
    isHdr: false,
    hasAudio: true,
  );
  const exportedInfo = VideoInfo(
    duration: Duration(seconds: 6),
    codedWidth: 1080,
    codedHeight: 1080,
    rotationDegrees: 0,
    isHdr: false,
    hasAudio: true,
  );
  final asset = PickerAsset(
    id: 'clip-1',
    type: PickerMediaType.video,
    width: 1080,
    height: 1920,
    createdAt: DateTime(2026, 8, 4),
    duration: const Duration(seconds: 30),
  );

  late Directory tempDir;
  late File source;
  late FakeMediaTransform transform;

  CropState stateWith({DurationRange? trim, Duration? coverAt}) => CropState(
        aspect: CropAspect.square,
        scale: scaleToCover(videoDisplaySize(sourceInfo), window) * 1.4,
        offset: const Offset(-12, 8),
        trim: trim,
        coverAt: coverAt,
      );

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('kutu_video_export');
    source = File('${tempDir.path}/source.mp4')
      ..writeAsBytesSync(List<int>.filled(2048, 1));
    // The fake writes the exported file itself, into its own output directory,
    // and `exportedVideoInfo` is what `probeVideo` reports for anything it
    // produced — which is how the exported geometry differs from the source's.
    transform = FakeMediaTransform(videoInfo: sourceInfo)
      ..exportedVideoInfo = exportedInfo;
  });

  tearDown(() {
    transform.dispose();
    tempDir.deleteSync(recursive: true);
  });

  Future<PickedVideo> run({
    required CropState state,
    AssetPickerConfig config = const AssetPickerConfig(),
    void Function(double)? onProgress,
    TransformCancelToken? cancelToken,
  }) =>
      VideoExportStep(transform: transform).export(
        asset: asset,
        source: source,
        info: sourceInfo,
        state: state,
        window: window,
        config: config,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );

  test('crops with exactly the rect the preview showed', () async {
    final state = stateWith(
      trim: const DurationRange(
          start: Duration(seconds: 2), end: Duration(seconds: 8)),
    );

    await run(state: state);

    expect(
      transform.videoExports.single.crop,
      toCropRect(state, videoDisplaySize(sourceInfo), window),
    );
  });

  test('trims to the kept range, and reports it relative to the source',
      () async {
    const trim =
        DurationRange(start: Duration(seconds: 2), end: Duration(seconds: 8));

    final picked = await run(state: stateWith(trim: trim));

    expect(transform.videoExports.single.trim.start, trim.start);
    expect(transform.videoExports.single.trim.end, trim.end);
    expect(picked.trimmed.start, trim.start);
    expect(picked.trimmed.end, trim.end);
    expect(picked.duration, const Duration(seconds: 6));
  });

  test('a null trim means the whole clip', () async {
    final picked = await run(state: stateWith());

    expect(picked.trimmed.start, Duration.zero);
    expect(picked.trimmed.end, sourceInfo.duration);
  });

  test('describes the exported file, not the source', () async {
    final picked = await run(state: stateWith());

    expect(picked.file.parent.path, transform.outputDirectory.path);
    expect(picked.file.path, isNot(source.path));
    expect(picked.sizeBytes, picked.file.lengthSync());
    // The EXPORTED geometry, from probing the output, not asset.width/height —
    // a rotated portrait source would report 1080x1920 there and be wrong.
    expect(picked.width, 1080);
    expect(picked.height, 1080);
    expect(picked.mimeType, 'video/mp4');
    expect(picked.aspectRatio, CropAspect.square.ratio);
    expect(picked.id, asset.id);
  });

  test('with enableCoverFrame, the poster is the chosen instant', () async {
    const trim =
        DurationRange(start: Duration(seconds: 2), end: Duration(seconds: 8));

    final picked = await run(
      state: stateWith(trim: trim, coverAt: const Duration(seconds: 5)),
    );

    // Relative to the exported file, which starts at the in point.
    expect(
        transform.frameExtractions.single.times, const [Duration(seconds: 3)]);
    expect(transform.frameExtractions.single.srcPath, picked.file.path);
    expect(picked.coverFrame.existsSync(), isTrue);
  });

  test('without enableCoverFrame, the poster is the first trimmed frame',
      () async {
    const trim =
        DurationRange(start: Duration(seconds: 2), end: Duration(seconds: 8));

    final picked = await run(
      state: stateWith(trim: trim, coverAt: const Duration(seconds: 5)),
      config: const AssetPickerConfig(enableCoverFrame: false),
    );

    expect(transform.frameExtractions.single.times, const [Duration.zero]);
    expect(picked.coverFrame.existsSync(), isTrue);
  });

  test('a cover instant outside the range is pulled back inside', () async {
    const trim =
        DurationRange(start: Duration(seconds: 2), end: Duration(seconds: 8));

    await run(
      state: stateWith(trim: trim, coverAt: const Duration(seconds: 25)),
    );

    expect(
        transform.frameExtractions.single.times, const [Duration(seconds: 6)]);
  });

  test('the poster is extracted at the exported resolution', () async {
    await run(state: stateWith());

    expect(transform.frameExtractions.single.size.width, 1080);
    expect(transform.frameExtractions.single.size.height, 1080);
  });

  test('keeps the original only when asked', () async {
    final without = await run(state: stateWith());
    expect(without.originalFile, isNull);

    final with_ = await run(
      state: stateWith(),
      config: const AssetPickerConfig(keepOriginals: true),
    );
    expect(with_.originalFile!.path, source.path);
  });

  test('reports progress through to the caller', () async {
    final seen = <double>[];
    transform.onExportVideo = (report) async {
      report(0.25);
      report(0.75);
    };

    await run(state: stateWith(), onProgress: seen.add);

    // The fake brackets the hook with its own 0 and 1 (slice 2's contract), so
    // the caller sees the whole ramp, hook values included, in order.
    expect(seen, [0.0, 0.25, 0.75, 1.0]);
  });

  test('propagates a cancellation instead of writing a cover', () async {
    final token = TransformCancelToken()..cancel();

    await expectLater(
      run(state: stateWith(), cancelToken: token),
      throwsA(
        isA<TransformException>()
            .having((e) => e.failure, 'failure', TransformFailure.cancelled),
      ),
    );
    expect(transform.frameExtractions, isEmpty);
  });

  test('refuses to guess from a degenerate crop window', () async {
    await expectLater(
      VideoExportStep(transform: transform).export(
        asset: asset,
        source: source,
        info: sourceInfo,
        state: stateWith(),
        window: Size.zero,
        config: const AssetPickerConfig(),
      ),
      throwsA(isA<TransformException>()),
    );
    expect(transform.videoExports, isEmpty);
  });

  group('the single retry (spec §4.5)', () {
    test('a first failure is retried once and the retry is what ships',
        () async {
      var attempts = 0;
      transform.onExportVideo = (report) async {
        attempts += 1;
        if (attempts == 1) {
          throw const TransformException(
            TransformFailure.encoderFailed,
            'AVAssetExportSession failed on a freshly-downloaded asset',
          );
        }
      };

      final picked = await run(state: stateWith());

      expect(attempts, 2);
      expect(transform.videoExports, hasLength(2));
      expect(picked.coverFrame.existsSync(), isTrue);
    });

    test('a second failure is what the caller sees', () async {
      var attempts = 0;
      transform.onExportVideo = (report) async {
        attempts += 1;
        throw const TransformException(
          TransformFailure.encoderFailed,
          'still failing',
        );
      };

      await expectLater(
        run(state: stateWith()),
        throwsA(
          isA<TransformException>().having(
            (e) => e.failure,
            'failure',
            TransformFailure.encoderFailed,
          ),
        ),
      );
      expect(attempts, 2);
      expect(transform.frameExtractions, isEmpty);
    });

    test('a cancellation is never retried', () async {
      final token = TransformCancelToken();
      var attempts = 0;
      transform.onExportVideo = (report) async {
        attempts += 1;
        token.cancel();
      };

      await expectLater(
        run(state: stateWith(), cancelToken: token),
        throwsA(
          isA<TransformException>()
              .having((e) => e.failure, 'failure', TransformFailure.cancelled),
        ),
      );
      // Retrying a cancel would ignore the author pressing Cancel and start the
      // multi-second export a second time.
      expect(attempts, 1);
    });
  });
}
