/// Fixed strings the video export path emits.
abstract final class VideoExportConstants {
  /// Both `VideoCodec.h264` and `VideoCodec.hevc` are exported in an MP4
  /// container by the plugin, so the type is the same for either codec.
  static const String mp4MimeType = 'video/mp4';

  static const String coverMimeType = 'image/jpeg';

  static const String coverSuffix = '_cover.jpg';
}
