import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'crop_gesture_activity.g.dart';

/// How many fingers are currently on the crop area.
///
/// A count rather than a bool because a pinch puts two fingers down and lifts
/// them one at a time: on a bool, the first lift would bring the trim bar back
/// mid-pinch.
// keepAlive, like every picker-scoped provider (contract §9): the scope lives
// and dies with the picker route, and an auto-dispose count would reset the
// moment the last widget watching it rebuilt away.
@Riverpod(keepAlive: true)
class CropGestureActivity extends _$CropGestureActivity {
  @override
  int build() => 0;

  void pointerDown() => state = state + 1;

  /// Clamped at zero: a pointer that went down before this mounted would
  /// otherwise leave the bar faded out forever.
  void pointerUp() => state = state > 0 ? state - 1 : 0;

  void reset() => state = 0;
}

/// Whether the author is currently moving the footage under the crop window.
///
/// The floating trim bar occludes the bottom of the frame being framed
/// (spec §2.7), so it fades out for exactly this long.
@Riverpod(keepAlive: true)
bool cropIsBeingDragged(Ref ref) => ref.watch(cropGestureActivityProvider) > 0;
