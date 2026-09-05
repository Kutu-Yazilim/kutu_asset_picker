// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'camera_capture_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Drives the OS camera delegate.
///
/// State is "a capture is in flight", so the tile can go inert rather than
/// launching two cameras on a double tap. All the `await`ing happens here and
/// none of it in the widget (Flutter rule 9).

@ProviderFor(CameraCapture)
final cameraCaptureProvider = CameraCaptureProvider._();

/// Drives the OS camera delegate.
///
/// State is "a capture is in flight", so the tile can go inert rather than
/// launching two cameras on a double tap. All the `await`ing happens here and
/// none of it in the widget (Flutter rule 9).
final class CameraCaptureProvider
    extends $NotifierProvider<CameraCapture, bool> {
  /// Drives the OS camera delegate.
  ///
  /// State is "a capture is in flight", so the tile can go inert rather than
  /// launching two cameras on a double tap. All the `await`ing happens here and
  /// none of it in the widget (Flutter rule 9).
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
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$cameraCaptureHash() => r'e818f88d699488e575678ff535c2e46d24a3c317';

/// Drives the OS camera delegate.
///
/// State is "a capture is in flight", so the tile can go inert rather than
/// launching two cameras on a double tap. All the `await`ing happens here and
/// none of it in the widget (Flutter rule 9).

abstract class _$CameraCapture extends $Notifier<bool> {
  bool build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<bool, bool>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<bool, bool>, bool, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
