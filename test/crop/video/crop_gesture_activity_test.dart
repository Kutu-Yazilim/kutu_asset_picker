import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/crop/video/crop_gesture_activity.dart';
import 'package:kutu_asset_picker/src/crop/video/crop_gesture_activity_detector.dart';

import '../../support/picker_test_harness.dart';

void main() {
  testWidgets('is idle before anything is touched', (tester) async {
    final container = await pumpPickerWidget(
      tester,
      const CropGestureActivityDetector(
        child: ColoredBox(color: Color(0xFF000000), child: SizedBox.expand()),
      ),
      config: const AssetPickerConfig(),
    );

    expect(container.read(cropIsBeingDraggedProvider), isFalse);
  });

  testWidgets('reports a drag between pointer down and pointer up',
      (tester) async {
    final container = await pumpPickerWidget(
      tester,
      const CropGestureActivityDetector(
        child: ColoredBox(color: Color(0xFF000000), child: SizedBox.expand()),
      ),
      config: const AssetPickerConfig(),
    );

    final gesture = await tester.startGesture(tester.getCenter(_box));
    await tester.pump();
    expect(container.read(cropIsBeingDraggedProvider), isTrue);

    await gesture.up();
    await tester.pump();
    expect(container.read(cropIsBeingDraggedProvider), isFalse);
  });

  testWidgets('stays dragging until the LAST finger of a pinch lifts',
      (tester) async {
    final container = await pumpPickerWidget(
      tester,
      const CropGestureActivityDetector(
        child: ColoredBox(color: Color(0xFF000000), child: SizedBox.expand()),
      ),
      config: const AssetPickerConfig(),
    );

    final centre = tester.getCenter(_box);
    final first = await tester.startGesture(centre - const Offset(40, 0));
    final second = await tester.startGesture(centre + const Offset(40, 0));
    await tester.pump();
    expect(container.read(cropGestureActivityProvider), 2);

    await first.up();
    await tester.pump();
    expect(container.read(cropIsBeingDraggedProvider), isTrue);

    await second.up();
    await tester.pump();
    expect(container.read(cropIsBeingDraggedProvider), isFalse);
  });

  testWidgets('a cancelled pointer releases the drag', (tester) async {
    final container = await pumpPickerWidget(
      tester,
      const CropGestureActivityDetector(
        child: ColoredBox(color: Color(0xFF000000), child: SizedBox.expand()),
      ),
      config: const AssetPickerConfig(),
    );

    final gesture = await tester.startGesture(tester.getCenter(_box));
    await tester.pump();
    await gesture.cancel();
    await tester.pump();

    expect(container.read(cropIsBeingDraggedProvider), isFalse);
  });

  testWidgets('does not swallow the gesture from a child recognizer',
      (tester) async {
    var childTaps = 0;
    await pumpPickerWidget(
      tester,
      CropGestureActivityDetector(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => childTaps++,
          child: const ColoredBox(
            color: Color(0xFF000000),
            child: SizedBox.expand(),
          ),
        ),
      ),
      config: const AssetPickerConfig(),
    );

    await tester.tap(_box);
    await tester.pump();

    expect(childTaps, 1);
  });

  testWidgets('an unbalanced pointer up cannot drive the count negative',
      (tester) async {
    final container = await pumpPickerWidget(
      tester,
      const CropGestureActivityDetector(
        child: ColoredBox(color: Color(0xFF000000), child: SizedBox.expand()),
      ),
      config: const AssetPickerConfig(),
    );

    container.read(cropGestureActivityProvider.notifier)
      ..pointerUp()
      ..pointerUp();

    expect(container.read(cropGestureActivityProvider), 0);
    expect(container.read(cropIsBeingDraggedProvider), isFalse);
  });

  testWidgets('reset clears a stuck count', (tester) async {
    final container = await pumpPickerWidget(
      tester,
      const CropGestureActivityDetector(
        child: ColoredBox(color: Color(0xFF000000), child: SizedBox.expand()),
      ),
      config: const AssetPickerConfig(),
    );

    final notifier = container.read(cropGestureActivityProvider.notifier)
      ..pointerUp()
      ..pointerDown()
      ..pointerDown();
    expect(container.read(cropGestureActivityProvider), 2);

    notifier.reset();
    expect(container.read(cropGestureActivityProvider), 0);
  });
}

/// The harness paints its own transparent ColoredBox behind the widget under
/// test, so the finder is scoped to the detector's subtree.
final Finder _box = find.descendant(
  of: find.byType(CropGestureActivityDetector),
  matching: find.byType(ColoredBox),
);
