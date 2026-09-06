import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'playback_target.dart';
import 'video_preview_player.dart';

/// Where playback goes. **This is the override point**, exactly as
/// `videoSeekTargetProvider` is for scrubbing: every test that drives playback
/// replaces it with a `FakePlaybackTarget`.
///
/// A player that has not finished initialising yields [NoopPlaybackTarget],
/// whose `isReady` is what keeps the play chip inert until there is a picture
/// to play.
final videoPlaybackTargetProvider = Provider.family<PlaybackTarget, String>(
  (ref, assetId) {
    final player = ref.watch(videoPreviewPlayerProvider(assetId)).value;
    return player == null
        ? const NoopPlaybackTarget()
        : VideoPlayerPlaybackTarget(player.controller);
  },
);
