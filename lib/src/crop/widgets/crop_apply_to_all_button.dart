import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:kutu_asset_picker/src/config/crop_aspect.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_sizes.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_spacing.dart';
import 'package:kutu_asset_picker/src/crop/crop_providers.dart';
import 'package:kutu_asset_picker/src/text/asset_picker_text_scope.dart';
import 'package:kutu_asset_picker/src/theme/asset_picker_theme_scope.dart';

/// Copies the focused asset's **aspect** — never its pan or zoom — to every
/// other selected asset, re-clamping each one through rule 3 (spec §2.4).
///
/// Rendering is gated by [CropAspectChipRow]: with one asset, or with
/// `allowPerAssetAspect: false`, there is nothing for it to do.
class CropApplyToAllButton extends ConsumerWidget {
  const CropApplyToAllButton({required this.aspect, super.key});

  final CropAspect aspect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.pickerTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AssetPickerSpacing.xs),
      child: GestureDetector(
        onTap: () =>
            ref.read(cropStatesProvider.notifier).applyAspectToAll(aspect),
        child: Container(
          height: AssetPickerSizes.chipHeight,
          padding:
              const EdgeInsets.symmetric(horizontal: AssetPickerSpacing.md),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(color: theme.onSurfaceMuted),
            borderRadius: BorderRadius.circular(theme.chipRadius),
          ),
          child: Text(
            context.pickerText.cropApplyToAll,
            style: theme.labelStyle.copyWith(color: theme.onSurface),
          ),
        ),
      ),
    );
  }
}
