import 'dart:io';

import 'package:kutu_asset_picker/src/config/asset_picker_config.dart';
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
import '../crop/video/video_display_size.dart';
import 'video_export_step.dart';
import 'package:flutter/material.dart';

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

    /// Fine-grained progress inside one asset, by index into [assets]. A video
    /// export is seconds to minutes, so the coarse done/total above is not
    /// enough on its own; a photo export never reports through this.
    void Function(int index, double fraction)? onAssetFraction,
  }) async {
    _failures.clear();
    final picked = <PickedAsset>[];
    final total = assets.length;
    var done = 0;
    onProgress?.call(done, total);

    for (var index = 0; index < assets.length; index++) {
      final asset = assets[index];
      if (cancelToken?.isCancelled ?? false) break;
      try {
        picked.add(
          await _exportOne(
            asset,
            stateOf(asset.id),
            config,
            cancelToken,
            (fraction) => onAssetFraction?.call(index, fraction),
          ),
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
    void Function(double fraction) onFraction,
  ) async {
    // `AssetSource.file` is the transcoded path, never `originFile` — Flutter
    // cannot render HEIC and `originFile` on HEIC fails outright on Android 10.
    final src = await source.file(asset.id, cancelToken: cancelToken);
    if (src == null) {
      throw TransformException(
        TransformFailure.sourceUnreadable,
        'the gallery returned no file for ${asset.id}',
      );
    }

    if (asset.type == PickerMediaType.video) {
      return _exportVideo(asset, src, state, config, onFraction, cancelToken);
    }

    final imageSize = pickerAssetSize(asset);
    final window = cropWindowSize(state.aspect, kCanonicalCropArea);
    // Normalizing here means an asset the author never opened still exports at
    // its opening framing rather than at a scale of 0.
    final normalized = reclampForAspect(state, imageSize, window, state.aspect);
    final crop = config.enableCrop
        ? toCropRect(normalized, imageSize, window)
        : const CropRect.full();

    return _exportImage(asset, src, crop, normalized, config);
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

  /// The video arm.
  ///
  /// Everything here that looks like duplication of the image arm is not: the
  /// crop is computed against `videoDisplaySize(info)`, the POST-rotation size
  /// the author actually framed, while `pickerAssetSize(asset)` would hand back
  /// the gallery's dimensions and crop a portrait clip sideways (spec §7.4
  /// invariant 1). `VideoExportStep` owns the trim, the poster and the single
  /// §4.5 retry.
  Future<PickedVideo> _exportVideo(
    PickerAsset asset,
    File src,
    CropState state,
    AssetPickerConfig config,
    void Function(double fraction) onFraction,
    TransformCancelToken? cancelToken,
  ) async {
    final info = await transform.probeVideo(src.path);
    final displaySize = videoDisplaySize(info);
    final window = cropWindowSize(state.aspect, kCanonicalCropArea);
    final normalized =
        reclampForAspect(state, displaySize, window, state.aspect);

    return VideoExportStep(transform: transform).export(
      asset: asset,
      source: src,
      info: info,
      state: config.enableCrop
          ? normalized
          : normalized.copyWith(
              scale: scaleToCover(displaySize, window),
              offset: Offset.zero,
            ),
      window: window,
      config: config,
      onProgress: onFraction,
      cancelToken: cancelToken,
    );
  }
}
