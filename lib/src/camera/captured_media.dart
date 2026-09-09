import 'dart:io';

import 'package:flutter/foundation.dart';

import '../source/picker_media_type.dart';

/// One capture, as the OS camera left it and before it is in the library.
///
/// A `PickerAsset` cannot express this: its `id` is a platform asset
/// identifier and both thumbnails and export resolve through it, so a plain
/// temp file has no way to be one. Turning this into a library asset is
/// `AssetSource.saveToLibrary`'s job.
@immutable
final class CapturedMedia {
  /// Creates a [CapturedMedia].
  const CapturedMedia({required this.file, required this.kind});

  /// The file the camera wrote. Usually a temp file the host's plugin owns.
  final File file;

  /// What was captured. The save call differs per kind.
  final PickerMediaType kind;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CapturedMedia &&
          other.file.path == file.path &&
          other.kind == kind;

  /// Hashes the path rather than the [File], which has identity equality.
  @override
  int get hashCode => Object.hash(file.path, kind);

  @override
  String toString() => 'CapturedMedia(${file.path}, $kind)';
}
