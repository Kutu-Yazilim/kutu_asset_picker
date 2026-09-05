// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'filmstrip_frames.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The frames behind the scrubber.
///
/// `photo_manager` thumbnails have no timestamp parameter — you get the
/// platform poster frame and nothing else — so this goes through our own
/// extractor (spec §6.3). Kept alive because on Android every frame is a
/// separate `MediaMetadataRetriever.getFrameAtTime` call and re-running the
/// strip on a rebuild would be visible; the whole cache dies with the picker's
/// `ProviderScope`, which is a short-lived scope by construction.

@ProviderFor(filmstripFrames)
final filmstripFramesProvider = FilmstripFramesFamily._();

/// The frames behind the scrubber.
///
/// `photo_manager` thumbnails have no timestamp parameter — you get the
/// platform poster frame and nothing else — so this goes through our own
/// extractor (spec §6.3). Kept alive because on Android every frame is a
/// separate `MediaMetadataRetriever.getFrameAtTime` call and re-running the
/// strip on a rebuild would be visible; the whole cache dies with the picker's
/// `ProviderScope`, which is a short-lived scope by construction.

final class FilmstripFramesProvider extends $FunctionalProvider<
        AsyncValue<List<Uint8List>>, List<Uint8List>, FutureOr<List<Uint8List>>>
    with $FutureModifier<List<Uint8List>>, $FutureProvider<List<Uint8List>> {
  /// The frames behind the scrubber.
  ///
  /// `photo_manager` thumbnails have no timestamp parameter — you get the
  /// platform poster frame and nothing else — so this goes through our own
  /// extractor (spec §6.3). Kept alive because on Android every frame is a
  /// separate `MediaMetadataRetriever.getFrameAtTime` call and re-running the
  /// strip on a rebuild would be visible; the whole cache dies with the picker's
  /// `ProviderScope`, which is a short-lived scope by construction.
  FilmstripFramesProvider._(
      {required FilmstripFramesFamily super.from,
      required FilmstripRequest super.argument})
      : super(
          retry: null,
          name: r'filmstripFramesProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$filmstripFramesHash();

  @override
  String toString() {
    return r'filmstripFramesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Uint8List>> $createElement(
          $ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Uint8List>> create(Ref ref) {
    final argument = this.argument as FilmstripRequest;
    return filmstripFrames(
      ref,
      argument,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is FilmstripFramesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filmstripFramesHash() => r'5e5e9bcf91422230ba732f0bb6a92e1b5f06a98c';

/// The frames behind the scrubber.
///
/// `photo_manager` thumbnails have no timestamp parameter — you get the
/// platform poster frame and nothing else — so this goes through our own
/// extractor (spec §6.3). Kept alive because on Android every frame is a
/// separate `MediaMetadataRetriever.getFrameAtTime` call and re-running the
/// strip on a rebuild would be visible; the whole cache dies with the picker's
/// `ProviderScope`, which is a short-lived scope by construction.

final class FilmstripFramesFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<List<Uint8List>>, FilmstripRequest> {
  FilmstripFramesFamily._()
      : super(
          retry: null,
          name: r'filmstripFramesProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: false,
        );

  /// The frames behind the scrubber.
  ///
  /// `photo_manager` thumbnails have no timestamp parameter — you get the
  /// platform poster frame and nothing else — so this goes through our own
  /// extractor (spec §6.3). Kept alive because on Android every frame is a
  /// separate `MediaMetadataRetriever.getFrameAtTime` call and re-running the
  /// strip on a rebuild would be visible; the whole cache dies with the picker's
  /// `ProviderScope`, which is a short-lived scope by construction.

  FilmstripFramesProvider call(
    FilmstripRequest request,
  ) =>
      FilmstripFramesProvider._(argument: request, from: this);

  @override
  String toString() => r'filmstripFramesProvider';
}
