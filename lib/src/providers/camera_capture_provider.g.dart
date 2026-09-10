// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'camera_capture_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the OS camera delegate.
///
/// All the `await`ing happens here and none of it in the widget (Flutter
/// rule 9). The tile goes inert while a capture is in flight rather than
/// launching two cameras on a double tap.

@ProviderFor(CameraCapture)
final cameraCaptureProvider = CameraCaptureProvider._();

/// Drives the OS camera delegate.
///
/// All the `await`ing happens here and none of it in the widget (Flutter
/// rule 9). The tile goes inert while a capture is in flight rather than
/// launching two cameras on a double tap.
final class CameraCaptureProvider
    extends $NotifierProvider<CameraCapture, CameraCaptureStatus> {
  /// Drives the OS camera delegate.
  ///
  /// All the `await`ing happens here and none of it in the widget (Flutter
  /// rule 9). The tile goes inert while a capture is in flight rather than
  /// launching two cameras on a double tap.
  CameraCaptureProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'cameraCaptureProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$cameraCaptureHash();

  @$internal
  @override
  CameraCapture create() => CameraCapture();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CameraCaptureStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CameraCaptureStatus>(value),
    );
  }
}

String _$cameraCaptureHash() => r'dd247ddd9f8660108cc4ae837ad7d2ff567cc462';

/// Drives the OS camera delegate.
///
/// All the `await`ing happens here and none of it in the widget (Flutter
/// rule 9). The tile goes inert while a capture is in flight rather than
/// launching two cameras on a double tap.

abstract class _$CameraCapture extends $Notifier<CameraCaptureStatus> {
  CameraCaptureStatus build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CameraCaptureStatus, CameraCaptureStatus>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<CameraCaptureStatus, CameraCaptureStatus>,
        CameraCaptureStatus,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
