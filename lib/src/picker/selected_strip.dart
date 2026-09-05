import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/picker_tuning.dart';
import '../providers/selection_provider.dart';
import '../source/picker_asset.dart';
import 'selected_strip_tile.dart';

/// The bottom strip of selected assets, draggable to reorder (design §5).
///
/// The order is not cosmetic: it is the order the consumer receives, and the
/// order slice 4's crop rail presents. This strip is the only place the user
/// can state it.
///
/// [Selection.reorder] already converts `ReorderableListView`'s pre-removal
/// destination index; passing the tear-off straight through is what keeps this
/// surface and slice 4's rail on one convention. Do **not** adjust the indices
/// here as well.
class SelectedStrip extends ConsumerWidget {
  const SelectedStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the id list for rebuilds; read the notifier for the assets behind
    // them. The registry lives on the notifier because AssetPage only holds
    // the current album, and a strip that dropped a pick on album switch would
    // be worse than no strip.
    final List<String> ids = ref.watch(selectionProvider);
    if (ids.isEmpty) {
      return const SizedBox.shrink();
    }
    final List<PickerAsset> assets =
        ref.read(selectionProvider.notifier).selectedAssets;

    return SizedBox(
      height: PickerChromeSizes.selectedStripHeight,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        padding: PickerChromeSizes.selectedStripPadding,
        itemCount: assets.length,
        onReorderItem: ref.read(selectionProvider.notifier).reorderItem,
        itemBuilder: (BuildContext context, int index) => Padding(
          key: ValueKey<String>(assets[index].id),
          padding: const EdgeInsets.only(
            right: PickerChromeSizes.selectedStripSpacing,
          ),
          child: SelectedStripTile(asset: assets[index]),
        ),
      ),
    );
  }
}
