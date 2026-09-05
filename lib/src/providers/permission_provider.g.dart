// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'permission_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The library-access state the whole picker branches on.
///
/// Requested once per scope and cached; [PermissionActions] is what
/// invalidates it.

@ProviderFor(assetPickerPermission)
final assetPickerPermissionProvider = AssetPickerPermissionProvider._();

/// The library-access state the whole picker branches on.
///
/// Requested once per scope and cached; [PermissionActions] is what
/// invalidates it.

final class AssetPickerPermissionProvider extends $FunctionalProvider<
        AsyncValue<PickerPermission>,
        PickerPermission,
        FutureOr<PickerPermission>>
    with $FutureModifier<PickerPermission>, $FutureProvider<PickerPermission> {
  /// The library-access state the whole picker branches on.
  ///
  /// Requested once per scope and cached; [PermissionActions] is what
  /// invalidates it.
  AssetPickerPermissionProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'assetPickerPermissionProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$assetPickerPermissionHash();

  @$internal
  @override
  $FutureProviderElement<PickerPermission> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<PickerPermission> create(Ref ref) {
    return assetPickerPermission(ref);
  }
}

String _$assetPickerPermissionHash() =>
    r'5c6025bea00fab4d292f6ef88d22834ac87cf6b2';

/// The side effects that can change [assetPickerPermissionProvider].
///
/// Separate from the provider itself because the contract declares that one as
/// a function, and because keeping `await` out of widgets (Flutter rule 9)
/// needs somewhere for these to live.

@ProviderFor(PermissionActions)
final permissionActionsProvider = PermissionActionsProvider._();

/// The side effects that can change [assetPickerPermissionProvider].
///
/// Separate from the provider itself because the contract declares that one as
/// a function, and because keeping `await` out of widgets (Flutter rule 9)
/// needs somewhere for these to live.
final class PermissionActionsProvider
    extends $NotifierProvider<PermissionActions, void> {
  /// The side effects that can change [assetPickerPermissionProvider].
  ///
  /// Separate from the provider itself because the contract declares that one as
  /// a function, and because keeping `await` out of widgets (Flutter rule 9)
  /// needs somewhere for these to live.
  PermissionActionsProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'permissionActionsProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$permissionActionsHash();

  @$internal
  @override
  PermissionActions create() => PermissionActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$permissionActionsHash() => r'395159264115aaf6effe0c6a560f87eef85c2705';

/// The side effects that can change [assetPickerPermissionProvider].
///
/// Separate from the provider itself because the contract declares that one as
/// a function, and because keeping `await` out of widgets (Flutter rule 9)
/// needs somewhere for these to live.

abstract class _$PermissionActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<void, void>, void, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
