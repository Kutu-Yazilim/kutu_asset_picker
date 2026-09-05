import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:kutu_media_transform/kutu_media_transform.dart';

/// A `MediaTransform` that records call overlap.
///
/// Slice 1 ships a `FakeMediaTransform`, but the sequencing assertion needs
/// instrumentation — a high-water mark of concurrent calls — that a general
/// fake has no business carrying. Every export yields several times before it
/// finishes, so an overlapping caller has every chance to be observed; a single
/// `await` can be scheduled tightly enough to hide one.
class RecordingMediaTransform implements MediaTransform {
  RecordingMediaTransform({
    required this.outputFor,
    this.failFor = const {},
    this.yieldTicks = 3,
    this.frameBytes,
  });

  /// Source path → the file the export "produces". The test creates it.
  final File Function(String srcPath) outputFor;

  /// Source path → the failure that export should raise instead.
  final Map<String, TransformFailure> failFor;

  final int yieldTicks;
  final Uint8List? frameBytes;

  int _inFlight = 0;

  /// The highest number of exports ever in flight at the same time.
  int maxConcurrent = 0;

  /// Every crop rect handed to an export, in call order.
  final List<CropRect> crops = <CropRect>[];

  /// Every method name called, in order.
  final List<String> calls = <String>[];

  Future<T> _run<T>(String label, String srcPath, T Function() body) async {
    calls.add(label);
    _inFlight += 1;
    maxConcurrent = math.max(maxConcurrent, _inFlight);
    try {
      for (var tick = 0; tick < yieldTicks; tick += 1) {
        await Future<void>.delayed(Duration.zero);
      }
      final failure = failFor[srcPath];
      if (failure != null) {
        throw TransformException(failure, 'stubbed failure for $srcPath');
      }
      return body();
    } finally {
      _inFlight -= 1;
    }
  }

  @override
  Future<File> exportImage(
    String srcPath,
    CropRect crop,
    ImageEncodeSettings settings,
  ) {
    crops.add(crop);
    return _run('exportImage', srcPath, () => outputFor(srcPath));
  }

  @override
  Future<File> exportVideo(
    String srcPath,
    CropRect crop,
    DurationRange trim,
    VideoEncodeSettings settings, {
    void Function(double progress)? onProgress,
    TransformCancelToken? cancelToken,
  }) {
    crops.add(crop);
    return _run('exportVideo', srcPath, () => outputFor(srcPath));
  }

  @override
  Future<List<Uint8List>> extractFrames(
    String srcPath,
    List<Duration> times,
    ThumbSize size,
  ) =>
      _run(
        'extractFrames',
        srcPath,
        () => [
          for (var i = 0; i < times.length; i += 1)
            frameBytes ?? Uint8List.fromList(const [1, 2, 3]),
        ],
      );

  @override
  Future<VideoInfo> probeVideo(String srcPath) => _run(
        'probeVideo',
        srcPath,
        () => const VideoInfo(
          duration: Duration(seconds: 10),
          codedWidth: 1920,
          codedHeight: 1080,
          rotationDegrees: 0,
          isHdr: false,
          hasAudio: true,
        ),
      );
}
