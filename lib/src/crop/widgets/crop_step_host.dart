import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:kutu_asset_picker/src/config/picker_enums.dart';
import 'package:kutu_asset_picker/src/config/picker_tuning.dart';
import 'package:kutu_asset_picker/src/crop/widgets/asset_crop_step.dart';
import 'package:kutu_asset_picker/src/providers/injection_providers.dart';
import 'package:kutu_asset_picker/src/theme/asset_picker_theme_scope.dart';

/// Shapes [AssetCropStep] as a page or a sheet, per `config.cropSurface`.
///
/// `pickerSurface` and `cropSurface` are configured independently (spec §2.6):
/// an avatar picker is a lightweight sheet while a post composer is a full
/// page, and the two steps do not have to agree. Slice 3's `PickerGridStep`
/// makes exactly this switch for the grid; this is the crop half, and without
/// it `cropSurface` is a field nothing reads.
///
/// Both branches shape the crop step **in place**. Pushing a second route for
/// the crop step would give the cropper two hosts, which is the thing spec §2.6
/// picked a separate step to avoid.
///
/// The sheet branch is a fixed-height rounded panel rather than a
/// `DraggableScrollableSheet`: the crop step contains no scrollable to hand
/// that widget's `ScrollController` to, so a draggable sheet here would render
/// a drag affordance that does nothing. Drag-to-dismiss belongs to the modal
/// route `KutuAssetPicker.show` created, which is still there underneath.
class CropStepHost extends ConsumerWidget {
  /// Creates a [CropStepHost].
  const CropStepHost({required this.onBack, super.key});

  /// The on back.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(assetPickerConfigProvider).cropSurface) {
        PickerSurface.page => Scaffold(
            backgroundColor: context.pickerTheme.background,
            body: AssetCropStep(onBack: onBack),
          ),
        PickerSurface.sheet => Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: PickerChromeSizes.sheetInitialExtent,
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(context.pickerTheme.sheetRadius),
                ),
                child: ColoredBox(
                  color: context.pickerTheme.background,
                  child: AssetCropStep(onBack: onBack),
                ),
              ),
            ),
          ),
      };
}
