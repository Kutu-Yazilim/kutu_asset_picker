import 'dart:io';
import 'dart:ui' show Size;

import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:path/path.dart' as p;

import '../config/asset_picker_config.dart';
import '../crop/crop_math.dart';
import '../crop/crop_state.dart';
import '../crop/video/trim_math.dart';
import '../crop/video/video_display_size.dart';
import '../result/picked_asset.dart';
import '../source/picker_asset.dart';
import 'video_export_constants.dart';

/// One video in, one [PickedVideo] out.
///
/// Separate from `ExportQueue` so the whole video export contract — the rect,
/// the range, the poster, both `enableCoverFrame` branches and the retry — is
/// testable against a fake transform without going through the queue.
final class VideoExportStep {
  /// Creates a [VideoExportStep].
  const VideoExportStep({required this.transform});

  /// The transform.
  final MediaTransform transform;

  /// Spec §4.5: `AVAssetExportSession` failing on a freshly-downloaded iCloud
  /// video is a recurring class of Apple-forum bug, and the second attempt
  /// usually succeeds. One retry, never a loop — a genuinely unsupported file
  /// would otherwise cost the author twice the wait before the same error.
  static const int attempts = 2;

  /// Export.
  Future<PickedVideo> export({
    required PickerAsset asset,
    required File source,
    required VideoInfo info,
    required CropState state,
    required Size window,
    required AssetPickerConfig config,
    void Function(double progress)? onProgress,
    TransformCancelToken? cancelToken,
  }) async {
    if (window.width <= 0 || window.height <= 0) {
      // Loud, because the alternative is a silently mis-framed export:
      // CropState.offset is in crop-window pixels, so a degenerate window here
      // would shift the crop by an arbitrary amount (spec §7.4 invariant 4).
      // The caller derives it from `cropWindowSize(state.aspect,
      // kCanonicalCropArea)`, which is never zero — reaching this is a bug.
      throw TransformException(
        TransformFailure.unknown,
        'degenerate crop window for ${asset.id}; cannot reproduce the framing',
      );
    }

    final trim = state.trim ?? DurationRange.wholeOf(info.duration);
    final exported = await _exportWithOneRetry(
      srcPath: source.path,
      crop: toCropRect(state, videoDisplaySize(info), window),
      trim: trim,
      settings: config.videoEncode,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );

    final exportedInfo = await transform.probeVideo(exported.path);
    final coverFrame = await _writeCover(
      exported: exported,
      exportedInfo: exportedInfo,
      trim: trim,
      state: state,
      config: config,
    );

    return PickedVideo(
      id: asset.id,
      file: exported,
      mimeType: VideoExportConstants.mp4MimeType,
      sizeBytes: await exported.length(),
      width: exportedInfo.displayWidth,
      height: exportedInfo.displayHeight,
      aspectRatio: state.aspect.ratio,
      originalFile: config.keepOriginals ? source : null,
      duration: trim.duration,
      trimmed: trim,
      coverFrame: coverFrame,
    );
  }

  /// [MediaTransform.exportVideo], attempted at most [attempts] times.
  ///
  /// A cancellation is rethrown immediately and never retried: the author
  /// pressed Cancel, and starting the multi-second export again is the one
  /// thing they just asked not to happen. Everything else gets exactly one
  /// second chance before the failure reaches the queue, which records it
  /// per-asset and keeps the rest of the batch running.
  Future<File> _exportWithOneRetry({
    required String srcPath,
    required CropRect crop,
    required DurationRange trim,
    required VideoEncodeSettings settings,
    void Function(double progress)? onProgress,
    TransformCancelToken? cancelToken,
  }) async {
    for (var attempt = 1;; attempt++) {
      try {
        return await transform.exportVideo(
          srcPath,
          crop,
          trim,
          settings,
          onProgress: onProgress,
          cancelToken: cancelToken,
        );
      } on TransformException catch (error) {
        if (attempt >= attempts ||
            error.failure == TransformFailure.cancelled) {
          rethrow;
        }
      }
    }
  }

  /// The poster, always.
  ///
  /// Extracted from the **exported** file rather than the source, so it is
  /// already cropped to the author's rect and already inside the trimmed range
  /// — no second rounding, no second rotation decision (spec §7.4).
  ///
  /// With `enableCoverFrame: false` this is the first frame of the trimmed
  /// range, which is why `PickedVideo.coverFrame` can be non-nullable and a
  /// consumer never has to branch on whether the author picked one (spec §3.4).
  Future<File> _writeCover({
    required File exported,
    required VideoInfo exportedInfo,
    required DurationRange trim,
    required CropState state,
    required AssetPickerConfig config,
  }) async {
    final coverAt = config.enableCoverFrame
        ? clampCoverAt(state.coverAt ?? trim.start, trim) - trim.start
        : Duration.zero;
    final frames = await transform.extractFrames(
      exported.path,
      [coverAt],
      ThumbSize(exportedInfo.displayWidth, exportedInfo.displayHeight),
    );
    final file = File(
      p.join(
        exported.parent.path,
        '${p.basenameWithoutExtension(exported.path)}'
        '${VideoExportConstants.coverSuffix}',
      ),
    );
    await file.writeAsBytes(frames.single, flush: true);
    return file;
  }
}
