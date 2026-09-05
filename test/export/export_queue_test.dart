import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/src/config/asset_picker_config.dart';
import 'package:kutu_asset_picker/src/config/crop_aspect.dart';
import 'package:kutu_asset_picker/src/crop/crop_math.dart';
import 'package:kutu_asset_picker/src/crop/crop_state.dart';
import 'package:kutu_asset_picker/src/export/export_queue.dart';
import 'package:kutu_asset_picker/src/result/picked_asset.dart';
import 'package:kutu_asset_picker/src/source/picker_asset.dart';
import 'package:kutu_asset_picker/src/source/picker_media_type.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

import '../support/recording_media_transform.dart';
import '../support/stub_asset_source.dart';

late Directory workDir;

PickerAsset image(String id, {int width = 1000, int height = 1000}) =>
    PickerAsset(
      id: id,
      type: PickerMediaType.image,
      width: width,
      height: height,
      createdAt: DateTime.utc(2026, 8, 4),
    );

PickerAsset video(String id) => PickerAsset(
      id: id,
      type: PickerMediaType.video,
      width: 1920,
      height: 1080,
      createdAt: DateTime.utc(2026, 8, 4),
      duration: const Duration(seconds: 12),
    );

File sourceFile(String id, {int bytes = 64}) {
  final file = File('${workDir.path}/$id.src')
    ..writeAsBytesSync(List<int>.filled(bytes, 7));
  return file;
}

File outputFile(String srcPath) {
  final name = srcPath.split(Platform.pathSeparator).last;
  return File('${workDir.path}/$name.out')
    ..writeAsBytesSync(List<int>.filled(128, 9));
}

CropState Function(String) constantState(CropState state) => (_) => state;

