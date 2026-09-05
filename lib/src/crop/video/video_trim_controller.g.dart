// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_trim_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns the trim handles and the cover cursor for one asset.
///
/// The authoritative store is still `CropStates` (spec §6.1) — every change is
/// written through, so tabbing to another asset and back finds the trim exactly
/// where it was left. This notifier is the working copy plus the clamp rules
/// plus the seek that shows the author what the handle is pointing at.
// keepAlive (contract §9): the trim the author set must survive a rebuild
// of the only widget watching it — the bar fades out mid-drag on purpose.

@ProviderFor(VideoTrimController)
final videoTrimControllerProvider = VideoTrimControllerFamily._();

/// Owns the trim handles and the cover cursor for one asset.
///
/// The authoritative store is still `CropStates` (spec §6.1) — every change is
/// written through, so tabbing to another asset and back finds the trim exactly
/// where it was left. This notifier is the working copy plus the clamp rules
/// plus the seek that shows the author what the handle is pointing at.
// keepAlive (contract §9): the trim the author set must survive a rebuild
// of the only widget watching it — the bar fades out mid-drag on purpose.
final class VideoTrimControllerProvider
    extends $NotifierProvider<VideoTrimController, VideoTrimState> {
  /// Owns the trim handles and the cover cursor for one asset.
  ///
  /// The authoritative store is still `CropStates` (spec §6.1) — every change is
  /// written through, so tabbing to another asset and back finds the trim exactly
  /// where it was left. This notifier is the working copy plus the clamp rules
  /// plus the seek that shows the author what the handle is pointing at.
// keepAlive (contract §9): the trim the author set must survive a rebuild
// of the only widget watching it — the bar fades out mid-drag on purpose.
  VideoTrimControllerProvider._(
      {required VideoTrimControllerFamily super.from,
      required (
        String,
        Duration,
      )
          super.argument})
      : super(
          retry: null,
          name: r'videoTrimControllerProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$videoTrimControllerHash();

  @override
  String toString() {
    return r'videoTrimControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  VideoTrimController create() => VideoTrimController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoTrimState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoTrimState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is VideoTrimControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$videoTrimControllerHash() =>
    r'8ef046af91c61b15d17b1aefb86b509f957c5dae';

/// Owns the trim handles and the cover cursor for one asset.
///
/// The authoritative store is still `CropStates` (spec §6.1) — every change is
/// written through, so tabbing to another asset and back finds the trim exactly
/// where it was left. This notifier is the working copy plus the clamp rules
/// plus the seek that shows the author what the handle is pointing at.
// keepAlive (contract §9): the trim the author set must survive a rebuild
// of the only widget watching it — the bar fades out mid-drag on purpose.

final class VideoTrimControllerFamily extends $Family
    with
        $ClassFamilyOverride<
            VideoTrimController,
            VideoTrimState,
            VideoTrimState,
            VideoTrimState,
            (
              String,
              Duration,
            )> {
  VideoTrimControllerFamily._()
      : super(
          retry: null,
          name: r'videoTrimControllerProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: false,
        );

  /// Owns the trim handles and the cover cursor for one asset.
  ///
  /// The authoritative store is still `CropStates` (spec §6.1) — every change is
  /// written through, so tabbing to another asset and back finds the trim exactly
  /// where it was left. This notifier is the working copy plus the clamp rules
  /// plus the seek that shows the author what the handle is pointing at.
// keepAlive (contract §9): the trim the author set must survive a rebuild
// of the only widget watching it — the bar fades out mid-drag on purpose.

  VideoTrimControllerProvider call(
    String assetId,
    Duration total,
  ) =>
      VideoTrimControllerProvider._(argument: (
        assetId,
        total,
      ), from: this);

  @override
  String toString() => r'videoTrimControllerProvider';
}

/// Owns the trim handles and the cover cursor for one asset.
///
/// The authoritative store is still `CropStates` (spec §6.1) — every change is
/// written through, so tabbing to another asset and back finds the trim exactly
/// where it was left. This notifier is the working copy plus the clamp rules
/// plus the seek that shows the author what the handle is pointing at.
// keepAlive (contract §9): the trim the author set must survive a rebuild
// of the only widget watching it — the bar fades out mid-drag on purpose.

abstract class _$VideoTrimController extends $Notifier<VideoTrimState> {
  late final _$args = ref.$arg as (
    String,
    Duration,
  );
  String get assetId => _$args.$1;
  Duration get total => _$args.$2;

  VideoTrimState build(
    String assetId,
    Duration total,
  );
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<VideoTrimState, VideoTrimState>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<VideoTrimState, VideoTrimState>,
        VideoTrimState,
        Object?,
        Object?>;
    return element.handleCreate(
        ref,
        () => build(
              _$args.$1,
              _$args.$2,
            ));
  }
}
