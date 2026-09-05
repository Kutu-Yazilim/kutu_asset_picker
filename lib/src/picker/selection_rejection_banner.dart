import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../crop/video/video_crop_constants.dart';
import '../crop/video/video_rejection_message.dart';
import 'selection_attempt.dart';
import '../theme/asset_picker_theme_scope.dart';

/// The last refused selection, over the grid.
///
/// Occupies no space at all when nothing has been refused, so the grid's
/// layout does not shift the first time someone taps a too-long clip.
class SelectionRejectionBanner extends ConsumerWidget {
  /// Creates a [SelectionRejectionBanner].
  const SelectionRejectionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rejection = ref.watch(selectionAttemptProvider);
    if (rejection == null) return const SizedBox.shrink();
    final theme = context.pickerTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ref.read(selectionAttemptProvider.notifier).dismiss(),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.danger.withValues(
            alpha: VideoCropConstants.barSurfaceOpacity,
          ),
          borderRadius: BorderRadius.circular(theme.chipRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(VideoCropConstants.barPadding),
          child: VideoRejectionMessage(rejection: rejection),
        ),
      ),
    );
  }
}
