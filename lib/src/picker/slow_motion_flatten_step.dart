import 'dart:io';

import 'package:kutu_media_transform/kutu_media_transform.dart';

import '../source/picker_asset.dart';
import '../source/picker_media_type.dart';

/// One selected asset → the file whose timeline matches the one the gallery
/// showed, or null when nothing had to be rewritten.
///
/// spec §7.3: an iOS slow-motion `PHAsset` is an `AVComposition` carrying a
/// `CMTimeMapping` over a 120/240 fps original, so the file the picker is
/// handed can play for a quarter of the duration Photos displays. Every number
/// downstream — the trim range, the filmstrip instants, the cover frame, the
/// exported clip — is then wrong, which is why this runs at selection time,
/// behind visible progress, rather than silently at export.
///
/// The comparison itself is `SlowMotionFlattener`'s: it probes the file and
/// rewrites only when the skew exceeds
/// `SlowMotionFlattener.durationTolerance`.
final class SlowMotionFlattenStep {
  const SlowMotionFlattenStep({required this.transform});

  final MediaTransform transform;

  /// The flattened file, or null when [asset] needed no rewrite.
  ///
  /// Null rather than the source file so the caller stores only the ids it
  /// actually rewrote — an entry per untouched asset would make
  /// `FlattenedAssetSource` a redundant copy of the gallery.
  ///
  /// Failures — including cancellation — are thrown, never swallowed: the
  /// caller is the pass that owns the progress bar, and it is the only thing
  /// that can decide whether to withhold the hand-over.
  Future<File?> flatten({
    required PickerAsset asset,
    required File source,
    required VideoEncodeSettings settings,
    void Function(double progress)? onProgress,
    TransformCancelToken? cancelToken,
  }) async {
    final expected = asset.duration;
    // An image has no timeline. A video with a null duration has no gallery
    // duration to compare against (contract §3), and transcoding on a guess
    // would re-encode every such clip for nothing.
    if (asset.type != PickerMediaType.video || expected == null) {
      return null;
    }

    final flattened = await SlowMotionFlattener(transform).ensureFlattened(
      source.path,
      expected,
      settings,
      onProgress: onProgress,
      cancelToken: cancelToken,
    );
    return flattened.path == source.path ? null : flattened;
  }
}
