// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crop_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(selectedAssets)
final selectedAssetsProvider = SelectedAssetsProvider._();

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

final class SelectedAssetsProvider extends $FunctionalProvider<
    List<PickerAsset>,
    List<PickerAsset>,
    List<PickerAsset>> with $Provider<List<PickerAsset>> {
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
  SelectedAssetsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'selectedAssetsProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$selectedAssetsHash();

  @$internal
  @override
  $ProviderElement<List<PickerAsset>> $createElement(
          $ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<PickerAsset> create(Ref ref) {
    return selectedAssets(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<PickerAsset> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<PickerAsset>>(value),
    );
  }
}

String _$selectedAssetsHash() => r'9b98e541a4ffca7f328ce3f3d9f01f492cced22a';

/// Per-asset crop state, preserved across focus changes (spec §6.1). Tab away
/// and back and the framing is where you left it — which is free, because the
/// state lives in this map and not in the viewport widget.

@ProviderFor(CropStates)
final cropStatesProvider = CropStatesProvider._();

/// Per-asset crop state, preserved across focus changes (spec §6.1). Tab away
/// and back and the framing is where you left it — which is free, because the
/// state lives in this map and not in the viewport widget.
final class CropStatesProvider
    extends $NotifierProvider<CropStates, Map<String, CropState>> {
  /// Per-asset crop state, preserved across focus changes (spec §6.1). Tab away
  /// and back and the framing is where you left it — which is free, because the
  /// state lives in this map and not in the viewport widget.
  CropStatesProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'cropStatesProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$cropStatesHash();

  @$internal
  @override
  CropStates create() => CropStates();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, CropState> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, CropState>>(value),
    );
  }
}

String _$cropStatesHash() => r'f40fb70a4f1848d24e421111f9f6abc77a01d91b';

/// Per-asset crop state, preserved across focus changes (spec §6.1). Tab away
/// and back and the framing is where you left it — which is free, because the
/// state lives in this map and not in the viewport widget.

abstract class _$CropStates extends $Notifier<Map<String, CropState>> {
  Map<String, CropState> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<Map<String, CropState>, Map<String, CropState>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<Map<String, CropState>, Map<String, CropState>>,
        Map<String, CropState>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}

/// Which asset the crop step is editing, or null until the author taps a rail
/// tile.
///
/// Deliberately dependency-free: deriving the default from `selectedAssets`
/// inside `build` would re-run and reset the focus every time the grid paged in
/// more assets. `resolveFocusedAsset` supplies the fallback instead.

@ProviderFor(FocusedAsset)
final focusedAssetProvider = FocusedAssetProvider._();

/// Which asset the crop step is editing, or null until the author taps a rail
/// tile.
///
/// Deliberately dependency-free: deriving the default from `selectedAssets`
/// inside `build` would re-run and reset the focus every time the grid paged in
/// more assets. `resolveFocusedAsset` supplies the fallback instead.
final class FocusedAssetProvider
    extends $NotifierProvider<FocusedAsset, String?> {
  /// Which asset the crop step is editing, or null until the author taps a rail
  /// tile.
  ///
  /// Deliberately dependency-free: deriving the default from `selectedAssets`
  /// inside `build` would re-run and reset the focus every time the grid paged in
  /// more assets. `resolveFocusedAsset` supplies the fallback instead.
  FocusedAssetProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'focusedAssetProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$focusedAssetHash();

  @$internal
  @override
  FocusedAsset create() => FocusedAsset();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$focusedAssetHash() => r'b374fea0b4fec99cc45f7fc16b6a999fd99ed8eb';

/// Which asset the crop step is editing, or null until the author taps a rail
/// tile.
///
/// Deliberately dependency-free: deriving the default from `selectedAssets`
/// inside `build` would re-run and reset the focus every time the grid paged in
/// more assets. `resolveFocusedAsset` supplies the fallback instead.

abstract class _$FocusedAsset extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<String?, String?>, String?, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

/// True while a crop gesture is in flight.
///
/// Drives the rule-of-thirds grid fading in. A provider rather than a hook
/// inside the viewport because the overlay that fades is the viewport's
/// sibling, not its child.

@ProviderFor(CropInteraction)
final cropInteractionProvider = CropInteractionProvider._();

/// True while a crop gesture is in flight.
///
/// Drives the rule-of-thirds grid fading in. A provider rather than a hook
/// inside the viewport because the overlay that fades is the viewport's
/// sibling, not its child.
final class CropInteractionProvider
    extends $NotifierProvider<CropInteraction, bool> {
  /// True while a crop gesture is in flight.
  ///
  /// Drives the rule-of-thirds grid fading in. A provider rather than a hook
  /// inside the viewport because the overlay that fades is the viewport's
  /// sibling, not its child.
  CropInteractionProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'cropInteractionProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$cropInteractionHash();

  @$internal
  @override
  CropInteraction create() => CropInteraction();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$cropInteractionHash() => r'a0806fb7812f22131f8f4bbb9c66605d9cb15244';

/// True while a crop gesture is in flight.
///
/// Drives the rule-of-thirds grid fading in. A provider rather than a hook
/// inside the viewport because the overlay that fades is the viewport's
/// sibling, not its child.

abstract class _$CropInteraction extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<bool, bool>, bool, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
