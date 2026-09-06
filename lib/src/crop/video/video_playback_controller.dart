// The playback target is a hand-written `Provider.family`, like the seek
// target it mirrors: the override point every test replaces with a fake.
// ignore_for_file: avoid_manual_providers_as_generated_provider_dependency

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'playback_target.dart';
import 'scrubber_mode.dart';
import 'trim_math.dart';
import 'video_crop_constants.dart';
import 'video_playback_providers.dart';
import 'video_trim_controller.dart';

part 'video_playback_controller.g.dart';

/// Where one asset's preview is, and whether it is moving.
@immutable
final class VideoPlayback {
  /// Creates a [VideoPlayback].
  const VideoPlayback({
    required this.isReady,
    required this.isPlaying,
    this.playhead,
  });

  /// Whether there is a player to drive yet.
  final bool isReady;

  /// Whether the preview is playing.
  final bool isPlaying;

  /// The last position playback reached, or null before the first play.
  ///
  /// It stays put through a pause and through a scrub: on the filmstrip it is
  /// the mark the author drags a handle towards.
  final Duration? playhead;

  /// Copy with.
  VideoPlayback copyWith({bool? isPlaying, Duration? playhead}) =>
      VideoPlayback(
        isReady: isReady,
        isPlaying: isPlaying ?? this.isPlaying,
        playhead: playhead ?? this.playhead,
      );

  @override
  bool operator ==(Object other) =>
      other is VideoPlayback &&
      other.isReady == isReady &&
      other.isPlaying == isPlaying &&
      other.playhead == playhead;

  @override
  int get hashCode => Object.hash(isReady, isPlaying, playhead);
}

/// Plays the kept range of one video, so the author finds a moment by watching
/// for it instead of guessing from twelve filmstrip thumbnails.
///
/// The rules, in one place:
///
/// - **Play** seeks to the playhead when it is inside the kept range and to the
///   in point otherwise, then polls the platform position every
///   [VideoCropConstants.playbackPollInterval] and loops at the out point — or
///   from before the in point, which is where a natively looping player lands
///   when a clip trimmed from the middle reaches the end of its file. The loop
///   plays again after seeking rather than trusting the player to still be
///   running.
/// - **Pause** holds the playhead. In trim mode it then seeks the player onto
///   it, so the line on the strip and the frame on screen agree — the poll is
///   up to one interval behind the picture. In cover mode it sets the cover
///   there instead: choosing that frame is the only thing cover mode is for,
///   so pausing is the choice, and the cover's own seek lands the picture.
/// - **A scrub** — any change to the trim state — pauses without moving the
///   playhead and without seeking. The author is positioning by hand now, the
///   handle's own seek shows its frame, and the line stays as the reference
///   they are dragging towards.
///
/// Auto-dispose, against contract §9's keepAlive default, on purpose: the seek
/// target keeps the platform player alive for the whole session, so a muted
/// clip left playing when its controls leave the screen would decode in the
/// background until the picker closed. Disposal pauses it.
@riverpod
class VideoPlaybackController extends _$VideoPlaybackController {
  PlaybackTarget _target = const NoopPlaybackTarget();
  Timer? _poll;
  bool _playing = false;
  bool _looping = false;

  @override
  VideoPlayback build(String assetId, Duration total) {
    _target = ref.watch(videoPlaybackTargetProvider(assetId));
    ref.listen(
      videoTrimControllerProvider(assetId, total),
      (_, __) => _pauseForScrub(),
    );
    ref.onDispose(_release);
    return VideoPlayback(isReady: _target.isReady, isPlaying: false);
  }

  /// Play.
  Future<void> play() async {
    if (!state.isReady || _playing) return;
    _playing = true;
    final from = resumePoint(state.playhead, _trim);
    state = state.copyWith(isPlaying: true, playhead: from);
    await _target.seekTo(from);
    await _target.play();
    // Paused, scrubbed or disposed while the platform was starting: the pause
    // that landed first must win, so undo the play that landed last.
    if (!_playing) {
      await _target.pause();
      return;
    }
    _poll = Timer.periodic(
      VideoCropConstants.playbackPollInterval,
      (_) => unawaited(_tick()),
    );
  }

  /// Pause.
  Future<void> pause() async {
    if (!_playing) return;
    _halt();
    final at = state.playhead;
    await _target.pause();
    if (at == null || !ref.mounted) return;
    if (ref.read(scrubberModeControllerProvider) == ScrubberMode.cover) {
      ref
          .read(videoTrimControllerProvider(assetId, total).notifier)
          .setCover(at);
      return;
    }
    await _target.seekTo(at);
  }

  /// Toggle.
  Future<void> toggle() => _playing ? pause() : play();

  DurationRange get _trim =>
      ref.read(videoTrimControllerProvider(assetId, total)).trim;

  Future<void> _tick() async {
    if (_looping) return;
    final at = await _target.position;
    if (!_playing || !ref.mounted || at == null) return;
    final trim = _trim;
    // Well before the in point counts as out of range too: the platform loops
    // the whole file at end-of-file, so a clip trimmed from the middle wraps
    // to zero and must be brought back to its in point. "Well" matters: a
    // frame-accurate seek reports a few milliseconds early, and treating that
    // as a wrap would seek again on every poll.
    final wrapped = at < trim.start - VideoCropConstants.playbackWrapTolerance;
    if (!wrapped && at < trim.end) {
      state = state.copyWith(playhead: at);
      return;
    }
    _looping = true;
    state = state.copyWith(playhead: trim.start);
    await _target.seekTo(trim.start);
    await _target.play();
    _looping = false;
  }

  void _pauseForScrub() {
    if (!_playing) return;
    _halt();
    unawaited(_target.pause());
  }

  void _halt() {
    _playing = false;
    _poll?.cancel();
    _poll = null;
    state = state.copyWith(isPlaying: false);
  }

  void _release() {
    _poll?.cancel();
    _poll = null;
    if (!_playing) return;
    _playing = false;
    unawaited(_target.pause());
  }
}
