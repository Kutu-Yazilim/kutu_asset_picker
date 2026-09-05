/// JPEG quality, pinned explicitly on every call.
///
/// `photo_manager`'s `ThumbnailOption` defaults to 95 and the
/// `thumbnailDataWithSize` overload defaults to 100 — inheriting is a coin
/// flip, and the difference is a doubled cache footprint for no visible gain
/// (spec §4.4).
abstract final class AssetPickerQuality {
  const AssetPickerQuality._();

  /// The thumbnail.
  static const int thumbnail = 85;

  /// The preview.
  static const int preview = 90;
}
