import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_sizes.dart';
import 'package:kutu_asset_picker/src/crop/crop_math.dart';
import 'package:kutu_asset_picker/src/crop/crop_providers.dart';
import 'package:kutu_asset_picker/src/crop/video/video_bar_slot.dart';
import 'package:kutu_asset_picker/src/crop/video/video_bar_visibility.dart';
import 'package:kutu_asset_picker/src/crop/video/video_crop_constants.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_dimming_mask.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_thirds_overlay.dart';
import 'package:kutu_asset_picker/src/providers/injection_providers.dart';
import 'package:kutu_asset_picker/src/source/picker_asset.dart';
import 'crop_media_surface.dart';

/// The framing area: the viewport with its chrome on top, and — in a session
/// that contains a video — the band under it that holds the video controls.
///
/// The crop window is derived here from the laid-out space and the focused
/// asset's ratio; everything below works in the window it is handed.
///
/// The band is the revised half of spec §2.7. The controls used to float over
/// the footage, `Positioned` at the bottom of this stage while the window was
/// centred in it, so any window tall enough to reach the bottom — 1:1 on a
/// phone, every 9:16 — had its lower edge covered by the controls meant to sit
/// beside it. Now the band is laid out **below** the framing area, and it is
/// reserved for every asset in the session, empty under a photo, so the
/// window is the same size whichever asset is focused: §2.7's rule that the
/// crop area never resizes as the author tabs between a photo and a video is
/// kept, without the occlusion it was paying for.
///
/// `stretch` on the column is load-bearing: it gives the framing area tight
/// constraints, so the mask and the viewport fill the stage's width even when
/// the window is narrower than it. With loose width the stage would size to
/// the window for a photo and to the box for a video, and the bands beside a
/// narrow window would be the plain background for one and the mask colour
/// for the other.
class CropStage extends ConsumerWidget {
  /// Creates a [CropStage].
  const CropStage({required this.asset, super.key});

  /// The asset.
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
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
          ),
          if (reservesVideoBarBand(config, ref.watch(selectedAssetsProvider)))
            SizedBox(
              height: VideoCropConstants.barSlotHeight,
              child: VideoBarSlot(asset: asset),
            ),
        ],
      ),
    );
  }
}
