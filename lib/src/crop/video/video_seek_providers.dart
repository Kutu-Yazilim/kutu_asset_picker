import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'seek_coalescer.dart';
import 'seek_target.dart';
import 'video_preview_player.dart';

/// Where seeks go. **This is the override point**: every test that drives the
/// scrubber replaces this with a `FakeSeekTarget`, which is what keeps the
/// coalescing behaviour testable without a platform player.
///
/// A player that has not finished initialising yields [NoopSeekTarget] rather
/// than an error, because the filmstrip is interactive before the player is
/// ready and those early seeks are correctly discarded — the player seeks to
/// the in point itself once it initialises.
final videoSeekTargetProvider = Provider.family<SeekTarget, String>(
  (ref, assetId) {
    final player = ref.watch(videoPreviewPlayerProvider(assetId)).value;
    return player == null
        ? const NoopSeekTarget()
        : VideoPlayerSeekTarget(player);
  },
);

/// One coalescer per asset, disposed with the scope.
final videoSeekCoalescerProvider = Provider.family<SeekCoalescer, String>(
  (ref, assetId) {
    final coalescer =
        SeekCoalescer(target: ref.watch(videoSeekTargetProvider(assetId)));
    ref.onDispose(coalescer.dispose);
    return coalescer;
  },
);
