import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'video_crop_constants.dart';
import 'video_rejection.dart';
import 'video_rejection_message.dart';
import '../../theme/asset_picker_theme_scope.dart';
import '../../text/asset_picker_text_scope.dart';

/// The crop area for a video that cannot be edited.
///
/// Two causes, one surface: a ceiling was exceeded, or the gallery could not
/// hand over the file at all (spec §4.5's iCloud case).
class VideoCropErrorView extends ConsumerWidget {
  const VideoCropErrorView({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.pickerTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(VideoCropConstants.barPadding),
        child: switch (error) {
          VideoRejectedException(:final rejection) =>
            VideoRejectionMessage(rejection: rejection),
          _ => Text(
              context.pickerText.pickerDownloadFailed,
              textAlign: TextAlign.center,
              style: theme.labelStyle.copyWith(color: theme.onSurfaceMuted),
            ),
        },
      ),
    );
  }
}
