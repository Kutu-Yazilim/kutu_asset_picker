import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:kutu_asset_picker/src/config/crop_aspect.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_durations.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_sizes.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_spacing.dart';
import 'package:kutu_asset_picker/src/crop/aspect_chip_label.dart';
import 'package:kutu_asset_picker/src/crop/crop_providers.dart';
import 'package:kutu_asset_picker/src/text/asset_picker_text_scope.dart';
import 'package:kutu_asset_picker/src/theme/asset_picker_theme_scope.dart';

/// One ratio in the menu.
///
/// Tapping runs `CropStates.setAspect`, which is rule 3 of spec §6.2 — the
/// widget itself decides nothing.
class CropAspectChip extends ConsumerWidget {
  const CropAspectChip({
    required this.assetId,
    required this.aspect,
    required this.isSelected,
    super.key,
  });

  final String assetId;
  final CropAspect aspect;
  final bool isSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.pickerTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AssetPickerSpacing.xs),
      child: GestureDetector(
        onTap: () =>
            ref.read(cropStatesProvider.notifier).setAspect(assetId, aspect),
        child: AnimatedContainer(
          duration: AssetPickerDurations.chipSwap,
          height: AssetPickerSizes.chipHeight,
          padding:
              const EdgeInsets.symmetric(horizontal: AssetPickerSpacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color:
                isSelected ? theme.chipSelectedFill : theme.chipUnselectedFill,
            borderRadius: BorderRadius.circular(theme.chipRadius),
          ),
          child: Text(
            aspectChipLabel(aspect, context.pickerText),
            style: theme.labelStyle.copyWith(
              color: isSelected
                  ? theme.chipSelectedText
                  : theme.chipUnselectedText,
            ),
          ),
        ),
      ),
    );
  }
}
