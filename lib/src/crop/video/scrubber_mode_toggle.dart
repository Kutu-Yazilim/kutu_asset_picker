import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/injection_providers.dart';
import 'scrubber_mode.dart';
import 'scrubber_mode_chip.dart';
import 'video_bar_visibility.dart';
import 'video_crop_constants.dart';
import '../../text/asset_picker_text_scope.dart';

/// Trim ↔ cover, on the floating bar.
///
/// Renders nothing when the config leaves only one mode — the scrubber is then
/// permanently in that mode and a one-option toggle is noise.
class ScrubberModeToggle extends ConsumerWidget {
  const ScrubberModeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!showsScrubberModeToggle(ref.watch(assetPickerConfigProvider))) {
      return const SizedBox.shrink();
    }
    final text = context.pickerText;
    final mode = ref.watch(scrubberModeControllerProvider);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ScrubberModeChip(
          label: text.cropTrim,
          mode: ScrubberMode.trim,
          selected: mode == ScrubberMode.trim,
        ),
        const SizedBox(width: VideoCropConstants.toggleGap),
        ScrubberModeChip(
          label: text.cropCoverFrame,
          mode: ScrubberMode.cover,
          selected: mode == ScrubberMode.cover,
        ),
      ],
    );
  }
}