void main() {
  setUp(() => workDir = Directory.systemTemp.createTempSync('export_queue'));
  tearDown(() => workDir.deleteSync(recursive: true));

  const centred = CropState(
    aspect: CropAspect.square,
    scale: 1,
    offset: Offset.zero,
  );

  test('exports run strictly sequentially — never two in flight', () async {
    // Ten 12 MP photos decoded in parallel is roughly 480 MB against a 256 MB
    // Dalvik heap. This is not a tuning knob (spec §7.5), so it is asserted
    // rather than assumed.
    final assets = [for (var i = 0; i < 6; i += 1) image('a$i')];
    final source = StubAssetSource(
      files: {for (final asset in assets) asset.id: sourceFile(asset.id)},
    );
    final transform = RecordingMediaTransform(outputFor: outputFile);

    await ExportQueue(transform: transform, source: source).run(
      assets,
      constantState(centred),
      const AssetPickerConfig(),
    );

    expect(transform.maxConcurrent, 1);
    expect(transform.calls.where((c) => c == 'exportImage'), hasLength(6));
  });

  test('progress reports done and total, starting at zero', () async {
    final assets = [image('a'), image('b'), image('c')];
    final source = StubAssetSource(
      files: {for (final asset in assets) asset.id: sourceFile(asset.id)},
    );
    final seen = <(int, int)>[];

    await ExportQueue(
      transform: RecordingMediaTransform(outputFor: outputFile),
      source: source,
    ).run(
      assets,
      constantState(centred),
      const AssetPickerConfig(),
      onProgress: (done, total) => seen.add((done, total)),
    );

    expect(seen, [(0, 3), (1, 3), (2, 3), (3, 3)]);
  });

  test('a per-asset failure surfaces per asset and never fails the batch',
      () async {
    final assets = [image('a'), image('b'), image('c')];
    final files = {for (final asset in assets) asset.id: sourceFile(asset.id)};
    final source = StubAssetSource(files: files);
    final transform = RecordingMediaTransform(
      outputFor: outputFile,
      failFor: {files['b']!.path: TransformFailure.encoderFailed},
    );
    final queue = ExportQueue(transform: transform, source: source);

    final picked = await queue.run(
      assets,
      constantState(centred),
      const AssetPickerConfig(),
    );

    expect(picked.map((p) => p.id), ['a', 'c']);
    expect(queue.failures, hasLength(1));
    expect(queue.failures.single.assetId, 'b');
    expect(queue.failures.single.failure, TransformFailure.encoderFailed);
  });

  test('an unavailable source file is a sourceUnreadable failure', () async {
    // The grid looks complete over files that live only in iCloud; the failure
    // surfaces here, per asset, rather than as a dead batch (spec §4.5).
    final assets = [image('a'), image('b')];
    final source = StubAssetSource(files: {'a': sourceFile('a')});
    final queue = ExportQueue(
      transform: RecordingMediaTransform(outputFor: outputFile),
      source: source,
    );

    final picked = await queue.run(
      assets,
      constantState(centred),
      const AssetPickerConfig(),
    );

    expect(picked.map((p) => p.id), ['a']);
    expect(queue.failures.single.assetId, 'b');
    expect(queue.failures.single.failure, TransformFailure.sourceUnreadable);
  });

  test('a cancelled token stops the queue mid-batch', () async {
    final assets = [image('a'), image('b'), image('c')];
    final source = StubAssetSource(
      files: {for (final asset in assets) asset.id: sourceFile(asset.id)},
    );
    final token = TransformCancelToken();
    final queue = ExportQueue(
      transform: RecordingMediaTransform(outputFor: outputFile),
      source: source,
    );

    final picked = await queue.run(
      assets,
      constantState(centred),
      const AssetPickerConfig(),
      onProgress: (done, total) {
        if (done == 1) token.cancel();
      },
      cancelToken: token,
    );

    expect(picked.map((p) => p.id), ['a']);
  });

  test('the crop rect handed over is the canonical-window rect', () async {
    // The export path must rebuild the identical rect without knowing anything
    // about the layout (spec §7.4 invariant 2).
    final asset = image('a', width: 2000, height: 1000);
    final source = StubAssetSource(files: {'a': sourceFile('a')});
    final transform = RecordingMediaTransform(outputFor: outputFile);
    const state = CropState(
      aspect: CropAspect.square,
      scale: 1,
      offset: Offset.zero,
    );

    await ExportQueue(transform: transform, source: source).run(
      [asset],
      constantState(state),
      const AssetPickerConfig(),
    );

    final expected = toCropRect(
      reclampForAspect(
        state,
        const Size(2000, 1000),
        cropWindowSize(CropAspect.square, kCanonicalCropArea),
        CropAspect.square,
      ),
      const Size(2000, 1000),
      cropWindowSize(CropAspect.square, kCanonicalCropArea),
    );
    expect(transform.crops.single.left, closeTo(expected.left, 1e-12));
    expect(transform.crops.single.right, closeTo(expected.right, 1e-12));
    expect(transform.crops.single.top, closeTo(expected.top, 1e-12));
    expect(transform.crops.single.bottom, closeTo(expected.bottom, 1e-12));
  });

  test('an untouched asset is exported at its opening framing', () async {
    // stateOf hands back an unsized state for an asset the author never
    // touched; the queue normalizes it rather than exporting a scale of 0.
    final asset = image('a', width: 2000, height: 1000);
    final source = StubAssetSource(files: {'a': sourceFile('a')});
    final transform = RecordingMediaTransform(outputFor: outputFile);

    await ExportQueue(transform: transform, source: source).run(
      [asset],
      constantState(const CropState.unsized(CropAspect.square)),
      const AssetPickerConfig(),
    );

    expect(transform.crops.single.isValid, isTrue);
    expect(transform.crops.single.left, closeTo(0.25, 1e-12));
    expect(transform.crops.single.right, closeTo(0.75, 1e-12));
  });

  test('enableCrop false exports the whole frame through the transform',
      () async {
    // The source is returned through the transcoded path, never originFile:
    // Flutter cannot render HEIC and originFile on HEIC fails outright on
    // Android 10 (spec §7.5).
    final asset = image('a', width: 2000, height: 1000);
    final source = StubAssetSource(files: {'a': sourceFile('a')});
    final transform = RecordingMediaTransform(outputFor: outputFile);

    final picked = await ExportQueue(transform: transform, source: source).run(
      [asset],
      constantState(const CropState.unsized(CropAspect.square)),
      const AssetPickerConfig(enableCrop: false),
    );

    expect(transform.calls, contains('exportImage'));
    expect(transform.crops.single.isFull, isTrue);
    expect(picked.single.mimeType, 'image/jpeg');
    // With no crop the shape is whatever the source was, not a chip's ratio.
    expect(picked.single.aspectRatio, closeTo(2, 1e-12));
  });

  test('a PickedImage carries the exported file and its predicted size',
      () async {
    final asset = image('a', width: 2000, height: 1000);
    final src = sourceFile('a');
    final source = StubAssetSource(files: {'a': src});

    final picked = await ExportQueue(
      transform: RecordingMediaTransform(outputFor: outputFile),
      source: source,
    ).run([asset], constantState(centred), const AssetPickerConfig());

    final result = picked.single;
    expect(result, isA<PickedImage>());
    expect(result.file.existsSync(), isTrue);
    expect(result.sizeBytes, result.file.lengthSync());
    expect(result.width, 1000);
    expect(result.height, 1000);
    expect(result.aspectRatio, closeTo(1, 1e-12));
    expect(result.originalFile, isNull);
  });

  test('keepOriginals hands back the source file too', () async {
    final src = sourceFile('a');
    final source = StubAssetSource(files: {'a': src});

    final picked = await ExportQueue(
      transform: RecordingMediaTransform(outputFor: outputFile),
      source: source,
    ).run(
      [image('a')],
      constantState(centred),
      const AssetPickerConfig(keepOriginals: true),
    );

    expect(picked.single.originalFile?.path, src.path);
  });

  test('a video exports through exportVideo and gets a cover frame', () async {
    final source = StubAssetSource(files: {'v': sourceFile('v')});
    final transform = RecordingMediaTransform(outputFor: outputFile);

    final picked = await ExportQueue(transform: transform, source: source).run(
      [video('v')],
      constantState(
        const CropState(
          aspect: CropAspect.landscape169,
          scale: 1,
          offset: Offset.zero,
          trim: DurationRange(
              start: Duration(seconds: 1), end: Duration(seconds: 5)),
        ),
      ),
      const AssetPickerConfig(),
    );

    final result = picked.single as PickedVideo;
    expect(
        transform.calls, containsAllInOrder(['exportVideo', 'extractFrames']));
    expect(result.duration, const Duration(seconds: 4));
    expect(result.trimmed.start, const Duration(seconds: 1));
    // Non-nullable by contract: a consumer always has a poster to render.
    expect(result.coverFrame.existsSync(), isTrue);
    expect(result.mimeType, 'video/mp4');
  });

  test('a video with no trim uses its whole duration', () async {
    final source = StubAssetSource(files: {'v': sourceFile('v')});

    final picked = await ExportQueue(
      transform: RecordingMediaTransform(outputFor: outputFile),
      source: source,
    ).run([video('v')], constantState(centred), const AssetPickerConfig());

    expect(
        (picked.single as PickedVideo).duration, const Duration(seconds: 12));
  });

  test('failures from a previous run do not leak into the next', () async {
    final source = StubAssetSource(files: {'a': sourceFile('a')});
    final queue = ExportQueue(
      transform: RecordingMediaTransform(outputFor: outputFile),
      source: source,
    );

    await queue.run(
      [image('missing')],
      constantState(centred),
      const AssetPickerConfig(),
    );
    expect(queue.failures, hasLength(1));

    await queue.run(
      [image('a')],
      constantState(centred),
      const AssetPickerConfig(),
    );
    expect(queue.failures, isEmpty);
  });
}
