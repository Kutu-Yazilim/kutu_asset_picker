import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_sizes.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_spacing.dart';
import 'package:kutu_asset_picker/src/crop/crop_providers.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_apply_to_all_button.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_aspect_chip.dart';
import 'package:kutu_asset_picker/src/providers/injection_providers.dart';

/// The ratio menu for the focused asset, plus *Apply to all* when it has
/// something to do.
class CropAspectChipRow extends ConsumerWidget {
  /// Creates a [CropAspectChipRow].
  const CropAspectChipRow({required this.assetId, super.key});

  /// The asset id.
  final String assetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(assetPickerConfigProvider);
    final selected = ref.watch(
          cropStatesProvider.select((states) => states[assetId]?.aspect),
        ) ??
        config.effectiveInitialAspect;

    return SizedBox(
      height: AssetPickerSizes.chipRow,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AssetPickerSpacing.sm),
        children: [
          for (final aspect in config.aspects)
            CropAspectChip(
              key: ValueKey(aspect),
              assetId: assetId,
              aspect: aspect,
              isSelected: aspect == selected,
            ),
          if (config.allowPerAssetAspect &&
              ref.watch(selectedAssetsProvider).length > 1)
            CropApplyToAllButton(aspect: selected),
        ],
      ),
    );
  }
}
