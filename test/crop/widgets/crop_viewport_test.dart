import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/src/config/asset_picker_config.dart';
import 'package:kutu_asset_picker/src/config/crop_aspect.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_limits.dart';
import 'package:kutu_asset_picker/src/crop/crop_math.dart';
import 'package:kutu_asset_picker/src/crop/crop_providers.dart';
import 'package:kutu_asset_picker/src/crop/crop_state.dart';
import 'package:kutu_asset_picker/src/crop/fling_duration.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_viewport.dart';
import 'package:kutu_asset_picker/src/providers/injection_providers.dart';

const Size kImage = Size(1000, 500);
const Size kWindow = Size(300, 300);
// scaleToCover(1000x500, 300x300) = 0.6, so the scaled image is 600x300:
// 150 logical px of horizontal slack and none vertically.
const double kMinScale = 0.6;
const double kSlackX = 150;

/// The stored (canonical-frame) state, converted back into layout pixels so a
/// test can reason in the same units it dragged in.
CropState layoutState(ProviderContainer container) {
  final stored = container.read(cropStatesProvider)['a']!;
  return rescaleCropState(
    stored,
    from: cropWindowSize(stored.aspect, kCanonicalCropArea),
    to: kWindow,
  );
}

Future<ProviderContainer> pumpViewport(WidgetTester tester) async {
  final container = ProviderContainer(
    overrides: [
      assetPickerConfigProvider.overrideWithValue(
        const AssetPickerConfig(aspects: [CropAspect.square]),
      ),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: Center(
          child: CropViewport(
            assetId: 'a',
            imageSize: kImage,
            window: kWindow,
            // A plain colour, not an Image: this test is about the gesture
            // math, and a decode would make it depend on real bytes.
            child: ColoredBox(color: Color(0xFF00FF00)),
          ),
        ),
      ),
    ),
  );
  return container;
}

void main() {
  group('flingDuration', () {
    test('is zero for a velocity already at a standstill', () {
      expect(flingDuration(0), 0);
      expect(flingDuration(AssetPickerLimits.flingMotionless), 0);
    });

    test('grows with velocity and stays finite', () {
      final slow = flingDuration(300);
      final fast = flingDuration(3000);

      expect(slow, greaterThan(0));
      expect(fast, greaterThan(slow));
      expect(fast.isFinite, isTrue);
      expect(fast, lessThan(2));
    });
  });

  group('CropViewport', () {
    testWidgets('opens at exactly the cover scale, centred', (tester) async {
      final container = await pumpViewport(tester);

      final transform = tester.widget<Transform>(find.byType(Transform));
      expect(transform.transform.storage[0], closeTo(kMinScale, 1e-9));
      expect(transform.transform.getTranslation().x, closeTo(0, 1e-9));
      // Opening the step writes nothing: the normalization happens at read
      // time, so an untouched asset has no entry at all.
      expect(container.read(cropStatesProvider).containsKey('a'), isFalse);
    });

    testWidgets('a drag pans the image', (tester) async {
      final container = await pumpViewport(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(CropViewport)),
      );

      await gesture.moveBy(const Offset(80, 0));
      await tester.pump();

      expect(layoutState(container).offset.dx, greaterThan(0));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a pan is clamped so no edge enters the window',
        (tester) async {
      final container = await pumpViewport(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(CropViewport)),
      );

      await gesture.moveBy(const Offset(4000, 4000));
      await tester.pump();

      final state = layoutState(container);
      expect(state.offset.dx, closeTo(kSlackX, 1e-6));
      // The image is exactly as tall as the window, so there is no vertical
      // slack at all and the drag must not move it a pixel.
      expect(state.offset.dy, closeTo(0, 1e-6));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a pinch zooms in', (tester) async {
      final container = await pumpViewport(tester);
      final centre = tester.getCenter(find.byType(CropViewport));
      final left = await tester.startGesture(centre - const Offset(20, 0));
      final right = await tester.startGesture(centre + const Offset(20, 0));

      await left.moveBy(const Offset(-40, 0));
      await right.moveBy(const Offset(40, 0));
      await tester.pump();

      expect(layoutState(container).scale, greaterThan(kMinScale));

      await left.up();
      await right.up();
      await tester.pumpAndSettle();
    });

    testWidgets('zoom is clamped between cover and the ceiling',
        (tester) async {
      final container = await pumpViewport(tester);
      final centre = tester.getCenter(find.byType(CropViewport));
      final left = await tester.startGesture(centre - const Offset(4, 0));
      final right = await tester.startGesture(centre + const Offset(4, 0));

      await left.moveBy(const Offset(-2000, 0));
      await right.moveBy(const Offset(2000, 0));
      await tester.pump();

      expect(
        layoutState(container).scale,
        closeTo(kMinScale * AssetPickerLimits.maxZoomFactor, 1e-6),
      );

      await left.up();
      await right.up();
      await tester.pumpAndSettle();
    });

    testWidgets('pinching out never goes below the cover scale',
        (tester) async {
      final container = await pumpViewport(tester);
      final centre = tester.getCenter(find.byType(CropViewport));
      final left = await tester.startGesture(centre - const Offset(100, 0));
      final right = await tester.startGesture(centre + const Offset(100, 0));

      await left.moveBy(const Offset(95, 0));
      await right.moveBy(const Offset(-95, 0));
      await tester.pump();

      expect(layoutState(container).scale, closeTo(kMinScale, 1e-6));

      await left.up();
      await right.up();
      await tester.pumpAndSettle();
    });

    testWidgets('the interaction flag is on during a gesture and off after', (
      tester,
    ) async {
      final container = await pumpViewport(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(CropViewport)),
      );

      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      expect(container.read(cropInteractionProvider), isTrue);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(container.read(cropInteractionProvider), isFalse);
    });

    testWidgets('state is stored in the canonical frame, not layout pixels', (
      tester,
    ) async {
      // The canonical 1:1 window is 1000x1000 against a 300x300 layout window,
      // so the stored scale is 0.6 * (1000/300) = 2.
      final container = await pumpViewport(tester);
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(CropViewport)),
      );

      await gesture.moveBy(const Offset(4000, 0));
      await tester.pump();

      final stored = container.read(cropStatesProvider)['a']!;
      expect(stored.scale, closeTo(2, 1e-6));
      expect(stored.offset.dx, closeTo(kSlackX * 1000 / 300, 1e-4));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a fling stays inside the clamp', (tester) async {
      final container = await pumpViewport(tester);

      await tester.fling(
        find.byType(CropViewport),
        const Offset(200, 0),
        3000,
      );
      await tester.pumpAndSettle();

      final state = layoutState(container);
      expect(state.offset.dx, lessThanOrEqualTo(kSlackX + 1e-6));
      expect(state.offset.dy, closeTo(0, 1e-6));
    });
  });
}
