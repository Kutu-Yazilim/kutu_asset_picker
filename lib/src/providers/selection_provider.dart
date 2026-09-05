import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../source/picker_asset.dart';
import 'injection_providers.dart';

part 'selection_provider.g.dart';

/// The ordered selection.
///
/// A list, not a set: the order is what the carousel and the crop step's asset
/// rail present, and it is what the consumer receives.
@Riverpod(keepAlive: true)
class Selection extends _$Selection {
  /// Every asset this notifier has been handed, by id.
  ///
  /// [AssetPage] only holds the *current* album, so without this a user who
  /// selects from Camera and then switches to Screenshots would lose the
  /// Camera pick at commit time.
  final Map<String, PickerAsset> _known = <String, PickerAsset>{};

  @override
  List<String> build() => const <String>[];

  /// Toggles by id. Adding past `maxSelection` is inert — it must never
  /// silently evict an earlier pick.
  void toggle(String assetId) {
    final List<String> current = state;
    if (current.contains(assetId)) {
      state = <String>[
        for (final String id in current)
          if (id != assetId) id,
      ];
      return;
    }
    if (!canSelectMore()) {
      return;
    }
    state = <String>[...current, assetId];
  }

  /// Toggles and remembers the asset behind the id.
  ///
  /// This is what a grid cell calls, so the tap handler stays a single call
  /// with no logic in the widget (Flutter rule 6).
  void toggleAsset(PickerAsset asset) {
    _known[asset.id] = asset;
    toggle(asset.id);
  }

  /// [reorder] for `ReorderableListView.onReorderItem`, whose `newIndex` is
  /// already adjusted for the removed item. The contract's [reorder] keeps
  /// the raw insertion-point convention, so the adjusted index is mapped back
  /// rather than the contract changing under slice 4's rail.
  void reorderItem(int oldIndex, int adjustedNewIndex) {
    reorder(
      oldIndex,
      adjustedNewIndex > oldIndex ? adjustedNewIndex + 1 : adjustedNewIndex,
    );
  }

  void reorder(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.length) {
      return;
    }
    // ReorderableListView reports the destination as an insertion point in the
    // pre-removal list, so a forward move is one index too high.
    final int target = newIndex > oldIndex ? newIndex - 1 : newIndex;
    if (target < 0 || target >= state.length) {
      return;
    }
    final List<String> next = <String>[...state];
    next.insert(target, next.removeAt(oldIndex));
    state = next;
  }

  bool canSelectMore() =>
      state.length < ref.read(assetPickerConfigProvider).maxSelection;

  /// The selected assets, in selection order.
  List<PickerAsset> get selectedAssets => <PickerAsset>[
        for (final String id in state)
          if (_known[id] case final PickerAsset asset) asset,
      ];
}

/// This asset's 1-based position in the selection, or 0 when unselected.
///
/// **This family is the rebuild-granularity mechanism** (contract §9). A grid
/// cell watches only `selectionIndexProvider(asset.id)`, and Riverpod notifies
/// a listener only when the computed value changes — so toggling one asset
/// rebuilds one cell, plus any cell whose number genuinely shifted.
///
/// It is deliberately auto-dispose: there is one element per asset id the user
/// has scrolled past, and keeping those alive would be a real leak. Every other
/// provider in this package is `keepAlive`.
@riverpod
int selectionIndex(Ref ref, String assetId) =>
    ref.watch(selectionProvider).indexOf(assetId) + 1;

/// Whether `maxSelection` has been reached, which dims every unselected cell.
///
/// This is the one dependency every cell deliberately shares: hitting the cap
/// has to change all of them at once. Its value only changes at the boundary,
/// so it costs one grid-wide rebuild per cap crossing rather than one per tap.
@riverpod
bool selectionCapReached(Ref ref) =>
    ref.watch(selectionProvider).length >=
    ref.watch(assetPickerConfigProvider).maxSelection;
