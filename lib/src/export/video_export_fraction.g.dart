// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_export_fraction.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How far through the video currently exporting.
///
/// Separate from `ExportProgress`, which counts assets: a photo export is
/// milliseconds and a done/total counter describes it fine, while a video
/// export is seconds to minutes and needs a bar that actually moves.

@ProviderFor(VideoExportFraction)
final videoExportFractionProvider = VideoExportFractionProvider._();

/// How far through the video currently exporting.
///
/// Separate from `ExportProgress`, which counts assets: a photo export is
/// milliseconds and a done/total counter describes it fine, while a video
/// export is seconds to minutes and needs a bar that actually moves.
final class VideoExportFractionProvider
    extends $NotifierProvider<VideoExportFraction, double> {
  /// How far through the video currently exporting.
  ///
  /// Separate from `ExportProgress`, which counts assets: a photo export is
  /// milliseconds and a done/total counter describes it fine, while a video
  /// export is seconds to minutes and needs a bar that actually moves.
  VideoExportFractionProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'videoExportFractionProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$videoExportFractionHash();

  @$internal
  @override
  VideoExportFraction create() => VideoExportFraction();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(double value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<double>(value),
    );
  }
}

String _$videoExportFractionHash() =>
    r'febf1e183fa459f5f50ccbd3ac4a2fad6b338f5c';

/// How far through the video currently exporting.
///
/// Separate from `ExportProgress`, which counts assets: a photo export is
/// milliseconds and a done/total counter describes it fine, while a video
/// export is seconds to minutes and needs a bar that actually moves.

abstract class _$VideoExportFraction extends $Notifier<double> {
  double build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<double, double>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<double, double>, double, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}
