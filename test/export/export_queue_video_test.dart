import 'dart:async';
import 'dart:io';
import 'dart:ui' show Offset, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/testing.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:kutu_media_transform/testing.dart';

void main() {
  const sourceInfo = VideoInfo(
    duration: Duration(seconds: 30),
    codedWidth: 1920,
    codedHeight: 1080,
    // A rotated portrait clip: the gallery reports 1080x1920, the coded frame
    // is 1920x1080, and only videoDisplaySize gets that right.
    rotationDegrees: 90,
    isHdr: false,
    hasAudio: true,
  );
  const exportedInfo = VideoInfo(
    duration: Duration(seconds: 30),
    codedWidth: 1080,
    codedHeight: 1080,
    rotationDegrees: 0,
    isHdr: false,
    hasAudio: true,
  );

  late Directory tempDir;
  late File clipA;
  late File clipB;
  late FakeMediaTransform transform;
  late FakeAssetSource source;

  PickerAsset videoAsset(String id) => PickerAsset(
        id: id,
        type: PickerMediaType.video,
        width: 1080,
        height: 1920,
        createdAt: DateTime(2026, 8, 4),
        duration: const Duration(seconds: 30),
      );

  /// The framing the author left behind, in the canonical frame every stored
  /// `CropState` uses (slice 4, `kCanonicalCropArea`).
  CropState state() {
    final window = cropWindowSize(CropAspect.square, kCanonicalCropArea);
    return CropState(
      aspect: CropAspect.square,
      scale: scaleToCover(const Size(1080, 1920), window),
      offset: Offset.zero,
    );
  }

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('kutu_export_queue');
    clipA = File('${tempDir.path}/a.mp4')..writeAsBytesSync([1, 2, 3]);
    clipB = File('${tempDir.path}/b.mp4')..writeAsBytesSync([4, 5, 6]);
    transform = FakeMediaTransform(videoInfo: sourceInfo)
      ..exportedVideoInfo = exportedInfo;
    source = FakeAssetSource();
    source.filesById
      ..['a'] = clipA
      ..['b'] = clipB;
  });

  tearDown(() {
    source.dispose();
    transform.dispose();
    tempDir.deleteSync(recursive: true);
  });

  test('routes a video asset to the video path and yields a PickedVideo',
      () async {
    final queue = ExportQueue(transform: transform, source: source);

    final results = await queue.run(
      [videoAsset('a')],
      (_) => state(),
      const AssetPickerConfig(),
    );

    expect(results.single, isA<PickedVideo>());
    expect(transform.videoExports, hasLength(1));
    expect(queue.failures, isEmpty);
  });

  test('crops against the ROTATED display size, not the gallery dimensions',
      () async {
    await ExportQueue(transform: transform, source: source).run(
      [videoAsset('a')],
      (_) => state(),
      const AssetPickerConfig(),
    );

    final window = cropWindowSize(CropAspect.square, kCanonicalCropArea);
    const display = Size(1080, 1920);
    expect(
      transform.videoExports.single.crop,
      toCropRect(
        reclampForAspect(state(), display, window, CropAspect.square),
        display,
        window,
      ),
    );
  });

  test('runs strictly one at a time', () async {
    var inFlight = 0;
    var maxInFlight = 0;
    var started = 0;
    final gate = Completer<void>();
    transform.onExportVideo = (report) async {
      inFlight++;
      maxInFlight = inFlight > maxInFlight ? inFlight : maxInFlight;
      started++;
      if (started == 1) await gate.future;
      inFlight--;
    };

    final run = ExportQueue(transform: transform, source: source).run(
      [videoAsset('a'), videoAsset('b')],
      (_) => state(),
      const AssetPickerConfig(),
    );
    await Future<void>.delayed(Duration.zero);
    expect(started, 1);

    gate.complete();
    await run;

    expect(maxInFlight, 1);
    expect(transform.videoExports, hasLength(2));
  });

  test('reports coarse per-asset progress and fine within-asset progress',
      () async {
    final coarse = <(int, int)>[];
    final fine = <(int, double)>[];
    transform.onExportVideo = (report) async => report(0.5);

    await ExportQueue(transform: transform, source: source).run(
      [videoAsset('a'), videoAsset('b')],
      (_) => state(),
      const AssetPickerConfig(),
      onProgress: (done, total) => coarse.add((done, total)),
      onAssetFraction: (index, fraction) => fine.add((index, fraction)),
    );

    expect(coarse, [(0, 2), (1, 2), (2, 2)]);
    expect(fine, contains((0, 0.5)));
    expect(fine, contains((1, 0.5)));
  });

  test('a cancel stops the batch and returns what finished', () async {
    final token = TransformCancelToken();
    var exports = 0;
    transform.onExportVideo = (report) async {
      exports++;
      token.cancel();
    };

    final queue = ExportQueue(transform: transform, source: source);
    final results = await queue.run(
      [videoAsset('a'), videoAsset('b')],
      (_) => state(),
      const AssetPickerConfig(),
      cancelToken: token,
    );

    expect(exports, 1);
    expect(results, isEmpty);
    expect(
      queue.failures.single.failure,
      TransformFailure.cancelled,
    );
  });

  test('one failing video is retried once, then isolated — the batch survives',
      () async {
    var attempts = 0;
    transform.onExportVideo = (report) async {
      attempts++;
      // 'a' is the first asset, so its two attempts are 1 and 2.
      if (attempts <= 2) {
        throw const TransformException(
          TransformFailure.encoderFailed,
          'encoder said no',
        );
      }
    };

    final queue = ExportQueue(transform: transform, source: source);
    final results = await queue.run(
      [videoAsset('a'), videoAsset('b')],
      (_) => state(),
      const AssetPickerConfig(),
    );

    expect(attempts, 3, reason: 'two for a — the retry — and one for b');
    expect(results.single, isA<PickedVideo>());
    expect(results.single.id, 'b');
    expect(queue.failures.single.assetId, 'a');
    expect(queue.failures.single.failure, TransformFailure.encoderFailed);
  });

  test('an asset the gallery cannot produce is a per-asset failure', () async {
    source.missingFiles.add('a');

    final queue = ExportQueue(transform: transform, source: source);
    final results = await queue.run(
      [videoAsset('a'), videoAsset('b')],
      (_) => state(),
      const AssetPickerConfig(),
    );

    expect(results.single.id, 'b');
    expect(
      queue.failures.single.failure,
      TransformFailure.sourceUnreadable,
    );
  });
}
