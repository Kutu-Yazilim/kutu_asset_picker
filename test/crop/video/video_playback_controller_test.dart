import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/crop/video/playback_target.dart';
import 'package:kutu_asset_picker/src/crop/video/scrubber_mode.dart';
import 'package:kutu_asset_picker/src/crop/video/video_crop_constants.dart';
import 'package:kutu_asset_picker/src/crop/video/video_playback_controller.dart';
import 'package:kutu_asset_picker/src/crop/video/video_playback_providers.dart';
import 'package:kutu_asset_picker/src/crop/video/video_seek_providers.dart';
import 'package:kutu_asset_picker/src/crop/video/video_trim_controller.dart';

import '../../support/fake_playback_target.dart';
import '../../support/fake_seek_target.dart';

void main() {
  const assetId = 'clip-1';
  const total = Duration(seconds: 40);
  const tick = VideoCropConstants.playbackPollInterval;
  final provider = videoPlaybackControllerProvider(assetId, total);

  late FakePlaybackTarget target;
  late FakeSeekTarget seekTarget;

  /// A container with the notifier kept alive — it is auto-dispose, so a
  /// bare `read` between calls would hand back a fresh one each time.
  ProviderContainer containerWith({PlaybackTarget? playback}) {
    final container = ProviderContainer(
      overrides: [
        assetPickerConfigProvider.overrideWithValue(const AssetPickerConfig()),
        videoSeekTargetProvider(assetId).overrideWithValue(seekTarget),
        videoPlaybackTargetProvider(assetId)
            .overrideWithValue(playback ?? target),
      ],
    );
    addTearDown(container.dispose);
    container.listen(provider, (_, __) {});
    return container;
  }

  setUp(() {
    target = FakePlaybackTarget();
    seekTarget = FakeSeekTarget();
  });

  test('starts paused, with no playhead, and ready once the player is', () {
    final container = containerWith();

    final state = container.read(provider);

    expect(state.isPlaying, isFalse);
    expect(state.playhead, isNull);
    expect(state.isReady, isTrue);
  });

  test('play is a no-op before the player exists', () {
    fakeAsync((async) {
      final container = containerWith(playback: const NoopPlaybackTarget());

      container.read(provider.notifier).play();
      async.elapse(tick * 3);

      expect(container.read(provider).isReady, isFalse);
      expect(container.read(provider).isPlaying, isFalse);
    });
  });

  test('play seeks to the in point, starts the player and polls the playhead',
      () {
    fakeAsync((async) {
      final container = containerWith();

      container.read(provider.notifier).play();
      async.flushMicrotasks();

      expect(target.sequence, [PlaybackCall.seek, PlaybackCall.play]);
      expect(target.seeks, [Duration.zero]);
      expect(container.read(provider).isPlaying, isTrue);
      expect(container.read(provider).playhead, Duration.zero);

      target.at = const Duration(seconds: 3);
      async.elapse(tick);

      expect(container.read(provider).playhead, const Duration(seconds: 3));
    });
  });

  test('loops back to the in point when playback reaches the out point', () {
    fakeAsync((async) {
      final container = containerWith();
      // Keep 0:00–0:20 of the forty-second clip.
      container
          .read(videoTrimControllerProvider(assetId, total).notifier)
          .nudgeEnd(-0.5);
      container.read(provider.notifier).play();
      async.flushMicrotasks();

      target.at = const Duration(seconds: 20);
      async.elapse(tick);

      // The platform stops at the end of the file, so the loop plays again
      // after seeking rather than trusting the player to still be running.
      expect(target.seeks.last, Duration.zero);
      expect(target.sequence.last, PlaybackCall.play);
      expect(container.read(provider).playhead, Duration.zero);
      expect(container.read(provider).isPlaying, isTrue);
    });
  });

  test('SNAPS BACK TO THE IN POINT WHEN THE PLATFORM WRAPS TO ZERO', () {
    fakeAsync((async) {
      // The preview player loops natively at end-of-file — the alternative,
      // `video_player`'s `completed` handling, pauses and seeks to the last
      // frame asynchronously and races this controller's own loop. So a clip
      // trimmed from the middle wraps to zero, before its in point.
      final container = containerWith();
      // Keep 0:10–0:40.
      container
          .read(videoTrimControllerProvider(assetId, total).notifier)
          .nudgeStart(0.25);
      container.read(provider.notifier).play();
      async.flushMicrotasks();
      expect(target.seeks.last, const Duration(seconds: 10));

      target.at = const Duration(milliseconds: 500);
      async.elapse(tick);

      expect(target.seeks.last, const Duration(seconds: 10));
      expect(container.read(provider).playhead, const Duration(seconds: 10));
      expect(container.read(provider).isPlaying, isTrue);
    });
  });

  test('A POSITION A HAIR BEFORE THE IN POINT IS NOT A WRAP', () {
    fakeAsync((async) {
      // AVPlayer answers a frame-accurate seek with the decoded frame's own
      // time, a few milliseconds before what was asked. Read as "before the
      // in point", that would seek again on every poll and freeze the picture
      // on the first frame of the clip — which is exactly what it did.
      final container = containerWith();
      container
          .read(videoTrimControllerProvider(assetId, total).notifier)
          .nudgeStart(0.25);
      container.read(provider.notifier).play();
      async.flushMicrotasks();
      final seeksAfterPlay = target.seeks.length;

      target.at =
          const Duration(seconds: 10) - const Duration(milliseconds: 20);
      async.elapse(tick);

      expect(target.seeks.length, seeksAfterPlay);
      expect(container.read(provider).playhead, target.at);
    });
  });

  test('pause holds the playhead, and play resumes from it', () {
    fakeAsync((async) {
      final container = containerWith();
      final notifier = container.read(provider.notifier)..play();
      async.flushMicrotasks();
      target.at = const Duration(seconds: 5);
      async.elapse(tick);

      notifier.pause();
      async.flushMicrotasks();

      expect(container.read(provider).isPlaying, isFalse);
      expect(container.read(provider).playhead, const Duration(seconds: 5));
      expect(target.playing, isFalse);
      // Polling stops with playback.
      final reads = target.positionReads;
      async.elapse(tick * 5);
      expect(target.positionReads, reads);

      notifier.play();
      async.flushMicrotasks();

      expect(target.seeks.last, const Duration(seconds: 5));
      expect(target.playing, isTrue);
    });
  });

  test('pausing in trim mode lands the player on the frame the playhead marks',
      () {
    fakeAsync((async) {
      final container = containerWith();
      final notifier = container.read(provider.notifier)..play();
      async.flushMicrotasks();
      target.at = const Duration(seconds: 5);
      async.elapse(tick);

      notifier.pause();
      async.flushMicrotasks();

      // The poll is up to one interval behind the picture; the seek is what
      // makes the line on the strip and the frame on screen agree.
      expect(
        target.sequence.sublist(target.sequence.length - 2),
        [PlaybackCall.pause, PlaybackCall.seek],
      );
      expect(target.seeks.last, const Duration(seconds: 5));
      // Trim mode never touches the cover.
      expect(
        container.read(videoTrimControllerProvider(assetId, total)).coverAt,
        Duration.zero,
      );
    });
  });

  test('PAUSING IN COVER MODE PICKS THE FRAME UNDER THE PLAYHEAD', () {
    fakeAsync((async) {
      final container = containerWith();
      container
          .read(scrubberModeControllerProvider.notifier)
          .select(ScrubberMode.cover);
      final notifier = container.read(provider.notifier)..play();
      async.flushMicrotasks();
      target.at = const Duration(seconds: 9);
      async.elapse(tick);

      notifier.pause();
      async.flushMicrotasks();

      // Choosing that frame is the only thing cover mode is for, so a pause
      // is the choice — and the cover's own seek lands the picture on it.
      expect(
        container.read(videoTrimControllerProvider(assetId, total)).coverAt,
        const Duration(seconds: 9),
      );
      expect(seekTarget.seeks.last, const Duration(seconds: 9));
      expect(container.read(provider).isPlaying, isFalse);
    });
  });

  test('play restarts from the in point when the playhead is outside the range',
      () {
    fakeAsync((async) {
      final container = containerWith();
      final notifier = container.read(provider.notifier)..play();
      async.flushMicrotasks();
      target.at = const Duration(seconds: 30);
      async.elapse(tick);
      notifier.pause();
      async.flushMicrotasks();

      // Now keep 0:00–0:20: the playhead at 0:30 is no longer in the clip.
      container
          .read(videoTrimControllerProvider(assetId, total).notifier)
          .nudgeEnd(-0.5);
      notifier.play();
      async.flushMicrotasks();

      expect(target.seeks.last, Duration.zero);
      expect(container.read(provider).playhead, Duration.zero);
    });
  });

  test('A SCRUB PAUSES PLAYBACK WITHOUT MOVING THE PLAYHEAD', () {
    fakeAsync((async) {
      final container = containerWith();
      container.read(provider.notifier).play();
      async.flushMicrotasks();
      target.at = const Duration(seconds: 7);
      async.elapse(tick);
      final seeksBefore = target.seeks.length;

      // The author grabbed a handle: they are positioning by hand now.
      container
          .read(videoTrimControllerProvider(assetId, total).notifier)
          .nudgeStart(0.1);
      async.flushMicrotasks();

      expect(container.read(provider).isPlaying, isFalse);
      expect(target.playing, isFalse);
      // The line stays where playback stopped, as the reference the handle is
      // being dragged towards; the handle's own seek shows its frame.
      expect(container.read(provider).playhead, const Duration(seconds: 7));
      expect(target.seeks.length, seeksBefore,
          reason: 'the scrub seeks through the coalescer, not through here');
    });
  });

  test('toggle flips between playing and paused', () {
    fakeAsync((async) {
      final container = containerWith();
      final notifier = container.read(provider.notifier)..toggle();
      async.flushMicrotasks();
      expect(container.read(provider).isPlaying, isTrue);

      notifier.toggle();
      async.flushMicrotasks();
      expect(container.read(provider).isPlaying, isFalse);
    });
  });

  test('a pause that lands while the platform is still starting wins', () {
    fakeAsync((async) {
      final container = containerWith();
      final notifier = container.read(provider.notifier)
        ..play()
        ..pause();
      async.flushMicrotasks();

      expect(container.read(provider).isPlaying, isFalse);
      expect(target.playing, isFalse);
      expect(target.sequence.last, PlaybackCall.pause);
      notifier.toggle();
      async.flushMicrotasks();
      expect(target.playing, isTrue);
    });
  });

  test('DISPOSING STOPS THE POLL AND PAUSES THE PLAYER', () {
    fakeAsync((async) {
      // Auto-dispose on purpose, against contract §9's keepAlive default: the
      // seek target keeps the platform player alive for the whole session,
      // so a muted clip left playing when its controls leave the screen would
      // decode in the background until the picker closed.
      final container = ProviderContainer(
        overrides: [
          assetPickerConfigProvider
              .overrideWithValue(const AssetPickerConfig()),
          videoSeekTargetProvider(assetId).overrideWithValue(seekTarget),
          videoPlaybackTargetProvider(assetId).overrideWithValue(target),
        ],
      );
      addTearDown(container.dispose);
      final subscription = container.listen(provider, (_, __) {});
      container.read(provider.notifier).play();
      async.flushMicrotasks();
      target.at = const Duration(seconds: 2);
      async.elapse(tick);
      expect(target.playing, isTrue);

      subscription.close();
      async.elapse(tick);
      final reads = target.positionReads;
      async.elapse(tick * 5);

      expect(target.playing, isFalse);
      expect(target.positionReads, reads);
    });
  });
}
