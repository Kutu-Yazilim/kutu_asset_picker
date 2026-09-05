import '../../text/asset_picker_text.dart';

/// Why a video cannot be taken.
///
/// Rejection happens at selection and at crop-step entry, never at upload
/// (spec §10). The copy lives on the text delegate, so [message] is the only
/// place a rejection meets a string — a widget never branches on the subtype.
sealed class VideoRejection {
  const VideoRejection();

  const factory VideoRejection.tooLong(Duration max) = VideoTooLong;

  const factory VideoRejection.tooLarge(int maxBytes) = VideoTooLarge;

  /// Message.
  String message(AssetPickerText text);
}

/// Video too long.
final class VideoTooLong extends VideoRejection {
  /// Creates a [VideoTooLong].
  const VideoTooLong(this.max);

  /// The max.
  final Duration max;

  @override
  String message(AssetPickerText text) => text.videoTooLong(max);
}

/// Video too large.
final class VideoTooLarge extends VideoRejection {
  /// Creates a [VideoTooLarge].
  const VideoTooLarge(this.maxBytes);

  /// The max bytes.
  final int maxBytes;

  @override
  String message(AssetPickerText text) => text.fileTooLarge(maxBytes);
}

/// Thrown by the preview source when a rejected video reaches the crop step.
final class VideoRejectedException implements Exception {
  /// Creates a [VideoRejectedException].
  const VideoRejectedException(this.rejection);

  /// The rejection.
  final VideoRejection rejection;

  @override
  String toString() => 'VideoRejectedException($rejection)';
}

/// Thrown when the gallery cannot hand over a file at all — the iCloud case
/// where the thumbnail rendered but the asset lives only in the cloud
/// (spec §4.5).
final class VideoUnavailableException implements Exception {
  /// Creates a [VideoUnavailableException].
  const VideoUnavailableException(this.assetId);

  /// The asset id.
  final String assetId;

  @override
  String toString() => 'VideoUnavailableException($assetId)';
}
