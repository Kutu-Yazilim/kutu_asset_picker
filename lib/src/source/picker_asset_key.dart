import 'package:flutter/foundation.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

/// The cache key for one thumbnail request.
///
/// Its value equality **is** the dedup mechanism (design §4.4): the framework's
/// `ImageCache` is keyed on this object, so two cells asking for the same asset
/// at the same size and quality share one decode and one platform call.
///
/// Width and height are compared directly rather than through `ThumbSize`
/// equality — this key's contract must not depend on another package's
/// unstated one.
@immutable
final class PickerAssetKey {
  /// Creates a [PickerAssetKey].
  const PickerAssetKey({
    required this.assetId,
    required this.size,
    required this.quality,
  });

  /// The asset id.
  final String assetId;

  /// The size.
  final ThumbSize size;

  /// The quality.
  final int quality;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PickerAssetKey &&
          other.assetId == assetId &&
          other.size.width == size.width &&
          other.size.height == size.height &&
          other.quality == quality;

  @override
  int get hashCode => Object.hash(assetId, size.width, size.height, quality);

  @override
  String toString() =>
      'PickerAssetKey($assetId, ${size.width}x${size.height}, q$quality)';
}
