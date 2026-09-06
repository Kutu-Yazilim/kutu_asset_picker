// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_playback_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Plays the kept range of one video, so the author finds a moment by watching
/// for it instead of guessing from twelve filmstrip thumbnails.
///
/// The rules, in one place:
///
/// - **Play** seeks to the playhead when it is inside the kept range and to the
///   in point otherwise, then polls the platform position every
///   [VideoCropConstants.playbackPollInterval] and loops at the out point. The
///   loop plays again after seeking, because the platform stops at the end of
///   the file and cannot be trusted to still be running.
/// - **Pause** holds the playhead. In trim mode it then seeks the player onto
///   it, so the line on the strip and the frame on screen agree — the poll is
///   up to one interval behind the picture. In cover mode it sets the cover
///   there instead: choosing that frame is the only thing cover mode is for,
///   so pausing is the choice, and the cover's own seek lands the picture.
/// - **A scrub** — any change to the trim state — pauses without moving the
///   playhead and without seeking. The author is positioning by hand now, the
///   handle's own seek shows its frame, and the line stays as the reference
///   they are dragging towards.
///
/// Auto-dispose, against contract §9's keepAlive default, on purpose: the seek
/// target keeps the platform player alive for the whole session, so a muted
/// clip left playing when its controls leave the screen would decode in the
/// background until the picker closed. Disposal pauses it.

@ProviderFor(VideoPlaybackController)
final videoPlaybackControllerProvider = VideoPlaybackControllerFamily._();

