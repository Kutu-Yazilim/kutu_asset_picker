import 'package:kutu_asset_picker/src/config/crop_aspect.dart';
import 'package:kutu_asset_picker/src/crop/crop_math.dart';
import 'package:kutu_asset_picker/src/crop/crop_state.dart';
import 'package:kutu_asset_picker/src/crop/picker_asset_size.dart';
import 'package:kutu_asset_picker/src/providers/injection_providers.dart';
import 'package:kutu_asset_picker/src/providers/selection_provider.dart';
import 'package:kutu_asset_picker/src/source/picker_asset.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'crop_providers.g.dart';

/// The selected assets as value objects, in selection order.
///
/// A one-line projection of slice 3's `Selection.selectedAssets`, and
/// deliberately nothing more. `Selection` captures the `PickerAsset` at tap
/// time — that is what `toggleAsset` is for — so a pick made in Camera still
/// carries its pixel dimensions after the author switches to Screenshots. A
/// second registry here, fed from `assetPageProvider`, would answer the same
/// question and would answer it differently the moment the two disagreed.
///
/// `keepAlive` because the grid unmounts when the crop step opens; without it
/// nothing would watch this at that moment and it would be disposed mid-flow.
@Riverpod(keepAlive: true)
List<PickerAsset> selectedAssets(Ref ref) {
  // Watch the id list, then read the notifier. The notifier itself is a stable
  // object, so watching `selectionProvider.notifier` would never rebuild — and
  // the id list is exactly what a toggle or a reorder changes.
  ref.watch(selectionProvider);
  return ref.read(selectionProvider.notifier).selectedAssets;
}

/// Per-asset crop state, preserved across focus changes (spec §6.1). Tab away
/// and back and the framing is where you left it — which is free, because the
/// state lives in this map and not in the viewport widget.
@Riverpod(keepAlive: true)
class CropStates extends _$CropStates {
  @override
  Map<String, CropState> build() => const <String, CropState>{};

  /// The stored state, or the opening one for an asset nobody has framed yet.
  ///
  /// Returns an *unsized* state rather than writing a normalized one: the
  /// caller normalizes at read time through `reclampForAspect`, which means no
  /// code has to write to a provider during layout.
  CropState stateOf(String assetId) =>
      state[assetId] ??
      CropState.unsized(
        ref.read(assetPickerConfigProvider).effectiveInitialAspect,
      );

  /// Update.
  void update(String assetId, CropState next) =>
      state = {...state, assetId: next};

  /// Change one asset's ratio, running rule 3 of spec §6.2 against the window
  /// of the ratio being switched **to**.
  void setAspect(String assetId, CropAspect aspect) {
    final asset = _assetById(assetId);
    if (asset == null) return;
    state = {
      ...state,
      assetId: reclampForAspect(
        stateOf(assetId),
        pickerAssetSize(asset),
        cropWindowSize(aspect, kCanonicalCropArea),
        aspect,
      ),
    };
  }

  /// Copies the focused asset's **aspect** to every other selected asset and
  /// re-clamps each one through rule 3.
  ///
  /// Aspect only. Pan and zoom are meaningless on a different image — a crop
  /// centred on a face in one photo lands on a shoulder in the next — so each
  /// asset keeps its own framing, adjusted to the new window (spec §2.4).
  void applyAspectToAll(CropAspect aspect) {
    final window = cropWindowSize(aspect, kCanonicalCropArea);
    final next = {...state};
    for (final asset in ref.read(selectedAssetsProvider)) {
      next[asset.id] = reclampForAspect(
        stateOf(asset.id),
        pickerAssetSize(asset),
        window,
        aspect,
      );
    }
    state = next;
  }

  PickerAsset? _assetById(String assetId) {
    for (final asset in ref.read(selectedAssetsProvider)) {
      if (asset.id == assetId) return asset;
    }
    return null;
  }
}

/// Which asset the crop step is editing, or null until the author taps a rail
/// tile.
///
/// Deliberately dependency-free: deriving the default from `selectedAssets`
/// inside `build` would re-run and reset the focus every time the grid paged in
/// more assets. `resolveFocusedAsset` supplies the fallback instead.
@Riverpod(keepAlive: true)
class FocusedAsset extends _$FocusedAsset {
  @override
  String? build() => null;

  /// Focus.
  void focus(String assetId) => state = assetId;
}

/// True while a crop gesture is in flight.
///
/// Drives the rule-of-thirds grid fading in. A provider rather than a hook
/// inside the viewport because the overlay that fades is the viewport's
/// sibling, not its child.
@Riverpod(keepAlive: true)
class CropInteraction extends _$CropInteraction {
  @override
  bool build() => false;

  /// Begin.
  void begin() => state = true;

  /// End.
  void end() => state = false;
}
