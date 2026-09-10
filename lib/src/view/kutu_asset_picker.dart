import 'package:flutter/material.dart';
import 'package:kutu_asset_picker/src/camera/picker_camera_delegate.dart';
import 'package:kutu_asset_picker/src/config/asset_picker_config.dart';
import 'package:kutu_asset_picker/src/config/picker_enums.dart';
import 'package:kutu_asset_picker/src/export/export_cache.dart';
import 'package:kutu_asset_picker/src/result/asset_picker_result.dart';
import 'package:kutu_asset_picker/src/source/asset_source.dart';
import 'package:kutu_asset_picker/src/source/photo_manager_asset_source.dart';
import 'package:kutu_asset_picker/src/text/asset_picker_text.dart';
import 'package:kutu_asset_picker/src/theme/asset_picker_theme.dart';
import 'package:kutu_asset_picker/src/view/asset_picker_scope.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

/// The convenience entry point.
///
/// A thin wrapper over `AssetPickerScope` + `AssetPickerView`, in that
/// direction on purpose (spec §3.3): the embeddable widget is the real thing,
/// and a consumer who needs a go_router sub-route or their own Riverpod scope
/// mounts it directly and never touches this class.
abstract final class KutuAssetPicker {
  const KutuAssetPicker._();

  /// Pushes the configured surface and resolves with the author's selection, or
  /// null if they backed out.
  ///
  /// [camera] adds the camera cell to the grid. Null, the default, means no
  /// camera: this package ships no capture plugin on purpose (design §2.8).
  static Future<AssetPickerResult?> show(
    BuildContext context, {
    required AssetPickerConfig config,
    AssetSource? source,
    MediaTransform? transform,
    PickerCameraDelegate? camera,
    AssetPickerTheme? theme,
    AssetPickerText? text,
  }) {
    final gallery = source ?? PhotoManagerAssetSource();

    if (config.pickerSurface == PickerSurface.page) {
      return Navigator.of(context).push<AssetPickerResult>(
        MaterialPageRoute<AssetPickerResult>(
          builder: (routeContext) => AssetPickerScope(
            config: config,
            source: gallery,
            transform: transform,
            camera: camera,
            theme: theme,
            text: text,
            onCompleted: (result) => Navigator.of(routeContext).pop(result),
            onCancelled: () => Navigator.of(routeContext).pop(),
          ),
        ),
      );
    }

    final resolved = AssetPickerTheme.resolve(context, theme);
    return showModalBottomSheet<AssetPickerResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: resolved.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(resolved.sheetRadius),
        ),
      ),
      builder: (sheetContext) => AssetPickerScope(
        config: config,
        source: gallery,
        transform: transform,
        camera: camera,
        theme: theme,
        text: text,
        onCompleted: (result) => Navigator.of(sheetContext).pop(result),
        onCancelled: () => Navigator.of(sheetContext).pop(),
      ),
    );
  }

  /// Deletes the export files this process produced.
  ///
  /// The package writes exports into a namespaced temp directory and **the
  /// consumer owns those files** — but iOS caches asset files into the app
  /// container and nothing else ever collects them (spec §3.4), so a composer
  /// opened twenty times leaves twenty batches behind.
  ///
  /// Call it once a batch has been consumed: uploaded, copied somewhere durable,
  /// or abandoned. It deletes the directory the plugin exported into, so do not
  /// call it while an export is still running, and do not call it while a
  /// `PickedAsset.file` you still intend to read is unread.
  static Future<void> clearCache() => ExportCache.clear();
}
