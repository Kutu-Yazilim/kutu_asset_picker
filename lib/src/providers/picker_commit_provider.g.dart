// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'picker_commit_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The iCloud pre-flight that runs before the selection leaves the grid.
///
/// design §4.5: with Optimize Storage on, a thumbnail renders perfectly from a
/// local derivative while the asset itself lives only in iCloud. The grid looks
/// complete and the failure surfaces at *Next*. This moves the discovery
/// earlier, reports it per asset, and makes it cancellable.
///
/// The downloads run **concurrently on purpose**. design §7.5's
/// strictly-sequential rule governs the export queue, which is CPU-bound
/// decoding that competes for the same memory; these are network waits, and
/// "one slow asset never blocks the rest of a multi-select" is unreachable
/// serially.

@ProviderFor(PickerCommit)
final pickerCommitProvider = PickerCommitProvider._();

/// The iCloud pre-flight that runs before the selection leaves the grid.
///
/// design §4.5: with Optimize Storage on, a thumbnail renders perfectly from a
/// local derivative while the asset itself lives only in iCloud. The grid looks
/// complete and the failure surfaces at *Next*. This moves the discovery
/// earlier, reports it per asset, and makes it cancellable.
///
/// The downloads run **concurrently on purpose**. design §7.5's
/// strictly-sequential rule governs the export queue, which is CPU-bound
/// decoding that competes for the same memory; these are network waits, and
/// "one slow asset never blocks the rest of a multi-select" is unreachable
/// serially.
final class PickerCommitProvider
    extends $NotifierProvider<PickerCommit, PickerCommitState> {
  /// The iCloud pre-flight that runs before the selection leaves the grid.
  ///
  /// design §4.5: with Optimize Storage on, a thumbnail renders perfectly from a
  /// local derivative while the asset itself lives only in iCloud. The grid looks
  /// complete and the failure surfaces at *Next*. This moves the discovery
  /// earlier, reports it per asset, and makes it cancellable.
  ///
  /// The downloads run **concurrently on purpose**. design §7.5's
  /// strictly-sequential rule governs the export queue, which is CPU-bound
  /// decoding that competes for the same memory; these are network waits, and
  /// "one slow asset never blocks the rest of a multi-select" is unreachable
  /// serially.
  PickerCommitProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'pickerCommitProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$pickerCommitHash();

  @$internal
  @override
  PickerCommit create() => PickerCommit();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PickerCommitState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PickerCommitState>(value),
    );
  }
}

String _$pickerCommitHash() => r'93cbb39f27cef0e4099cd21faab76a526abfcf3e';

/// The iCloud pre-flight that runs before the selection leaves the grid.
///
/// design §4.5: with Optimize Storage on, a thumbnail renders perfectly from a
/// local derivative while the asset itself lives only in iCloud. The grid looks
/// complete and the failure surfaces at *Next*. This moves the discovery
/// earlier, reports it per asset, and makes it cancellable.
///
/// The downloads run **concurrently on purpose**. design §7.5's
/// strictly-sequential rule governs the export queue, which is CPU-bound
/// decoding that competes for the same memory; these are network waits, and
/// "one slow asset never blocks the rest of a multi-select" is unreachable
/// serially.

abstract class _$PickerCommit extends $Notifier<PickerCommitState> {
  PickerCommitState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PickerCommitState, PickerCommitState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<PickerCommitState, PickerCommitState>,
        PickerCommitState,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
