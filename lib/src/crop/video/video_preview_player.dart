import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:video_player/video_player.dart';

import 'trim_math.dart';
import 'video_preview_source.dart';
import '../../providers/injection_providers.dart';

part 'video_preview_player.g.dart';

/// Owns one asset's [VideoPlayerController].
///
/// Deliberately a thin shim with no logic of its own: everything worth testing
/// — the trim clamps, the seek coalescing, the crop rect — lives in pure
/// functions and in providers that take a [SeekTarget], so this file needs no
/// unit test and gets none.
///
/// Muted, because framing a crop is a silent activity and an autoplaying clip
/// with sound is the wrong thing to do to someone who just tapped a thumbnail.
@riverpod
Future<VideoPlayerController> videoPreviewPlayer(
    Ref ref, String assetId) async {
  final preview = await ref.watch(videoPreviewSourceProvider(assetId).future);
  final controller = VideoPlayerController.file(preview.file);
  // Registered BEFORE the await: an asset the author tabs away from during
  // initialisation would otherwise leak the platform surface.
  ref.onDispose(controller.dispose);
  await controller.initialize();
  await controller.setVolume(0);
  await controller.setLooping(false);
  await controller.seekTo(
    initialTrim(
      preview.info.duration,
      ref.read(assetPickerConfigProvider).maxVideoDuration,
    ).start,
  );
  return controller;
}
