import 'package:kutu_asset_picker/src/crop/video/playback_target.dart';

/// What a [FakePlaybackTarget] was asked to do.
enum PlaybackCall {
  /// `play()`.
  play,

  /// `pause()`.
  pause,

  /// `seekTo(...)`.
  seek,
}

/// One recorded call, with the position for a seek.
typedef PlaybackCallRecord = ({PlaybackCall call, Duration? at});

/// A player that records what it is told and reports whatever position the
/// test last gave it.
///
/// It does not advance on its own: a test sets [at] between polls, which is
/// what makes the loop and pause assertions deterministic under `fakeAsync`.
final class FakePlaybackTarget implements PlaybackTarget {
  FakePlaybackTarget({this.isReady = true});

  @override
  final bool isReady;

  /// The position the next [position] read reports; a seek overwrites it.
  Duration? at = Duration.zero;

  /// Whether the last play/pause left the player playing.
  bool playing = false;

  /// Every call, in order.
  final List<PlaybackCallRecord> calls = <PlaybackCallRecord>[];

  /// How many times [position] was read — the poll counter.
  int positionReads = 0;

  /// The recorded calls, without their positions.
  List<PlaybackCall> get sequence =>
      <PlaybackCall>[for (final record in calls) record.call];

  /// Every seek position, in order.
  List<Duration?> get seeks => <Duration?>[
        for (final record in calls)
          if (record.call == PlaybackCall.seek) record.at,
      ];

  @override
  Future<void> play() async {
    playing = true;
    calls.add((call: PlaybackCall.play, at: null));
  }

  @override
  Future<void> pause() async {
    playing = false;
    calls.add((call: PlaybackCall.pause, at: null));
  }

  @override
  Future<void> seekTo(Duration position) async {
    at = position;
    calls.add((call: PlaybackCall.seek, at: position));
  }

  @override
  Future<Duration?> get position async {
    positionReads += 1;
    return at;
  }
}
