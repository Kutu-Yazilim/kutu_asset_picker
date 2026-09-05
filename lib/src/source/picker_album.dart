import 'package:flutter/foundation.dart';

/// One album (a `MediaStore` bucket on Android, a `PHAssetCollection` on
/// iOS/macOS).
@immutable
final class PickerAlbum {
  const PickerAlbum({
    required this.id,
    required this.name,
    required this.assetCount,
    required this.isAll,
  });

  final String id;
  final String name;
  final int assetCount;

  /// Whether this is the root "Recent"/"All" album.
  final bool isAll;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PickerAlbum &&
          other.id == id &&
          other.name == name &&
          other.assetCount == assetCount &&
          other.isAll == isAll;

  @override
  int get hashCode => Object.hash(id, name, assetCount, isAll);

  @override
  String toString() => 'PickerAlbum(id: $id, name: $name, count: $assetCount)';
}
