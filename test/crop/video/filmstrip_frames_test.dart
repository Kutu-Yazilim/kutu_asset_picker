import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/crop/video/filmstrip_frames.dart';
import 'package:kutu_asset_picker/src/crop/video/video_crop_constants.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:kutu_media_transform/testing.dart';

void main() {
  const info = VideoInfo(
    duration: Duration(seconds: 12),
    codedWidth: 1920,
    codedHeight: 1080,
    rotationDegrees: 0,
    isHdr: false,
    hasAudio: true,
  );

  late FakeMediaTransform transform;

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [mediaTransformProvider.overrideWithValue(transform)],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() => transform = FakeMediaTransform(videoInfo: info));

  test('asks the transform for one frame per configured slot', () async {
    final container = makeContainer();
    final request = filmstripRequestFor(
      '/tmp/clip.mp4',
      const DurationRange(start: Duration.zero, end: Duration(seconds: 12)),
    );

    final frames =
        await container.read(filmstripFramesProvider(request).future);

    expect(frames, hasLength(VideoCropConstants.filmstripFrameCount));
    expect(transform.frameExtractions, hasLength(1));
    expect(
      transform.frameExtractions.single.times,
      hasLength(VideoCropConstants.filmstripFrameCount),
    );
  });

  test('requests them at the low filmstrip resolution', () async {
    final container = makeContainer();
    final request = filmstripRequestFor(
      '/tmp/clip.mp4',
      const DurationRange(start: Duration.zero, end: Duration(seconds: 12)),
    );

    await container.read(filmstripFramesProvider(request).future);

    expect(
      transform.frameExtractions.single.size.width,
      VideoCropConstants.filmstripFrameEdge,
    );
    expect(
      transform.frameExtractions.single.size.height,
      VideoCropConstants.filmstripFrameEdge,
    );
  });

  test('caches: the same request never extracts twice', () async {
    final container = makeContainer();
    final request = filmstripRequestFor(
      '/tmp/clip.mp4',
      const DurationRange(start: Duration.zero, end: Duration(seconds: 12)),
    );

    await container.read(filmstripFramesProvider(request).future);
    await container.read(filmstripFramesProvider(request).future);
    await container.read(filmstripFramesProvider(request).future);

    expect(transform.frameExtractions, hasLength(1));
  });

  test('a different clip is a different cache entry', () async {
    final container = makeContainer();
    const range =
        DurationRange(start: Duration.zero, end: Duration(seconds: 12));

    await container.read(
        filmstripFramesProvider(filmstripRequestFor('/tmp/a.mp4', range))
            .future);
    await container.read(
        filmstripFramesProvider(filmstripRequestFor('/tmp/b.mp4', range))
            .future);

    expect(transform.frameExtractions, hasLength(2));
  });

  test('the request record is value-equal, which is what makes the cache work',
      () {
    const range =
        DurationRange(start: Duration.zero, end: Duration(seconds: 12));

    expect(
      filmstripRequestFor('/tmp/clip.mp4', range),
      filmstripRequestFor('/tmp/clip.mp4', range),
    );
  });
}
