import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_sizes.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_spacing.dart';
import 'package:kutu_asset_picker/src/crop/crop_providers.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_asset_rail_tile.dart';
import 'package:kutu_asset_picker/src/providers/selection_provider.dart';

/// The asset navigator: permanent, fixed height, tap to focus, long-press to
/// reorder.
///
/// Fixed height on purpose (spec §2.7). Two stacked rails were rejected because
/// the crop area would then be a different height for photos and videos, so the
/// image would visibly resize as the author tabs between them; swiping between
/// assets was rejected because a horizontal drag inside the crop window is
/// ambiguous — it fights pan.
class CropAssetRail extends ConsumerWidget {
  /// Creates a [CropAssetRail].
  const CropAssetRail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(selectedAssetsProvider);
    return SizedBox(
      height: AssetPickerSizes.railHeight,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AssetPickerSpacing.sm,
          vertical: AssetPickerSpacing.sm,
        ),
        // A tap must focus, so the whole tile cannot be a drag handle. A delayed
        // press is the standard way to have both on one target.
        buildDefaultDragHandles: false,
        itemCount: assets.length,
        itemBuilder: (context, index) => ReorderableDelayedDragStartListener(
          key: ValueKey(assets[index].id),
          index: index,
          child: CropAssetRailTile(asset: assets[index]),
        ),
        // onReorderItem already adjusts for the removed item; reorderItem maps
        // it back onto Selection.reorder's raw convention, the same way the
        // grid's selected strip does, so both rails agree by construction.
        onReorderItem: ref.read(selectionProvider.notifier).reorderItem,
      ),
    );
  }
}
