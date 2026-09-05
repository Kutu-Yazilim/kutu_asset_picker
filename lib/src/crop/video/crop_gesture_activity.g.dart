// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'crop_gesture_activity.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How many fingers are currently on the crop area.
///
/// A count rather than a bool because a pinch puts two fingers down and lifts
/// them one at a time: on a bool, the first lift would bring the trim bar back
/// mid-pinch.
// keepAlive, like every picker-scoped provider (contract §9): the scope lives
// and dies with the picker route, and an auto-dispose count would reset the
// moment the last widget watching it rebuilt away.

@ProviderFor(CropGestureActivity)
final cropGestureActivityProvider = CropGestureActivityProvider._();

/// How many fingers are currently on the crop area.
///
/// A count rather than a bool because a pinch puts two fingers down and lifts
/// them one at a time: on a bool, the first lift would bring the trim bar back
/// mid-pinch.
// keepAlive, like every picker-scoped provider (contract §9): the scope lives
// and dies with the picker route, and an auto-dispose count would reset the
// moment the last widget watching it rebuilt away.
final class CropGestureActivityProvider
    extends $NotifierProvider<CropGestureActivity, int> {
  /// How many fingers are currently on the crop area.
  ///
  /// A count rather than a bool because a pinch puts two fingers down and lifts
  /// them one at a time: on a bool, the first lift would bring the trim bar back
  /// mid-pinch.
// keepAlive, like every picker-scoped provider (contract §9): the scope lives
// and dies with the picker route, and an auto-dispose count would reset the
// moment the last widget watching it rebuilt away.
  CropGestureActivityProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'cropGestureActivityProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$cropGestureActivityHash();

  @$internal
  @override
  CropGestureActivity create() => CropGestureActivity();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(int value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<int>(value),
    );
  }
}

String _$cropGestureActivityHash() =>
    r'5633a702d37fbba52038b948c16ce4b3bd7749a0';

/// How many fingers are currently on the crop area.
///
/// A count rather than a bool because a pinch puts two fingers down and lifts
/// them one at a time: on a bool, the first lift would bring the trim bar back
/// mid-pinch.
// keepAlive, like every picker-scoped provider (contract §9): the scope lives
// and dies with the picker route, and an auto-dispose count would reset the
// moment the last widget watching it rebuilt away.

abstract class _$CropGestureActivity extends $Notifier<int> {
  int build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<int, int>;
    final element = ref.element
        as $ClassProviderElement<AnyNotifier<int, int>, int, Object?, Object?>;
    return element.handleCreate(ref, build);
  }
}

/// Whether the author is currently moving the footage under the crop window.
///
/// The floating trim bar occludes the bottom of the frame being framed
/// (spec §2.7), so it fades out for exactly this long.

@ProviderFor(cropIsBeingDragged)
final cropIsBeingDraggedProvider = CropIsBeingDraggedProvider._();

/// Whether the author is currently moving the footage under the crop window.
///
/// The floating trim bar occludes the bottom of the frame being framed
/// (spec §2.7), so it fades out for exactly this long.

final class CropIsBeingDraggedProvider
    extends $FunctionalProvider<bool, bool, bool> with $Provider<bool> {
  /// Whether the author is currently moving the footage under the crop window.
  ///
  /// The floating trim bar occludes the bottom of the frame being framed
  /// (spec §2.7), so it fades out for exactly this long.
  CropIsBeingDraggedProvider._()
      : super(
          from: null,
          argument: null,
          retry: null,
          name: r'cropIsBeingDraggedProvider',
          isAutoDispose: false,
          dependencies: null,
          $allTransitiveDependencies: null,
        );

  @override
  String debugGetCreateSourceHash() => _$cropIsBeingDraggedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return cropIsBeingDragged(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$cropIsBeingDraggedHash() =>
    r'a48f7ed6172ccd8ad1b2357c583f12ede3964f6a';
