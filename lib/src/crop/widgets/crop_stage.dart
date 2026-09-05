import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_sizes.dart';
import 'package:kutu_asset_picker/src/crop/crop_math.dart';
import 'package:kutu_asset_picker/src/crop/crop_providers.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_dimming_mask.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_thirds_overlay.dart';
import 'package:kutu_asset_picker/src/providers/injection_providers.dart';
import 'package:kutu_asset_picker/src/source/picker_asset.dart';
import 'crop_media_surface.dart';

/// The framing area: the viewport with its chrome on top.
///
/// The crop window is derived here from the laid-out space and the focused
/// asset's ratio; everything below works in the window it is handed.
class CropStage extends ConsumerWidget {
  const CropStage({required this.asset, super.key});

  final PickerAsset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(assetPickerConfigProvider);
    final aspect = ref.watch(
          cropStatesProvider.select((states) => states[asset.id]?.aspect),
        ) ??
        config.effectiveInitialAspect;

    return Padding(
      padding: const EdgeInsets.all(AssetPickerSizes.cropStageInset),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final window = cropWindowSize(aspect, constraints.biggest);
          return Stack(
            alignment: Alignment.center,
            children: [
              CropMediaSurface(asset: asset, window: window),
              Positioned.fill(
                child: IgnorePointer(
                  child: CropDimmingMask(
                    window: window,
                    shape: config.cropOverlayShape,
                  ),
                ),
              ),
              CropThirdsOverlay(window: window),
            ],
          );
        },
      ),
    );
  }
}
