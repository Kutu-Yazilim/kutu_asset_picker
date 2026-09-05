import 'dart:io';

import 'package:kutu_asset_picker/src/config/asset_picker_config.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_sizes.dart';
import 'package:kutu_asset_picker/src/crop/crop_math.dart';
import 'package:kutu_asset_picker/src/crop/crop_state.dart';
import 'package:kutu_asset_picker/src/crop/picker_asset_size.dart';
import 'package:kutu_asset_picker/src/export/export_failure.dart';
import 'package:kutu_asset_picker/src/export/exported_pixel_size.dart';
import 'package:kutu_asset_picker/src/result/picked_asset.dart';
import 'package:kutu_asset_picker/src/source/asset_source.dart';
import 'package:kutu_asset_picker/src/source/picker_asset.dart';
import 'package:kutu_asset_picker/src/source/picker_media_type.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

/// Runs the export batch.
///
/// **Strictly one asset at a time.** Ten 12 MP photos decoded in parallel is
/// roughly 480 MB, and a 256 MB Dalvik heap on a low-end Android device simply
/// dies. This is not a tuning knob (spec §7.5) — there is no `Future.wait` in
/// this file and there must never be one.
///
/// A per-asset failure is recorded in [failures] and the batch continues. One
/// iCloud video that will not download must not cost the author the nine photos
/// that exported fine.
final class ExportQueue {
  ExportQueue({required this.transform, required this.source});

  final MediaTransform transform;
  final AssetSource source;

  final List<ExportFailure> _failures = <ExportFailure>[];

  /// Per-asset errors from the most recent [run].
  List<ExportFailure> get failures =>
      List<ExportFailure>.unmodifiable(_failures);

  Future<List<PickedAsset>> run(
    List<PickerAsset> assets,
    CropState Function(String id) stateOf,
    AssetPickerConfig config, {
    void Function(int done, int total)? onProgress,
    TransformCancelToken? cancelToken,
  }) async {
    _failures.clear();
    final picked = <PickedAsset>[];
    final total = assets.length;
    var done = 0;
    onProgress?.call(done, total);

    for (final asset in assets) {
      if (cancelToken?.isCancelled ?? false) break;
      try {
        picked.add(
          await _exportOne(asset, stateOf(asset.id), config, cancelToken),
        );
      } on TransformException catch (error) {
        _failures.add(
          ExportFailure(
            assetId: asset.id,
            failure: error.failure,
            message: error.message,
          ),
        );
      } on Object catch (error) {
        _failures.add(
          ExportFailure(
            assetId: asset.id,
            failure: TransformFailure.unknown,
            message: '$error',
          ),
        );
      }
      done += 1;
      onProgress?.call(done, total);
    }

    return picked;
  }

  Future<PickedAsset> _exportOne(
    PickerAsset asset,
    CropState state,
    AssetPickerConfig config,
    TransformCancelToken? cancelToken,
  ) async {
    // `AssetSource.file` is the transcoded path, never `originFile` — Flutter
    // cannot render HEIC and `originFile` on HEIC fails outright on Android 10.
    final src = await source.file(asset.id, cancelToken: cancelToken);
    if (src == null) {
      throw const TransformException(
        TransformFailure.sourceUnreadable,
        'the asset file is not available locally',
      );
    }

    final imageSize = pickerAssetSize(asset);
    final window = cropWindowSize(state.aspect, kCanonicalCropArea);
    // Normalizing here means an asset the author never opened still exports at
    // its opening framing rather than at a scale of 0.
    final normalized = reclampForAspect(state, imageSize, window, state.aspect);
    final crop = config.enableCrop
        ? toCropRect(normalized, imageSize, window)
        : const CropRect.full();

    return asset.type == PickerMediaType.image
        ? _exportImage(asset, src, crop, normalized, config)
        : _exportVideo(asset, src, crop, normalized, config, cancelToken);
  }

  Future<PickedImage> _exportImage(
    PickerAsset asset,
    File src,
    CropRect crop,
    CropState state,
    AssetPickerConfig config,
  ) async {
    final out = await transform.exportImage(src.path, crop, config.imageEncode);
    final size = exportedPixelSize(
      crop: crop,
      sourceWidth: asset.width,
      sourceHeight: asset.height,
      maxLongEdge: config.imageEncode.maxLongEdge,
    );
    return PickedImage(
      id: asset.id,
      file: out,
      mimeType: switch (config.imageEncode.format) {
        ImageOutputFormat.jpeg => 'image/jpeg',
        ImageOutputFormat.png => 'image/png',
      },
      sizeBytes: await out.length(),
      width: size.width,
      height: size.height,
      // With no crop the shape is whatever the source was; this path promises
      // no shape, so consumers fit rather than crop.
      aspectRatio:
          config.enableCrop ? state.aspect.ratio : asset.width / asset.height,
      originalFile: config.keepOriginals ? src : null,
    );
  }

  Future<PickedVideo> _exportVideo(
    PickerAsset asset,
    File src,
    CropRect crop,
    CropState state,
    AssetPickerConfig config,
    TransformCancelToken? cancelToken,
  ) async {
    final trim =
        state.trim ?? DurationRange.wholeOf(asset.duration ?? Duration.zero);
    final out = await transform.exportVideo(
      src.path,
      crop,
      trim,
      config.videoEncode,
      cancelToken: cancelToken,
    );

    // The cover frame is taken from the EXPORTED file, so it is already
    // cropped, trimmed and tone-mapped and cannot disagree with the video.
    // Offsets are relative to the exported clip, hence the subtraction.
    final coverAt = (state.coverAt ?? trim.start) - trim.start;
    final frames = await transform.extractFrames(
      out.path,
      [coverAt.isNegative ? Duration.zero : coverAt],
      AssetPickerSizes.coverFrame,
    );
    if (frames.isEmpty) {
      throw const TransformException(
        TransformFailure.unknown,
        'the cover frame could not be extracted',
      );
    }
    // Written beside the exported video rather than into a directory of our
    // own: the plugin already chose somewhere writable, and a poster that lives
    // next to its clip is collected by whatever collects the clip.
    final cover =
        await File('${out.path}.cover.jpg').writeAsBytes(frames.first);

    final size = exportedPixelSize(
      crop: crop,
      sourceWidth: asset.width,
      sourceHeight: asset.height,
      maxLongEdge: config.videoEncode.maxLongEdge,
    );
    return PickedVideo(
      id: asset.id,
      file: out,
      mimeType: 'video/mp4',
      sizeBytes: await out.length(),
      width: size.width,
      height: size.height,
      aspectRatio:
          config.enableCrop ? state.aspect.ratio : asset.width / asset.height,
      duration: trim.duration,
      trimmed: trim,
      coverFrame: cover,
      originalFile: config.keepOriginals ? src : null,
    );
  }
}
