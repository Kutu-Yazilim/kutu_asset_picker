// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'slow_motion_flatten.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Flattens every selected slow-motion clip before the selection leaves the
/// grid (spec §7.3).
///
/// Sequential, unlike the iCloud pre-flight beside it: these are encoder jobs
/// competing for the same hardware, not network waits, so overlapping them
/// buys nothing and costs memory (spec §7.5's reasoning, same hardware).

@ProviderFor(SlowMotionFlatten)
final slowMotionFlattenProvider = SlowMotionFlattenProvider._();

/// Flattens every selected slow-motion clip before the selection leaves the
/// grid (spec §7.3).
///
/// Sequential, unlike the iCloud pre-flight beside it: these are encoder jobs
/// competing for the same hardware, not network waits, so overlapping them
/// buys nothing and costs memory (spec §7.5's reasoning, same hardware).
final class SlowMotionFlattenProvider
    extends $NotifierProvider<SlowMotionFlatten, SlowMotionFlattenState> {
  /// Flattens every selected slow-motion clip before the selection leaves the
  /// grid (spec §7.3).
  ///
  /// Sequential, unlike the iCloud pre-flight beside it: these are encoder jobs
  /// competing for the same hardware, not network waits, so overlapping them
  /// buys nothing and costs memory (spec §7.5's reasoning, same hardware).
  SlowMotionFlattenProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'slowMotionFlattenProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$slowMotionFlattenHash();

  @$internal
  @override
  SlowMotionFlatten create() => SlowMotionFlatten();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SlowMotionFlattenState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SlowMotionFlattenState>(value),
    );
  }
}

String _$slowMotionFlattenHash() => r'a52c0c3a72573158b46164395ecc5a945fca7420';

/// Flattens every selected slow-motion clip before the selection leaves the
/// grid (spec §7.3).
///
/// Sequential, unlike the iCloud pre-flight beside it: these are encoder jobs
/// competing for the same hardware, not network waits, so overlapping them
/// buys nothing and costs memory (spec §7.5's reasoning, same hardware).

abstract class _$SlowMotionFlatten extends $Notifier<SlowMotionFlattenState> {
  SlowMotionFlattenState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<SlowMotionFlattenState, SlowMotionFlattenState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<SlowMotionFlattenState, SlowMotionFlattenState>,
        SlowMotionFlattenState,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}

/// The source every consumer of a *selected* asset's file must read.
///
/// `assetSourceProvider` is still the gallery and is still what the grid and
/// the pass itself use; this is the gallery with the flatten pass's rewrites
/// laid over it. Reading the wrong one is how a trim range chosen against a
/// 12-second timeline ends up applied to a 3-second file.

@ProviderFor(flattenedAssetSource)
final flattenedAssetSourceProvider = FlattenedAssetSourceProvider._();

/// The source every consumer of a *selected* asset's file must read.
///
/// `assetSourceProvider` is still the gallery and is still what the grid and
/// the pass itself use; this is the gallery with the flatten pass's rewrites
/// laid over it. Reading the wrong one is how a trim range chosen against a
/// 12-second timeline ends up applied to a 3-second file.

final class FlattenedAssetSourceProvider
    extends $FunctionalProvider<AssetSource, AssetSource, AssetSource>
    with $Provider<AssetSource> {
  /// The source every consumer of a *selected* asset's file must read.
  ///
  /// `assetSourceProvider` is still the gallery and is still what the grid and
  /// the pass itself use; this is the gallery with the flatten pass's rewrites
  /// laid over it. Reading the wrong one is how a trim range chosen against a
  /// 12-second timeline ends up applied to a 3-second file.
  FlattenedAssetSourceProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'flattenedAssetSourceProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$flattenedAssetSourceHash();

  @$internal
  @override
  $ProviderElement<AssetSource> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AssetSource create(Ref ref) {
    return flattenedAssetSource(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AssetSource value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AssetSource>(value),
    );
  }
}

String _$flattenedAssetSourceHash() =>
    r'75a3205b6525f5a25fc34449e941cb9e7b44477e';
