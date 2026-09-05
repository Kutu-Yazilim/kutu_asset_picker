import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'video_crop_error_view.dart';
import 'video_crop_loading.dart';
import 'video_crop_stack.dart';
import 'video_preview_source.dart';

/// The crop area for a video: the async gate, and nothing else.
///
/// No `await` here — the wait lives in `videoPreviewSourceProvider` and this
/// widget only renders its three outcomes (Flutter rule 9).
class VideoCropSurface extends ConsumerWidget {
  const VideoCropSurface(
      {super.key, required this.assetId, required this.window});

  final String assetId;
  final Size window;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(videoPreviewSourceProvider(assetId)).when(
            loading: VideoCropLoading.new,
            error: (error, _) => VideoCropErrorView(error: error),
            data: (preview) => VideoCropStack(
              assetId: assetId,
              preview: preview,
              window: window,
            ),
          );
}
