// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'selection_attempt.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The guarded front door to selection.
///
/// Every cell tap goes through here rather than straight to `Selection`, so a
/// refusal happens where the author is looking — in the grid, on tap — instead
/// of surfacing minutes later at upload (spec §10).
///
/// State is the last rejection, or null.
// keepAlive (contract §9): a banner that vanished because its notifier was
// collected between the tap and the next frame would be a flaky banner.

@ProviderFor(SelectionAttempt)
final selectionAttemptProvider = SelectionAttemptProvider._();

/// The guarded front door to selection.
///
/// Every cell tap goes through here rather than straight to `Selection`, so a
/// refusal happens where the author is looking — in the grid, on tap — instead
/// of surfacing minutes later at upload (spec §10).
///
/// State is the last rejection, or null.
// keepAlive (contract §9): a banner that vanished because its notifier was
// collected between the tap and the next frame would be a flaky banner.
final class SelectionAttemptProvider
    extends $NotifierProvider<SelectionAttempt, VideoRejection?> {
  /// The guarded front door to selection.
  ///
  /// Every cell tap goes through here rather than straight to `Selection`, so a
  /// refusal happens where the author is looking — in the grid, on tap — instead
  /// of surfacing minutes later at upload (spec §10).
  ///
  /// State is the last rejection, or null.
// keepAlive (contract §9): a banner that vanished because its notifier was
// collected between the tap and the next frame would be a flaky banner.
  SelectionAttemptProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'selectionAttemptProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$selectionAttemptHash();

  @$internal
  @override
  SelectionAttempt create() => SelectionAttempt();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(VideoRejection? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<VideoRejection?>(value),
    );
  }
}

String _$selectionAttemptHash() => r'd0609b83b67fff70201f1f8dc04b616469f9eabd';

/// The guarded front door to selection.
///
/// Every cell tap goes through here rather than straight to `Selection`, so a
/// refusal happens where the author is looking — in the grid, on tap — instead
/// of surfacing minutes later at upload (spec §10).
///
/// State is the last rejection, or null.
// keepAlive (contract §9): a banner that vanished because its notifier was
// collected between the tap and the next frame would be a flaky banner.

abstract class _$SelectionAttempt extends $Notifier<VideoRejection?> {
  VideoRejection? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<VideoRejection?, VideoRejection?>;
    final element = ref.element as $ClassProviderElement<
        AnyNotifier<VideoRejection?, VideoRejection?>,
        VideoRejection?,
        Object?,
        Object?>;
    return element.handleCreate(ref, build);
  }
}
