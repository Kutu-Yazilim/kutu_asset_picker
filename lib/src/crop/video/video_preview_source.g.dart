// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_preview_source.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(videoPreviewSource)
final videoPreviewSourceProvider = VideoPreviewSourceFamily._();

final class VideoPreviewSourceProvider extends $FunctionalProvider<
        AsyncValue<VideoPreviewSource>,
        VideoPreviewSource,
        FutureOr<VideoPreviewSource>>
    with
        $FutureModifier<VideoPreviewSource>,
        $FutureProvider<VideoPreviewSource> {
  VideoPreviewSourceProvider._(
      {required VideoPreviewSourceFamily super.from,
      required String super.argument})
      : super(
          retry: _noRetry,
          name: r'videoPreviewSourceProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$videoPreviewSourceHash();

  @override
  String toString() {
    return r'videoPreviewSourceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<VideoPreviewSource> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<VideoPreviewSource> create(Ref ref) {
    final argument = this.argument as String;
    return videoPreviewSource(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is VideoPreviewSourceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$videoPreviewSourceHash() =>
    r'32150912a5a153ad5e5dcca6a7a954588096aaa8';

final class VideoPreviewSourceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<VideoPreviewSource>, String> {
  VideoPreviewSourceFamily._()
      : super(
          retry: _noRetry,
          name: r'videoPreviewSourceProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  VideoPreviewSourceProvider call(
    String assetId,
  ) =>
      VideoPreviewSourceProvider._(argument: assetId, from: this);

  @override
  String toString() => r'videoPreviewSourceProvider';
}
