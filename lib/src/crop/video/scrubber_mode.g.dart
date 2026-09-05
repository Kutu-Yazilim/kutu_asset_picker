// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scrubber_mode.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ScrubberModeController)
final scrubberModeControllerProvider = ScrubberModeControllerProvider._();

final class ScrubberModeControllerProvider
    extends $NotifierProvider<ScrubberModeController, ScrubberMode> {
  ScrubberModeControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'scrubberModeControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$scrubberModeControllerHash();

  @$internal
  @override
  ScrubberModeController create() => ScrubberModeController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ScrubberMode value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ScrubberMode>(value),
    );
  }
}

String _$scrubberModeControllerHash() =>
    r'9591b0fe223f8cec594be244b88a738955839960';

abstract class _$ScrubberModeController extends $Notifier<ScrubberMode> {
  ScrubberMode build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ScrubberMode, ScrubberMode>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<ScrubberMode, ScrubberMode>,
        ScrubberMode,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
