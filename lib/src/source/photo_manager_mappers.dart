import 'package:photo_manager/photo_manager.dart';

import 'picker_album.dart';
import 'picker_asset.dart';
import 'picker_media_type.dart';

/// Converts one `photo_manager` entity into the picker's value type.
///
/// Returns null for audio and `AssetType.other`: the picker never surfaces
/// them (design §14), and dropping them here means no layer above has to know
/// they exist.
PickerAsset? pickerAssetFrom(AssetEntity entity) {
  final PickerMediaType? type = switch (entity.type) {
    AssetType.image => PickerMediaType.image,
    AssetType.video => PickerMediaType.video,
    AssetType.audio || AssetType.other => null,
  };
  if (type == null) {
    return null;
  }

  return PickerAsset(
    id: entity.id,
    type: type,
    // Raw dimensions, NOT orientatedWidth/orientatedHeight: `orientation` is
    // Android-only and always 0 on iOS/macOS (design §7.2), so using it would
    // make the same photo report different dimensions per platform.
    width: entity.width,
    height: entity.height,
    createdAt: entity.createDateTime,
    duration: _durationOf(entity, type),
    isLivePhoto: entity.isLivePhoto,
  );
}

/// `AssetEntity.duration` is a non-nullable int in seconds and is 0 when the
/// platform reports nothing. A 0 would render as a "0:00" chip on a video that
/// is minutes long, so absent metadata becomes null and the UI omits the chip
/// (design §4.5).
Duration? _durationOf(AssetEntity entity, PickerMediaType type) {
  if (type != PickerMediaType.video || entity.duration <= 0) {
    return null;
  }
  return Duration(seconds: entity.duration);
}

/// Converts one album. The count is passed in because `assetCountAsync` is a
/// platform round-trip the caller batches.
PickerAlbum pickerAlbumFrom(AssetPathEntity path, int assetCount) =>
    PickerAlbum(
      id: path.id,
      name: path.name,
      assetCount: assetCount,
      isAll: path.isAll,
    );
