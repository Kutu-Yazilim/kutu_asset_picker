import 'package:kutu_asset_picker/src/crop/video/seek_target.dart';

/// Records every seek that actually reached the platform, and takes [latency]
/// to complete each one.
///
/// Under `fakeAsync` that latency is fake-clocked, which is what makes the
/// coalescing assertions deterministic.
final class FakeSeekTarget implements SeekTarget {
  FakeSeekTarget({this.latency = Duration.zero});

  final Duration latency;
  final List<Duration> seeks = <Duration>[];

  @override
  Future<void> seekTo(Duration position) {
    seeks.add(position);
    // Zero latency completes on the microtask queue, so a test that only
    // flushes microtasks sees it land; anything else is fake-clocked.
    return latency == Duration.zero
        ? Future<void>.value()
        : Future<void>.delayed(latency);
  }
}
