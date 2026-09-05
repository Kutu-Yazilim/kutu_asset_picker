import 'dart:typed_data';

import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../providers/injection_providers.dart';
import 'filmstrip_times.dart';
import 'video_crop_constants.dart';

part 'filmstrip_frames.g.dart';

/// The cache key for one strip of frames.
///
/// A record of primitives on purpose: records are structurally equal for free,
/// and that equality *is* the caching mechanism — the same discipline
/// `PickerAssetKey` uses for thumbnails (spec §4.4).
typedef FilmstripRequest = ({
  String srcPath,
  int startMicros,
  int endMicros,
  int frameCount,
  int frameEdge,
});

/// Filmstrip request for.
FilmstripRequest filmstripRequestFor(String srcPath, DurationRange range) => (
      srcPath: srcPath,
      startMicros: range.start.inMicroseconds,
      endMicros: range.end.inMicroseconds,
      frameCount: VideoCropConstants.filmstripFrameCount,
      frameEdge: VideoCropConstants.filmstripFrameEdge,
    );

/// The frames behind the scrubber.
///
/// `photo_manager` thumbnails have no timestamp parameter — you get the
/// platform poster frame and nothing else — so this goes through our own
/// extractor (spec §6.3). Kept alive because on Android every frame is a
/// separate `MediaMetadataRetriever.getFrameAtTime` call and re-running the
/// strip on a rebuild would be visible; the whole cache dies with the picker's
/// `ProviderScope`, which is a short-lived scope by construction.
@Riverpod(keepAlive: true)
Future<List<Uint8List>> filmstripFrames(Ref ref, FilmstripRequest request) =>
    ref.watch(mediaTransformProvider).extractFrames(
          request.srcPath,
          filmstripTimes(
            DurationRange(
              start: Duration(microseconds: request.startMicros),
              end: Duration(microseconds: request.endMicros),
            ),
            request.frameCount,
          ),
          ThumbSize.square(request.frameEdge),
        );
