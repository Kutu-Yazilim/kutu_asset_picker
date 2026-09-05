import 'dart:io';

import 'package:kutu_asset_picker/src/result/picked_asset.dart';

/// The directories this process has written exports into.
///
/// The package writes exports into a namespaced temp directory and the result
/// doc states plainly that **the consumer owns those files**;
/// `KutuAssetPicker.clearCache()` exists because iOS caches asset files into
/// the app container and nothing ever collects them (spec §3.4).
///
/// The directory is chosen natively — `cacheDir/kutu_media_transform` on
/// Android, the same leaf under the caches directory on iOS — and this pure-Dart
/// package cannot name it without taking a `path_provider` dependency. It does
/// not have to: every exported file is inside it, so `file.parent` is the
/// answer, recorded as each batch finishes.
abstract final class ExportCache {
  const ExportCache._();

  static final Set<String> _directories = <String>{};

  /// The recorded directories. Exposed for tests and for a consumer who wants
  /// to inspect rather than delete.
  static Set<String> get directories => Set<String>.unmodifiable(_directories);

  /// Records where [assets] and their originals and cover frames landed.
  static void rememberAll(List<PickedAsset> assets) {
    for (final PickedAsset asset in assets) {
      _directories.add(asset.file.parent.path);
      final File? original = asset.originalFile;
      if (original != null) _directories.add(original.parent.path);
      if (asset is PickedVideo) {
        _directories.add(asset.coverFrame.parent.path);
      }
    }
  }

  /// Deletes every recorded directory and forgets it.
  ///
  /// Best-effort per directory: the consumer owns these files and may have
  /// moved or deleted them already, and a collector that threw because its work
  /// was already done would be worse than useless.
  static Future<void> clear() async {
    for (final String path in _directories.toList()) {
      final Directory directory = Directory(path);
      try {
        if (directory.existsSync()) {
          await directory.delete(recursive: true);
        }
      } on FileSystemException {
        // Already gone, or not ours to delete. Nothing to do and nothing to
        // report — the next batch recreates it natively.
      }
    }
    _directories.clear();
  }

  /// Forgets everything without touching the filesystem. Tests only.
  static void reset() => _directories.clear();
}