/// Plays the kept range of one video, so the author finds a moment by watching
/// for it instead of guessing from twelve filmstrip thumbnails.
///
/// The rules, in one place:
///
/// - **Play** seeks to the playhead when it is inside the kept range and to the
///   in point otherwise, then polls the platform position every
///   [VideoCropConstants.playbackPollInterval] and loops at the out point. The
///   loop plays again after seeking, because the platform stops at the end of
///   the file and cannot be trusted to still be running.
/// - **Pause** holds the playhead. In trim mode it then seeks the player onto
///   it, so the line on the strip and the frame on screen agree — the poll is
///   up to one interval behind the picture. In cover mode it sets the cover
///   there instead: choosing that frame is the only thing cover mode is for,
///   so pausing is the choice, and the cover's own seek lands the picture.
/// - **A scrub** — any change to the trim state — pauses without moving the
///   playhead and without seeking. The author is positioning by hand now, the
///   handle's own seek shows its frame, and the line stays as the reference
///   they are dragging towards.
///
/// Auto-dispose, against contract §9's keepAlive default, on purpose: the seek
/// target keeps the platform player alive for the whole session, so a muted
/// clip left playing when its controls leave the screen would decode in the
/// background until the picker closed. Disposal pauses it.
final class VideoPlaybackControllerProvider
    extends $NotifierProvider<VideoPlaybackController, VideoPlayback> {
  /// Plays the kept range of one video, so the author finds a moment by watching
  /// for it instead of guessing from twelve filmstrip thumbnails.
  ///
  /// The rules, in one place:
  ///
  /// - **Play** seeks to the playhead when it is inside the kept range and to the
  ///   in point otherwise, then polls the platform position every
  ///   [VideoCropConstants.playbackPollInterval] and loops at the out point. The
  ///   loop plays again after seeking, because the platform stops at the end of
  ///   the file and cannot be trusted to still be running.
  /// - **Pause** holds the playhead. In trim mode it then seeks the player onto
  ///   it, so the line on the strip and the frame on screen agree — the poll is
  ///   up to one interval behind the picture. In cover mode it sets the cover
  ///   there instead: choosing that frame is the only thing cover mode is for,
  ///   so pausing is the choice, and the cover's own seek lands the picture.
  /// - **A scrub** — any change to the trim state — pauses without moving the
  ///   playhead and without seeking. The author is positioning by hand now, the
  ///   handle's own seek shows its frame, and the line stays as the reference
  ///   they are dragging towards.
  ///
  /// Auto-dispose, against contract §9's keepAlive default, on purpose: the seek
  /// target keeps the platform player alive for the whole session, so a muted
  /// clip left playing when its controls leave the screen would decode in the
  /// background until the picker closed. Disposal pauses it.
  VideoPlaybackControllerProvider._(
      {required VideoPlaybackControllerFamily super.from,
      required (
        String,
        Duration,
      )
          super.argument})
      : super(
          retry: null,
          name: r'videoPlaybackControllerProvider',
          isAutoDispose: true,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$videoPlaybackControllerHash();

  @override
  String toString() {
    return r'videoPlaybackControllerProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  VideoPlaybackController create() => VideoPlaybackController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoPlayback value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoPlayback>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is VideoPlaybackControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$videoPlaybackControllerHash() =>
    r'ec733a45109ad2f84d70c8e29b864c7d65dcaca5';

/// Plays the kept range of one video, so the author finds a moment by watching
/// for it instead of guessing from twelve filmstrip thumbnails.
///
/// The rules, in one place:
///
/// - **Play** seeks to the playhead when it is inside the kept range and to the
///   in point otherwise, then polls the platform position every
///   [VideoCropConstants.playbackPollInterval] and loops at the out point. The
///   loop plays again after seeking, because the platform stops at the end of
///   the file and cannot be trusted to still be running.
/// - **Pause** holds the playhead. In trim mode it then seeks the player onto
///   it, so the line on the strip and the frame on screen agree — the poll is
///   up to one interval behind the picture. In cover mode it sets the cover
///   there instead: choosing that frame is the only thing cover mode is for,
///   so pausing is the choice, and the cover's own seek lands the picture.
/// - **A scrub** — any change to the trim state — pauses without moving the
///   playhead and without seeking. The author is positioning by hand now, the
///   handle's own seek shows its frame, and the line stays as the reference
///   they are dragging towards.
///
/// Auto-dispose, against contract §9's keepAlive default, on purpose: the seek
/// target keeps the platform player alive for the whole session, so a muted
/// clip left playing when its controls leave the screen would decode in the
/// background until the picker closed. Disposal pauses it.

final class VideoPlaybackControllerFamily extends $Family
    with
        $ClassFamilyOverride<
            VideoPlaybackController,
            VideoPlayback,
            VideoPlayback,
            VideoPlayback,
            (
              String,
              Duration,
            )> {
  VideoPlaybackControllerFamily._()
      : super(
          retry: null,
          name: r'videoPlaybackControllerProvider',
          dependencies: null,
          $allTransitiveDependencies: null,
          isAutoDispose: true,
        );

  /// Plays the kept range of one video, so the author finds a moment by watching
  /// for it instead of guessing from twelve filmstrip thumbnails.
  ///
  /// The rules, in one place:
  ///
  /// - **Play** seeks to the playhead when it is inside the kept range and to the
  ///   in point otherwise, then polls the platform position every
  ///   [VideoCropConstants.playbackPollInterval] and loops at the out point. The
  ///   loop plays again after seeking, because the platform stops at the end of
  ///   the file and cannot be trusted to still be running.
  /// - **Pause** holds the playhead. In trim mode it then seeks the player onto
  ///   it, so the line on the strip and the frame on screen agree — the poll is
  ///   up to one interval behind the picture. In cover mode it sets the cover
  ///   there instead: choosing that frame is the only thing cover mode is for,
  ///   so pausing is the choice, and the cover's own seek lands the picture.
  /// - **A scrub** — any change to the trim state — pauses without moving the
  ///   playhead and without seeking. The author is positioning by hand now, the
  ///   handle's own seek shows its frame, and the line stays as the reference
  ///   they are dragging towards.
  ///
  /// Auto-dispose, against contract §9's keepAlive default, on purpose: the seek
  /// target keeps the platform player alive for the whole session, so a muted
  /// clip left playing when its controls leave the screen would decode in the
  /// background until the picker closed. Disposal pauses it.

  VideoPlaybackControllerProvider call(
    String assetId,
    Duration total,
  ) =>
      VideoPlaybackControllerProvider._(argument: (
        assetId,
        total,
      ), from: this);

  @override
  String toString() => r'videoPlaybackControllerProvider';
}

/// Plays the kept range of one video, so the author finds a moment by watching
/// for it instead of guessing from twelve filmstrip thumbnails.
///
/// The rules, in one place:
///
/// - **Play** seeks to the playhead when it is inside the kept range and to the
///   in point otherwise, then polls the platform position every
///   [VideoCropConstants.playbackPollInterval] and loops at the out point. The
///   loop plays again after seeking, because the platform stops at the end of
///   the file and cannot be trusted to still be running.
/// - **Pause** holds the playhead. In trim mode it then seeks the player onto
///   it, so the line on the strip and the frame on screen agree — the poll is
///   up to one interval behind the picture. In cover mode it sets the cover
///   there instead: choosing that frame is the only thing cover mode is for,
///   so pausing is the choice, and the cover's own seek lands the picture.
/// - **A scrub** — any change to the trim state — pauses without moving the
///   playhead and without seeking. The author is positioning by hand now, the
///   handle's own seek shows its frame, and the line stays as the reference
///   they are dragging towards.
///
/// Auto-dispose, against contract §9's keepAlive default, on purpose: the seek
/// target keeps the platform player alive for the whole session, so a muted
/// clip left playing when its controls leave the screen would decode in the
/// background until the picker closed. Disposal pauses it.

abstract class _$VideoPlaybackController extends $Notifier<VideoPlayback> {
  late final _$args = ref.$arg as (
    String,
    Duration,
  );
  String get assetId => _$args.$1;
  Duration get total => _$args.$2;

  VideoPlayback build(
    String assetId,
    Duration total,
  );
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<VideoPlayback, VideoPlayback>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<VideoPlayback, VideoPlayback>,
        VideoPlayback,
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
