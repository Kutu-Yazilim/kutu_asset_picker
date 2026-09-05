import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:kutu_asset_picker/src/crop/crop_providers.dart';
import 'package:kutu_asset_picker/src/crop/focused_asset_resolver.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_asset_rail.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_aspect_chip_row.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_stage.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_step_app_bar.dart';
import 'package:kutu_asset_picker/src/theme/asset_picker_theme_scope.dart';

/// The crop screen (spec §6).
///
/// Layout order is fixed and deliberate: the rail is permanent and last, the
/// chips sit directly above it, and the stage takes what is left. The rail
/// never moves and never changes height, so the framing area does not resize as
/// the author tabs between assets (spec §2.7).
class AssetCropStep extends ConsumerWidget {
  const AssetCropStep({required this.onBack, super.key});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focused = resolveFocusedAsset(
      ref.watch(selectedAssetsProvider),
      ref.watch(focusedAssetProvider),
    );
    if (focused == null) return const SizedBox.shrink();

    return ColoredBox(
      color: context.pickerTheme.background,
      child: SafeArea(
        child: Column(
          children: [
            CropStepAppBar(onBack: onBack),
            Expanded(child: CropStage(asset: focused)),
            CropAspectChipRow(assetId: focused.id),
            const CropAssetRail(),
          ],
        ),
      ),
    );
  }
}
