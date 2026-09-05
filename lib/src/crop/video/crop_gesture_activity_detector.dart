import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'crop_gesture_activity.dart';

/// Reports pointers over the crop area without competing for them.
///
/// [Listener] observes raw pointer events and never enters the gesture arena,
/// so slice 4's scale recognizer inside [child] is completely unaffected — no
/// arena contention, no changed drag behaviour, and not one line of the crop
/// gesture code touched.
class CropGestureActivityDetector extends ConsumerWidget {
  const CropGestureActivityDetector({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Listener(
        onPointerDown: (_) =>
            ref.read(cropGestureActivityProvider.notifier).pointerDown(),
        onPointerUp: (_) =>
            ref.read(cropGestureActivityProvider.notifier).pointerUp(),
        onPointerCancel: (_) =>
            ref.read(cropGestureActivityProvider.notifier).pointerUp(),
        child: child,
      );
}
