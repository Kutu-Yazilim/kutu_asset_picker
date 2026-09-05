import 'dart:io';

import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../providers/injection_providers.dart';
import 'video_rejection.dart';

part 'video_preview_source.g.dart';

/// Everything the crop step needs about one video before it can show anything.
typedef VideoPreviewSource = ({File file, VideoInfo info, int sizeBytes});

/// Materialises one video and applies both selection-time ceilings.
///
/// Order matters: the byte ceiling is checked before the probe, because a probe
/// on a file we are about to refuse is a wasted platform round trip on the one
/// path most likely to involve a huge file.
/// A rejection or an unavailable asset is a verdict, not a transient fault:
/// Riverpod 3's default retry would re-run the probe on a backoff and hold the
/// crop step in a loading state for the whole schedule.
Duration? _noRetry(int retryCount, Object error) => null;

@Riverpod(retry: _noRetry)
Future<VideoPreviewSource> videoPreviewSource(Ref ref, String assetId) async {
  final config = ref.watch(assetPickerConfigProvider);
  final file = await ref.watch(assetSourceProvider).file(assetId);
  if (file == null) throw VideoUnavailableException(assetId);

  final sizeBytes = await file.length();
  final maxBytes = config.maxVideoBytes;
  if (maxBytes != null && sizeBytes > maxBytes) {
    throw VideoRejectedException(VideoRejection.tooLarge(maxBytes));
  }

  final info = await ref.watch(mediaTransformProvider).probeVideo(file.path);
  final maxDuration = config.maxVideoDuration;
  if (maxDuration != null && info.duration > maxDuration) {
    throw VideoRejectedException(VideoRejection.tooLong(maxDuration));
  }

  return (file: file, info: info, sizeBytes: sizeBytes);
}
