// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'albums_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The album list for the configured media types.

@ProviderFor(AssetPickerAlbums)
final assetPickerAlbumsProvider = AssetPickerAlbumsProvider._();

/// The album list for the configured media types.
final class AssetPickerAlbumsProvider
    extends $AsyncNotifierProvider<AssetPickerAlbums, List<PickerAlbum>> {
  /// The album list for the configured media types.
  AssetPickerAlbumsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'assetPickerAlbumsProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$assetPickerAlbumsHash();

  @$internal
  @override
  AssetPickerAlbums create() => AssetPickerAlbums();
}

String _$assetPickerAlbumsHash() => r'fd561edb10016a9a8b69a0de98afdca7e8935329';

/// The album list for the configured media types.

abstract class _$AssetPickerAlbums extends $AsyncNotifier<List<PickerAlbum>> {
  FutureOr<List<PickerAlbum>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<PickerAlbum>>, List<PickerAlbum>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AsyncValue<List<PickerAlbum>>, List<PickerAlbum>>,
        AsyncValue<List<PickerAlbum>>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}

/// Which album the grid is showing.

@ProviderFor(CurrentAlbum)
final currentAlbumProvider = CurrentAlbumProvider._();

/// Which album the grid is showing.
final class CurrentAlbumProvider
    extends $NotifierProvider<CurrentAlbum, PickerAlbum?> {
  /// Which album the grid is showing.
  CurrentAlbumProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'currentAlbumProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$currentAlbumHash();

  @$internal
  @override
  CurrentAlbum create() => CurrentAlbum();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PickerAlbum? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PickerAlbum?>(value),
    );
  }
}

String _$currentAlbumHash() => r'651592a8c51b2b501d18fb19705bf05711945597';

/// Which album the grid is showing.

abstract class _$CurrentAlbum extends $Notifier<PickerAlbum?> {
  PickerAlbum? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PickerAlbum?, PickerAlbum?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<PickerAlbum?, PickerAlbum?>,
        PickerAlbum?,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
