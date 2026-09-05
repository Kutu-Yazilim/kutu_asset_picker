import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'scrubber_mode.dart';
import 'video_crop_constants.dart';
import '../../theme/asset_picker_theme_scope.dart';

/// One mode of the scrubber, as a tappable chip.
class ScrubberModeChip extends ConsumerWidget {
  /// Creates a [ScrubberModeChip].
  const ScrubberModeChip({
    super.key,
    required this.label,
    required this.mode,
    required this.selected,
  });

  /// The label.
  final String label;

  /// The mode.
  final ScrubberMode mode;

  /// The selected.
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.pickerTheme;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () =>
          ref.read(scrubberModeControllerProvider.notifier).select(mode),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? theme.chipSelectedFill : theme.chipUnselectedFill,
          borderRadius: BorderRadius.circular(theme.chipRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: VideoCropConstants.barPadding,
            vertical: VideoCropConstants.toggleGap,
          ),
          child: Text(
            label,
            style: theme.labelStyle.copyWith(
              color:
                  selected ? theme.chipSelectedText : theme.chipUnselectedText,
            ),
          ),
        ),
      ),
    );
  }
}
