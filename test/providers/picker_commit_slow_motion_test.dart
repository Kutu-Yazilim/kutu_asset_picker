import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/picker/slow_motion_flatten.dart';
import 'package:kutu_asset_picker/testing.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:kutu_media_transform/testing.dart';

void main() {
  late Directory tempDir;
  late FakeAssetSource source;

  PickerAsset slowMo(String id) => PickerAsset(
        id: id,
        type: PickerMediaType.video,
        width: 1080,
        height: 1920,
        createdAt: DateTime(2026, 8, 4),
        duration: const Duration(seconds: 12),
      );

  /// A file that plays for a quarter of what the gallery reports — the
  /// un-flattened slow-motion signature.
  FakeMediaTransform fakeSlowMotion() {
    final fake = FakeMediaTransform(
      videoInfo: const VideoInfo(
        duration: Duration(seconds: 3),
        codedWidth: 1920,
        codedHeight: 1080,
        rotationDegrees: 0,
        isHdr: false,
        hasAudio: true,
      ),
    );
    addTearDown(fake.dispose);
    return fake;
  }

  ProviderContainer containerWith(FakeMediaTransform transform) {
    final container = ProviderContainer(
      overrides: [
        assetPickerConfigProvider.overrideWithValue(const AssetPickerConfig()),
        assetSourceProvider.overrideWithValue(source),
        mediaTransformProvider.overrideWithValue(transform),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('kutu_commit_slow_motion');
    source = FakeAssetSource();
    source.filesById['slow'] = File('${tempDir.path}/slow.mov')
      ..writeAsBytesSync([1, 2, 3]);
  });

  tearDown(() async {
    await source.dispose();
    tempDir.deleteSync(recursive: true);
  });

  test('the pass runs before the hand-over, not behind it', () async {
    final transform = fakeSlowMotion();
    final container = containerWith(transform);
    container.read(selectionProvider.notifier).toggleAsset(slowMo('slow'));

    var ready = false;
    await container
        .read(pickerCommitProvider.notifier)
        .commit(onReady: () => ready = true);

    expect(transform.videoExports, hasLength(1));
    expect(ready, isTrue);
    expect(
      container.read(slowMotionFlattenProvider).files.containsKey('slow'),
      isTrue,
    );
  });

  test('a failed flatten withholds the hand-over', () async {
    final transform = fakeSlowMotion();
    transform.onExportVideo = (report) async => throw const TransformException(
          TransformFailure.encoderFailed,
          'the flatten export failed',
        );
    final container = containerWith(transform);
    container.read(selectionProvider.notifier).toggleAsset(slowMo('slow'));

    var ready = false;
    await container
        .read(pickerCommitProvider.notifier)
        .commit(onReady: () => ready = true);

    expect(ready, isFalse);
  });

  test('Cancel stops the transcode as well as the downloads', () async {
    final transform = fakeSlowMotion();
    final container = containerWith(transform);
    transform.onExportVideo = (report) async =>
        container.read(pickerCommitProvider.notifier).cancel();
    container.read(selectionProvider.notifier).toggleAsset(slowMo('slow'));

    var ready = false;
    await container
        .read(pickerCommitProvider.notifier)
        .commit(onReady: () => ready = true);

    expect(ready, isFalse);
    expect(container.read(slowMotionFlattenProvider).running, isFalse);
    expect(container.read(pickerCommitProvider).running, isFalse);
  });

  test('committing twice transcodes once', () async {
    final transform = fakeSlowMotion();
    final container = containerWith(transform);
    container.read(selectionProvider.notifier).toggleAsset(slowMo('slow'));

    var ready = 0;
    final notifier = container.read(pickerCommitProvider.notifier);
    await notifier.commit(onReady: () => ready += 1);
    await notifier.commit(onReady: () => ready += 1);

    expect(ready, 2);
    expect(transform.videoExports, hasLength(1));
  });
}
