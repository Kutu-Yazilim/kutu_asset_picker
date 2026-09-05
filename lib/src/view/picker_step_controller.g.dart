// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'picker_step_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(PickerStepController)
final pickerStepControllerProvider = PickerStepControllerProvider._();

final class PickerStepControllerProvider
    extends $NotifierProvider<PickerStepController, AssetPickerStep> {
  PickerStepControllerProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'pickerStepControllerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$pickerStepControllerHash();

  @$internal
  @override
  PickerStepController create() => PickerStepController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AssetPickerStep value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AssetPickerStep>(value),
    );
  }
}

String _$pickerStepControllerHash() =>
    r'8f7c19706336370d58ef6ce435ffcc43a115e460';

abstract class _$PickerStepController extends $Notifier<AssetPickerStep> {
  AssetPickerStep build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AssetPickerStep, AssetPickerStep>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<AssetPickerStep, AssetPickerStep>,
        AssetPickerStep,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
