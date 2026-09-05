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

  PickerAsset video(String id, Duration? galleryDuration) => PickerAsset(
        id: id,
        type: PickerMediaType.video,
        width: 1080,
        height: 1920,
        createdAt: DateTime(2026, 8, 4),
        duration: galleryDuration,
      );

  PickerAsset image(String id) => PickerAsset(
        id: id,
        type: PickerMediaType.image,
        width: 4032,
        height: 3024,
        createdAt: DateTime(2026, 8, 4),
      );

  VideoInfo fileInfo(Duration duration) => VideoInfo(
        duration: duration,
        codedWidth: 1920,
        codedHeight: 1080,
        rotationDegrees: 0,
        isHdr: false,
        hasAudio: true,
      );

  FakeMediaTransform fakeWith(Duration fileDuration) {
    final fake = FakeMediaTransform(videoInfo: fileInfo(fileDuration));
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

  File onDisk(String name) =>
      File('${tempDir.path}/$name')..writeAsBytesSync([1, 2, 3]);

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('kutu_flatten_pass');
    source = FakeAssetSource();
  });

  tearDown(() async {
    await source.dispose();
    tempDir.deleteSync(recursive: true);
  });

  test('a selection with nothing to flatten hands over immediately', () async {
    final transform = fakeWith(const Duration(seconds: 12));
    final container = containerWith(transform);
    source.filesById['a'] = onDisk('a.mov');
    container
        .read(selectionProvider.notifier)
        .toggleAsset(video('a', const Duration(seconds: 12)));

    expect(
        await container.read(slowMotionFlattenProvider.notifier).run(), isTrue);
    expect(transform.videoExports, isEmpty);
    expect(container.read(slowMotionFlattenProvider).files, isEmpty);
    expect(container.read(slowMotionFlattenProvider).running, isFalse);
  });

  test('a slow-motion clip is rewritten, and the flattened source serves it',
      () async {
    final transform = fakeWith(const Duration(seconds: 3));
    final container = containerWith(transform);
    source.filesById['slow'] = onDisk('slow.mov');
    container
        .read(selectionProvider.notifier)
        .toggleAsset(video('slow', const Duration(seconds: 12)));

    expect(
        await container.read(slowMotionFlattenProvider.notifier).run(), isTrue);

    final rewritten = container.read(slowMotionFlattenProvider).files['slow'];
    expect(transform.videoExports, hasLength(1));
    expect(rewritten, isNotNull);
    expect(
      (await container.read(flattenedAssetSourceProvider).file('slow'))!.path,
      rewritten!.path,
    );
  });

  test('images and unknown-duration videos are never probed', () async {
    final transform = fakeWith(const Duration(seconds: 3));
    final container = containerWith(transform);
    source.filesById['pic'] = onDisk('pic.jpg');
    source.filesById['odd'] = onDisk('odd.mp4');
    container.read(selectionProvider.notifier)
      ..toggleAsset(image('pic'))
      ..toggleAsset(video('odd', null));

    expect(
        await container.read(slowMotionFlattenProvider.notifier).run(), isTrue);
    expect(transform.probedPaths, isEmpty);
    expect(transform.videoExports, isEmpty);
  });

  test('progress spans the batch, so the bar moves across two clips', () async {
    final transform = fakeWith(const Duration(seconds: 3));
    final container = containerWith(transform);
    final seen = <double>[];
    transform.onExportVideo = (report) async {
      report(0.5);
      seen.add(container.read(slowMotionFlattenProvider).progress);
    };
    source.filesById['a'] = onDisk('a.mov');
    source.filesById['b'] = onDisk('b.mov');
    container.read(selectionProvider.notifier)
      ..toggleAsset(video('a', const Duration(seconds: 12)))
      ..toggleAsset(video('b', const Duration(seconds: 12)));

    await container.read(slowMotionFlattenProvider.notifier).run();

    // Half of the first of two, then half of the second.
    expect(seen, [0.25, 0.75]);
  });

  test('a cancel abandons the pass and refuses the hand-over', () async {
    final transform = fakeWith(const Duration(seconds: 3));
    final container = containerWith(transform);
    transform.onExportVideo = (report) async =>
        container.read(slowMotionFlattenProvider.notifier).cancel();
    source.filesById['a'] = onDisk('a.mov');
    container
        .read(selectionProvider.notifier)
        .toggleAsset(video('a', const Duration(seconds: 12)));

    expect(await container.read(slowMotionFlattenProvider.notifier).run(),
        isFalse);
    expect(container.read(slowMotionFlattenProvider).running, isFalse);
    expect(container.read(slowMotionFlattenProvider).files, isEmpty);
  });

  test('a clip that will not flatten withholds the hand-over', () async {
    // Handing this one over would export a 12-second clip as a 3-second one at
    // 4x speed, which is worse than refusing to continue.
    final transform = fakeWith(const Duration(seconds: 3));
    final container = containerWith(transform);
    transform.onExportVideo = (report) async => throw const TransformException(
          TransformFailure.encoderFailed,
          'the flatten export failed',
        );
    source.filesById['a'] = onDisk('a.mov');
    container
        .read(selectionProvider.notifier)
        .toggleAsset(video('a', const Duration(seconds: 12)));

    expect(await container.read(slowMotionFlattenProvider.notifier).run(),
        isFalse);
    expect(container.read(slowMotionFlattenProvider).running, isFalse);
  });

  test('a second pass does not transcode what the first one rewrote', () async {
    final transform = fakeWith(const Duration(seconds: 3));
    final container = containerWith(transform);
    source.filesById['slow'] = onDisk('slow.mov');
    container
        .read(selectionProvider.notifier)
        .toggleAsset(video('slow', const Duration(seconds: 12)));

    expect(
        await container.read(slowMotionFlattenProvider.notifier).run(), isTrue);
    expect(
        await container.read(slowMotionFlattenProvider.notifier).run(), isTrue);

    expect(transform.videoExports, hasLength(1));
  });

  test('an asset the gallery cannot hand over stops the pass', () async {
    final transform = fakeWith(const Duration(seconds: 3));
    final container = containerWith(transform);
    source.missingFiles.add('a');
    container
        .read(selectionProvider.notifier)
        .toggleAsset(video('a', const Duration(seconds: 12)));

    expect(await container.read(slowMotionFlattenProvider.notifier).run(),
        isFalse);
    expect(transform.videoExports, isEmpty);
  });
}
