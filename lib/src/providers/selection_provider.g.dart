// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The ordered selection.
///
/// A list, not a set: the order is what the carousel and the crop step's asset
/// rail present, and it is what the consumer receives.

@ProviderFor(Selection)
final selectionProvider = SelectionProvider._();

/// The ordered selection.
///
/// A list, not a set: the order is what the carousel and the crop step's asset
/// rail present, and it is what the consumer receives.
final class SelectionProvider
    extends $NotifierProvider<Selection, List<String>> {
  /// The ordered selection.
  ///
  /// A list, not a set: the order is what the carousel and the crop step's asset
  /// rail present, and it is what the consumer receives.
  SelectionProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'selectionProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$selectionHash();

  @$internal
  @override
  Selection create() => Selection();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$selectionHash() => r'1672aba675f99a92c4ef5a9f9791ce9a4c034ed9';

/// The ordered selection.
///
/// A list, not a set: the order is what the carousel and the crop step's asset
/// rail present, and it is what the consumer receives.

abstract class _$Selection extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<List<String>, List<String>>,
        List<String>,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
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

@ProviderFor(selectionIndex)
final selectionIndexProvider = SelectionIndexFamily._();

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

final class SelectionIndexProvider extends $FunctionalProvider<int, int, int>
    with $Provider<int> {
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
  SelectionIndexProvider._(
      {required SelectionIndexFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'selectionIndexProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$selectionIndexHash();

  @override
  String toString() {
    return r'selectionIndexProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<int> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  int create(Ref ref) {
    final argument = this.argument as String;
    return selectionIndex(
      ref,
      argument,
    );
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is SelectionIndexProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$selectionIndexHash() => r'8ac6f04c03a0900b1edc3f7fcf5c4a6e27301530';

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

final class SelectionIndexFamily extends $Family
    with $FunctionalFamilyOverride<int, String> {
  SelectionIndexFamily._()
      : super(
          retry: null,
          name: r'selectionIndexProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

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

  SelectionIndexProvider call(
    String assetId,
  ) =>
      SelectionIndexProvider._(argument: assetId, from: this);

  @override
  String toString() => r'selectionIndexProvider';
}

/// Whether `maxSelection` has been reached, which dims every unselected cell.
///
/// This is the one dependency every cell deliberately shares: hitting the cap
/// has to change all of them at once. Its value only changes at the boundary,
/// so it costs one grid-wide rebuild per cap crossing rather than one per tap.

@ProviderFor(selectionCapReached)
final selectionCapReachedProvider = SelectionCapReachedProvider._();

/// Whether `maxSelection` has been reached, which dims every unselected cell.
///
/// This is the one dependency every cell deliberately shares: hitting the cap
/// has to change all of them at once. Its value only changes at the boundary,
/// so it costs one grid-wide rebuild per cap crossing rather than one per tap.

final class SelectionCapReachedProvider
    extends $FunctionalProvider<bool, bool, bool> with $Provider<bool> {
  /// Whether `maxSelection` has been reached, which dims every unselected cell.
  ///
  /// This is the one dependency every cell deliberately shares: hitting the cap
  /// has to change all of them at once. Its value only changes at the boundary,
  /// so it costs one grid-wide rebuild per cap crossing rather than one per tap.
  SelectionCapReachedProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'selectionCapReachedProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$selectionCapReachedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return selectionCapReached(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$selectionCapReachedHash() =>
    r'2fd0fdc13bd3d741ace3b8b4539c457564584fd6';
