// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_preview_player.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Owns one asset's [VideoPlayerController].
///
/// Deliberately a thin shim with no logic of its own: everything worth testing
/// — the trim clamps, the seek coalescing, the crop rect — lives in pure
/// functions and in providers that take a [SeekTarget], so this file needs no
/// unit test and gets none.
///
/// Muted, because framing a crop is a silent activity and an autoplaying clip
/// with sound is the wrong thing to do to someone who just tapped a thumbnail.

@ProviderFor(videoPreviewPlayer)
final videoPreviewPlayerProvider = VideoPreviewPlayerFamily._();

/// Owns one asset's [VideoPlayerController].
///
/// Deliberately a thin shim with no logic of its own: everything worth testing
/// — the trim clamps, the seek coalescing, the crop rect — lives in pure
/// functions and in providers that take a [SeekTarget], so this file needs no
/// unit test and gets none.
///
/// Muted, because framing a crop is a silent activity and an autoplaying clip
/// with sound is the wrong thing to do to someone who just tapped a thumbnail.

final class VideoPreviewPlayerProvider extends $FunctionalProvider<
        AsyncValue<VideoPlayerController>,
        VideoPlayerController,
        FutureOr<VideoPlayerController>>
    with
        $FutureModifier<VideoPlayerController>,
        $FutureProvider<VideoPlayerController> {
  /// Owns one asset's [VideoPlayerController].
  ///
  /// Deliberately a thin shim with no logic of its own: everything worth testing
  /// — the trim clamps, the seek coalescing, the crop rect — lives in pure
  /// functions and in providers that take a [SeekTarget], so this file needs no
  /// unit test and gets none.
  ///
  /// Muted, because framing a crop is a silent activity and an autoplaying clip
  /// with sound is the wrong thing to do to someone who just tapped a thumbnail.
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
  $FutureProviderElement<VideoPlayerController> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<VideoPlayerController> create(Ref ref) {
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
    r'9af4e5b8ab186b3f848abc19af5021264a2815c8';

/// Owns one asset's [VideoPlayerController].
///
/// Deliberately a thin shim with no logic of its own: everything worth testing
/// — the trim clamps, the seek coalescing, the crop rect — lives in pure
/// functions and in providers that take a [SeekTarget], so this file needs no
/// unit test and gets none.
///
/// Muted, because framing a crop is a silent activity and an autoplaying clip
/// with sound is the wrong thing to do to someone who just tapped a thumbnail.

final class VideoPreviewPlayerFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<VideoPlayerController>, String> {
  VideoPreviewPlayerFamily._()
      : super(
          retry: null,
          name: r'videoPreviewPlayerProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Owns one asset's [VideoPlayerController].
  ///
  /// Deliberately a thin shim with no logic of its own: everything worth testing
  /// — the trim clamps, the seek coalescing, the crop rect — lives in pure
  /// functions and in providers that take a [SeekTarget], so this file needs no
  /// unit test and gets none.
  ///
  /// Muted, because framing a crop is a silent activity and an autoplaying clip
  /// with sound is the wrong thing to do to someone who just tapped a thumbnail.

  VideoPreviewPlayerProvider call(
    String assetId,
  ) =>
      VideoPreviewPlayerProvider._(argument: assetId, from: this);

  @override
  String toString() => r'videoPreviewPlayerProvider';
}
