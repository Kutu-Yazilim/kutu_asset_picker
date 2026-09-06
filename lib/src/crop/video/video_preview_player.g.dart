// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_preview_player.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The muted, initialised preview player for [assetId], seeked to the trim's
/// in point. Disposed with the provider; framing a crop is a silent activity.

@ProviderFor(videoPreviewPlayer)
final videoPreviewPlayerProvider = VideoPreviewPlayerFamily._();

/// The muted, initialised preview player for [assetId], seeked to the trim's
/// in point. Disposed with the provider; framing a crop is a silent activity.

final class VideoPreviewPlayerProvider extends $FunctionalProvider<
        AsyncValue<VideoPreviewPlayer>,
        VideoPreviewPlayer,
        FutureOr<VideoPreviewPlayer>>
    with
        $FutureModifier<VideoPreviewPlayer>,
        $FutureProvider<VideoPreviewPlayer> {
  /// The muted, initialised preview player for [assetId], seeked to the trim's
  /// in point. Disposed with the provider; framing a crop is a silent activity.
  VideoPreviewPlayerProvider._(
      {required VideoPreviewPlayerFamily super.from,
      required String super.argument})
      : super(
          retry: null,
          name: r'videoPreviewPlayerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$videoPreviewPlayerHash();

  @override
  String toString() {
    return r'videoPreviewPlayerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<VideoPreviewPlayer> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<VideoPreviewPlayer> create(Ref ref) {
    final argument = this.argument as String;
    return videoPreviewPlayer(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is VideoPreviewPlayerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$videoPreviewPlayerHash() =>
    r'00b09f3b27d2d6957676106d4ce2cf5303e8958e';

/// The muted, initialised preview player for [assetId], seeked to the trim's
/// in point. Disposed with the provider; framing a crop is a silent activity.

final class VideoPreviewPlayerFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<VideoPreviewPlayer>, String> {
  VideoPreviewPlayerFamily._()
      : super(
          retry: null,
          name: r'videoPreviewPlayerProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// The muted, initialised preview player for [assetId], seeked to the trim's
  /// in point. Disposed with the provider; framing a crop is a silent activity.

  VideoPreviewPlayerProvider call(
    String assetId,
  ) =>
      VideoPreviewPlayerProvider._(argument: assetId, from: this);

  @override
  String toString() => r'videoPreviewPlayerProvider';
}
