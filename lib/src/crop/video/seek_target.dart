import 'package:video_player/video_player.dart';

/// The one thing the scrubber does to a player.
///
/// A seam rather than a direct [VideoPlayerController] call, because the
/// coalescing rules below are the highest-value logic in the video crop step
/// and they must be testable without a platform player.
abstract interface class SeekTarget {
  /// Seek to.
  Future<void> seekTo(Duration position);
}

/// Video player seek target.
final class VideoPlayerSeekTarget implements SeekTarget {
  /// Creates a [VideoPlayerSeekTarget].
  const VideoPlayerSeekTarget(this.controller);

  /// The controller.
  final VideoPlayerController controller;

  @override
  Future<void> seekTo(Duration position) => controller.seekTo(position);
}

/// Absorbs seeks issued before the player has finished initialising.
///
/// The scrubber is on screen as soon as the filmstrip has frames, which can be
/// before the player is ready; dropping those seeks is correct, because the
/// player seeks to the in point when it does become ready.
final class NoopSeekTarget implements SeekTarget {
  /// Creates a [NoopSeekTarget].
  const NoopSeekTarget();

  @override
  Future<void> seekTo(Duration position) async {}
}
