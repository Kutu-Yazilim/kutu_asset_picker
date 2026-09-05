import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/crop/video/video_preview_source.dart';
import 'package:kutu_asset_picker/testing.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:kutu_media_transform/testing.dart';

void main() {
  late Directory tempDir;
  late File clip;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('kutu_preview_source');
    clip = File('${tempDir.path}/clip.mp4')
      ..writeAsBytesSync(List<int>.filled(4096, 7));
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  ProviderContainer containerWith({
    required AssetPickerConfig config,
    required VideoInfo info,
    bool missing = false,
  }) {
    final source = FakeAssetSource();
    addTearDown(source.dispose);
    if (missing) {
      source.missingFiles.add('clip-1');
    } else {
      source.filesById['clip-1'] = clip;
    }
    final transform = FakeMediaTransform(videoInfo: info);
    addTearDown(transform.dispose);

    final container = ProviderContainer(
      overrides: [
        assetPickerConfigProvider.overrideWithValue(config),
        assetSourceProvider.overrideWithValue(source),
        mediaTransformProvider.overrideWithValue(transform),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  const info = VideoInfo(
    duration: Duration(seconds: 30),
    codedWidth: 1920,
    codedHeight: 1080,
    rotationDegrees: 90,
    isHdr: false,
    hasAudio: true,
  );

  test('resolves the file, its byte size and its probed info', () async {
    final container = containerWith(
      config: const AssetPickerConfig(),
      info: info,
    );

    final preview = await _load(container, 'clip-1');

    expect(preview.file.path, clip.path);
    expect(preview.sizeBytes, 4096);
    expect(preview.info.displayWidth, 1080);
    expect(preview.info.displayHeight, 1920);
  });

  test('rejects a clip longer than maxVideoDuration', () async {
    final container = containerWith(
      config: const AssetPickerConfig(maxVideoDuration: Duration(seconds: 10)),
      info: info,
    );

    await expectLater(
      _load(container, 'clip-1'),
      throwsA(
        isA<VideoRejectedException>().having(
          (e) => e.rejection,
          'rejection',
          isA<VideoTooLong>().having(
            (r) => r.max,
            'max',
            const Duration(seconds: 10),
          ),
        ),
      ),
    );
  });

  test('rejects a file larger than maxVideoBytes', () async {
    final container = containerWith(
      config: const AssetPickerConfig(maxVideoBytes: 1024),
      info: info,
    );

    await expectLater(
      _load(container, 'clip-1'),
      throwsA(
        isA<VideoRejectedException>().having(
          (e) => e.rejection,
          'rejection',
          isA<VideoTooLarge>().having((r) => r.maxBytes, 'maxBytes', 1024),
        ),
      ),
    );
  });

  test('checks the byte ceiling before spending a probe', () async {
    final source = FakeAssetSource();
    addTearDown(source.dispose);
    source.filesById['clip-1'] = clip;
    final transform = FakeMediaTransform(videoInfo: info);
    addTearDown(transform.dispose);

    final container = ProviderContainer(
      overrides: [
        assetPickerConfigProvider
            .overrideWithValue(const AssetPickerConfig(maxVideoBytes: 1024)),
        assetSourceProvider.overrideWithValue(source),
        mediaTransformProvider.overrideWithValue(transform),
      ],
    );
    addTearDown(container.dispose);

    await expectLater(
      _load(container, 'clip-1'),
      throwsA(isA<VideoRejectedException>()),
    );
    expect(transform.probedPaths, isEmpty);
  });

  test('accepts a clip exactly at both ceilings', () async {
    final container = containerWith(
      config: const AssetPickerConfig(
        maxVideoDuration: Duration(seconds: 30),
        maxVideoBytes: 4096,
      ),
      info: info,
    );

    final preview = await _load(container, 'clip-1');

    expect(preview.sizeBytes, 4096);
  });

  test('surfaces an unavailable asset as its own exception', () async {
    final container = containerWith(
      config: const AssetPickerConfig(),
      info: info,
      missing: true,
    );

    await expectLater(
      _load(container, 'clip-1'),
      throwsA(isA<VideoUnavailableException>()),
    );
  });

  group('VideoRejection.message', () {
    const text = AssetPickerTextEn();

    test('too-long reads from videoTooLong', () {
      expect(
        const VideoRejection.tooLong(Duration(seconds: 60)).message(text),
        text.videoTooLong(const Duration(seconds: 60)),
      );
    });

    test('too-large reads from fileTooLarge', () {
      expect(
        const VideoRejection.tooLarge(150 * 1024 * 1024).message(text),
        text.fileTooLarge(150 * 1024 * 1024),
      );
    });
  });
}

/// Reads the preview source while holding a listener on it: the provider is
/// auto-dispose, and Riverpod 3 tears an unlistened provider down mid-load.
Future<VideoPreviewSource> _load(ProviderContainer container, String id) {
  final sub = container.listen(videoPreviewSourceProvider(id), (_, __) {});
  addTearDown(sub.close);
  return container.read(videoPreviewSourceProvider(id).future);
}
