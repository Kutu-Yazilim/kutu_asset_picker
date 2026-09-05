// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_page_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The current album's assets, loaded a page at a time.
///
/// Rebuilding — a new album, or an explicit invalidate after the limited
/// selection changed — restarts paging from offset zero.

@ProviderFor(AssetPage)
final assetPageProvider = AssetPageProvider._();

/// The current album's assets, loaded a page at a time.
///
/// Rebuilding — a new album, or an explicit invalidate after the limited
/// selection changed — restarts paging from offset zero.
final class AssetPageProvider
    extends $AsyncNotifierProvider<AssetPage, List<PickerAsset>> {
  /// The current album's assets, loaded a page at a time.
  ///
  /// Rebuilding — a new album, or an explicit invalidate after the limited
  /// selection changed — restarts paging from offset zero.
  AssetPageProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'assetPageProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$assetPageHash();

  @$internal
  @override
  AssetPage create() => AssetPage();
}

String _$assetPageHash() => r'34d1cb6acaa723b9b164bbf0b1f9462d055916b4';

/// The current album's assets, loaded a page at a time.
///
/// Rebuilding — a new album, or an explicit invalidate after the limited
/// selection changed — restarts paging from offset zero.

abstract class _$AssetPage extends $AsyncNotifier<List<PickerAsset>> {
  FutureOr<List<PickerAsset>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<PickerAsset>>, List<PickerAsset>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<PickerAsset>>, List<PickerAsset>>,
        AsyncValue<List<PickerAsset>>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
