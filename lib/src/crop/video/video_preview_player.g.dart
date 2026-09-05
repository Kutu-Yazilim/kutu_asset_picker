// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_preview_player.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(videoPreviewPlayer)
final videoPreviewPlayerProvider = VideoPreviewPlayerFamily._();

final class VideoPreviewPlayerProvider extends $FunctionalProvider<
        AsyncValue<VideoPreviewPlayer>,
        VideoPreviewPlayer,
        FutureOr<VideoPreviewPlayer>>
    with
        $FutureModifier<VideoPreviewPlayer>,
        $FutureProvider<VideoPreviewPlayer> {
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
    r'9264402ea307d850fde9ba7eb28457a81cd0a30a';

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

  VideoPreviewPlayerProvider call(
    String assetId,
  ) =>
      VideoPreviewPlayerProvider._(argument: assetId, from: this);

  @override
  String toString() => r'videoPreviewPlayerProvider';
}
