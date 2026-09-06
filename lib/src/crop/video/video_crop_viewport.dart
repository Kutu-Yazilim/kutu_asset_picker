import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../widgets/crop_viewport.dart';
import 'video_display_size.dart';
import 'video_preview_player.dart';
import 'video_preview_source.dart';

/// A video under the crop window.
///
/// The player is just a widget, so the `ClipRect` + `Transform` stack above it
/// is byte-for-byte the one the photo path uses (spec §6.3): stage-sized, with
/// the [window] `CropStage` laid out centred inside it and the footage showing
/// through the mask beyond it. The controls are **not** here. They used to be
/// `Positioned` over the footage in this widget, which is how they came to
/// cover the bottom of the crop window; `CropStage` now reserves a band under
/// the window for them (spec §2.7), so this is footage and nothing else.
class VideoCropViewport extends ConsumerWidget {
  /// Creates a [VideoCropViewport].
  const VideoCropViewport({
    super.key,
    required this.assetId,
    required this.preview,
    required this.window,
  });

  /// The asset id.
  final String assetId;

  /// The preview.
  final VideoPreviewSource preview;

  /// The crop window `CropStage` computed for the focused aspect.
  final Size window;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final player = ref.watch(videoPreviewPlayerProvider(assetId)).value;
    return CropViewport(
      assetId: assetId,
      // The ROTATED size, never the coded one: `video_player` applies the
      // rotation tag for display, so crop_math must be given what the author
      // sees (spec §7.4 invariant 1).
      imageSize: videoDisplaySize(preview.info),
      window: window,
      child: player == null
          ? const SizedBox.expand()
          : VideoPlayer(player.controller),
    );
  }
}
