import 'package:video_player/video_player.dart';

import 'seek_target.dart';

/// What playback does to a player, over and above seeking.
///
/// The same seam [SeekTarget] is, for the same reason: the play/pause/loop
/// rules in `VideoPlaybackController` must be testable without a platform
/// player, and a fake that records calls and reports a chosen position is
/// what makes them so.
abstract interface class PlaybackTarget implements SeekTarget {
  /// Whether there is a player to drive yet.
  bool get isReady;

  /// Play.
  Future<void> play();

  /// Pause.
  Future<void> pause();

  /// The player's current position, straight from the platform — `video_player`
  /// refreshes its own copy only every 500 ms, too coarse for a playhead.
  Future<Duration?> get position;
}

/// Video player playback target.
final class VideoPlayerPlaybackTarget implements PlaybackTarget {
  /// Creates a [VideoPlayerPlaybackTarget].
  const VideoPlayerPlaybackTarget(this.controller);

  /// The controller.
  final VideoPlayerController controller;

  @override
  bool get isReady => true;

  @override
  Future<void> play() => controller.play();

  @override
  Future<void> pause() => controller.pause();

  @override
  Future<void> seekTo(Duration position) => controller.seekTo(position);

  @override
  Future<Duration?> get position => controller.position;
}

/// Stands in until the player has initialised.
///
/// Reports itself not ready, which is what disables the play chip; everything
/// else is a no-op, so a stray call cannot throw.
final class NoopPlaybackTarget implements PlaybackTarget {
  /// Creates a [NoopPlaybackTarget].
  const NoopPlaybackTarget();

  @override
  bool get isReady => false;

  @override
  Future<void> play() async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> seekTo(Duration position) async {}

  @override
  Future<Duration?> get position async => null;
}
