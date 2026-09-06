// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the sequential [ExportQueue] and publishes its progress.
///
/// [ExportController.run] **never throws**. The Done button calls it and walks
/// away — Flutter rule 9 forbids `await` in UI — so an escaping exception would surface as an
/// unhandled zone error with no UI anywhere to show it.

@ProviderFor(ExportController)
final exportControllerProvider = ExportControllerProvider._();

/// Drives the sequential [ExportQueue] and publishes its progress.
///
/// [ExportController.run] **never throws**. The Done button calls it and walks
/// away — Flutter rule 9 forbids `await` in UI — so an escaping exception would surface as an
/// unhandled zone error with no UI anywhere to show it.
final class ExportControllerProvider
    extends $NotifierProvider<ExportController, ExportProgress> {
  /// Drives the sequential [ExportQueue] and publishes its progress.
  ///
  /// [ExportController.run] **never throws**. The Done button calls it and walks
  /// away — Flutter rule 9 forbids `await` in UI — so an escaping exception would surface as an
  /// unhandled zone error with no UI anywhere to show it.
  ExportControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'exportControllerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$exportControllerHash();

  @$internal
  @override
  ExportController create() => ExportController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExportProgress value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExportProgress>(value),
    );
  }
}

String _$exportControllerHash() => r'524b9b87f4a09661117dd521c578b31024181c3f';

/// Drives the sequential [ExportQueue] and publishes its progress.
///
/// [ExportController.run] **never throws**. The Done button calls it and walks
/// away — Flutter rule 9 forbids `await` in UI — so an escaping exception would surface as an
/// unhandled zone error with no UI anywhere to show it.

abstract class _$ExportController extends $Notifier<ExportProgress> {
  ExportProgress build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ExportProgress, ExportProgress>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<ExportProgress, ExportProgress>,
        ExportProgress,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
