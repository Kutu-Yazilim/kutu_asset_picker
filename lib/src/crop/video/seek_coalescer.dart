import 'dart:async';

import 'seek_target.dart';
import 'video_crop_constants.dart';

/// Collapses a drag's worth of seek requests into the few the platform can
/// actually service.
///
/// Apple QA1820 documents that rapid successive `seekToTime:` calls cancel one
/// another, so a scrubber that fires one seek per drag pixel produces a great
/// deal of seeking and almost no displayed frames. Android has the same class
/// of problem (flutter#171583) and is handled identically.
///
/// Three rules, in this order:
///
/// 1. **Leading edge.** An idle coalescer seeks immediately, so the first
///    frame appears the instant the finger moves.
/// 2. **In-flight gate.** While a seek is outstanding, later requests overwrite
///    a single pending slot instead of queueing. Only the newest survives.
/// 3. **Trailing guarantee.** When a seek completes with something pending, the
///    next one is scheduled after [debounce] — which is what bounds the rate —
///    and the loop repeats until nothing is pending. The last position the
///    caller asked for therefore always lands.
final class SeekCoalescer {
  SeekCoalescer({
    required SeekTarget target,
    Duration debounce = VideoCropConstants.seekDebounce,
  })  : _target = target,
        _debounce = debounce;

  final SeekTarget _target;
  final Duration _debounce;

  Duration? _pending;
  bool _inFlight = false;
  bool _disposed = false;
  bool _flushRequested = false;
  Timer? _timer;

  /// The position that has been asked for but not yet sent.
  Duration? get pending => _pending;

  /// Whether a seek is outstanding on the platform right now.
  bool get isSeeking => _inFlight;

  void request(Duration position) {
    if (_disposed) return;
    _pending = position;
    if (_inFlight || _timer != null) return;
    unawaited(_drain());
  }

  /// Send the pending position now, ignoring the debounce floor.
  ///
  /// Called on drag end so the released handle lands on its exact frame
  /// instead of waiting out a timer.
  Future<void> flush() async {
    _timer?.cancel();
    _timer = null;
    // A seek still on the platform cannot be interrupted; remember that the
    // next one must go straight out when it lands instead of after the floor.
    _flushRequested = _inFlight;
    await _drain();
  }

  Future<void> _drain() async {
    if (_disposed || _inFlight) return;
    final next = _pending;
    if (next == null) return;
    _pending = null;
    _inFlight = true;
    try {
      await _target.seekTo(next);
    } finally {
      _inFlight = false;
    }
    if (_disposed || _pending == null) return;
    if (_flushRequested) {
      _flushRequested = false;
      unawaited(_drain());
      return;
    }
    _timer = Timer(_debounce, () {
      _timer = null;
      unawaited(_drain());
    });
  }

  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _timer = null;
    _pending = null;
  }
}
