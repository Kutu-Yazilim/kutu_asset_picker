import 'package:flutter/foundation.dart';

import 'picker_media_type.dart';

/// One asset in the device library, as the picker sees it.
///
/// `photo_manager`'s `AssetEntity` never escapes the source layer; this is the
/// value type every other layer works with (design §4.1).
@immutable
final class PickerAsset {
  const PickerAsset({
    required this.id,
    required this.type,
    required this.width,
    required this.height,
    required this.createdAt,
    this.duration,
    this.isLivePhoto = false,
  });

  /// Platform asset identifier: the `MediaStore` `_id` on Android, the
  /// `PHAsset.localIdentifier` on iOS/macOS.
  final String id;

  final PickerMediaType type;

  /// Reported pixel dimensions.
  ///
  /// These are `AssetEntity.width`/`height`, deliberately NOT
  /// `orientatedWidth`/`orientatedHeight`: `AssetEntity.orientation` is
  /// Android-only and always 0 on iOS/macOS (design §7.2), so using it would
  /// make the same photo report different dimensions per platform.
  final int width;
  final int height;

  final DateTime createdAt;

  /// Null for images, and also null for a video whose duration metadata is
  /// absent — a real set of files on Android from some downloads and
  /// third-party recorders (design §4.5). The UI handles null; it never
  /// vanishes the video.
  final Duration? duration;

  final bool isLivePhoto;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PickerAsset &&
          other.id == id &&
          other.type == type &&
          other.width == width &&
          other.height == height &&
          other.createdAt == createdAt &&
          other.duration == duration &&
          other.isLivePhoto == isLivePhoto;

  @override
  int get hashCode => Object.hash(
        id,
        type,
        width,
        height,
        createdAt,
        duration,
        isLivePhoto,
      );

  @override
  String toString() => 'PickerAsset(id: $id, type: $type, ${width}x$height)';
}
