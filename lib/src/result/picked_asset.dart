import 'dart:io';

import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:flutter/foundation.dart';

/// One asset the author finished with.
///
/// Sealed so a consumer's `switch` is exhaustive: adding a media type later is
/// then a compile error at every call site rather than a silent fall-through.
///
/// [file] is the **exported** file — cropped, trimmed, re-encoded. The package
/// writes these into a namespaced temporary directory and **the consumer owns
/// them**: nothing in this package deletes them, and on iOS nothing in the OS
/// collects them either.
@immutable
sealed class PickedAsset {
  const PickedAsset({
    required this.id,
    required this.file,
    required this.mimeType,
    required this.sizeBytes,
    required this.width,
    required this.height,
    required this.aspectRatio,
    this.originalFile,
  });

  /// The source asset's id, so a consumer can correlate back to the gallery.
  final String id;

  /// The exported file.
  final File file;

  final String mimeType;
  final int sizeBytes;
  final int width;
  final int height;

  /// The ratio the author chose, not whatever the source happened to be.
  final double aspectRatio;

  /// Null unless `config.keepOriginals`.
  final File? originalFile;
}

@immutable
final class PickedImage extends PickedAsset {
  const PickedImage({
    required super.id,
    required super.file,
    required super.mimeType,
    required super.sizeBytes,
    required super.width,
    required super.height,
    required super.aspectRatio,
    super.originalFile,
  });
}

@immutable
final class PickedVideo extends PickedAsset {
  const PickedVideo({
    required super.id,
    required super.file,
    required super.mimeType,
    required super.sizeBytes,
    required super.width,
    required super.height,
    required super.aspectRatio,
    required this.duration,
    required this.trimmed,
    required this.coverFrame,
    super.originalFile,
  });

  /// After trim.
  final Duration duration;

  /// The kept range, relative to the source.
  final DurationRange trimmed;

  /// The poster, exported as JPEG. **Always present**, even when
  /// `enableCoverFrame` is false — in that case it is the first frame of the
  /// trimmed range, cropped to the same rect. A consumer always has a poster to
  /// render and never has to branch on whether the author happened to pick one
  /// (spec §3.4).
  final File coverFrame;
}
