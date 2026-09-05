import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/src/config/asset_picker_config.dart';
import 'package:kutu_asset_picker/src/config/picker_enums.dart';
import 'package:kutu_asset_picker/src/crop/crop_providers.dart';
import 'package:kutu_asset_picker/src/crop/crop_window_geometry.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_asset_image.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_dimming_mask.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_thirds_overlay.dart';
import 'package:kutu_asset_picker/src/providers/injection_providers.dart';
import 'package:kutu_asset_picker/src/source/picker_asset.dart';
import 'package:kutu_asset_picker/src/source/picker_media_type.dart';

import '../../support/stub_asset_source.dart';
import '../../support/tiny_png.dart';

void main() {
  group('cropWindowRect', () {
    test('centres the window in the stage', () {
      expect(
        cropWindowRect(const Size(400, 600), const Size(200, 100)),
        const Rect.fromLTRB(100, 250, 300, 350),
      );
    });

    test('a window larger than the stage still centres rather than clipping',
        () {
      expect(
        cropWindowRect(const Size(100, 100), const Size(200, 200)),
        const Rect.fromLTRB(-50, -50, 150, 150),
      );
    });
  });

  group('cropWindowPath', () {
    const rect = Rect.fromLTRB(0, 0, 100, 100);

    test('the rectangle shape includes its corners', () {
      final path = cropWindowPath(rect, CropOverlayShape.rectangle);

      expect(path.contains(const Offset(2, 2)), isTrue);
      expect(path.contains(const Offset(50, 50)), isTrue);
    });

    test('the circle shape excludes the corners it inscribes', () {
      // The avatar case. If this ever passes for a corner the mask has stopped
      // being a circle and become a rounded rectangle.
      final path = cropWindowPath(rect, CropOverlayShape.circle);

      expect(path.contains(const Offset(50, 50)), isTrue);
      expect(path.contains(const Offset(2, 2)), isFalse);
      expect(path.contains(const Offset(98, 98)), isFalse);
    });
  });

  group('CropDimmingMask', () {
    testWidgets('builds for both shapes', (tester) async {
      for (final shape in CropOverlayShape.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Stack(
              children: [
                Positioned.fill(
                  child: CropDimmingMask(
                    window: const Size(200, 200),
                    shape: shape,
                  ),
                ),
              ],
            ),
          ),
        );

        expect(find.byType(CropDimmingMask), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });

  group('CropThirdsOverlay', () {
    Future<ProviderContainer> pumpOverlay(WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Center(child: CropThirdsOverlay(window: Size(200, 200))),
          ),
        ),
      );
      return container;
    }

    testWidgets('is invisible at rest and fades in during interaction', (
      tester,
    ) async {
      // A guide, not decoration: it appears while the author is composing and
      // gets out of the way the moment they let go (spec §6.2).
      final container = await pumpOverlay(tester);

      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0,
      );

      container.read(cropInteractionProvider.notifier).begin();
      await tester.pump();

      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        1,
      );

      container.read(cropInteractionProvider.notifier).end();
      await tester.pump();

      expect(
        tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0,
      );
    });

    testWidgets('never intercepts a pan meant for the image', (tester) async {
      await pumpOverlay(tester);

      // Scoped to the overlay: MaterialApp's own chrome carries IgnorePointers.
      expect(
        find.descendant(
          of: find.byType(CropThirdsOverlay),
          matching: find.byType(IgnorePointer),
        ),
        findsOneWidget,
      );
    });
  });

  group('CropAssetImage', () {
    testWidgets('renders the asset at an aspect-matched preview size', (
      tester,
    ) async {
      final asset = PickerAsset(
        id: 'a',
        type: PickerMediaType.image,
        width: 4000,
        height: 3000,
        createdAt: DateTime.utc(2026, 8, 4),
      );
      final container = ProviderContainer(
        overrides: [
          assetPickerConfigProvider.overrideWithValue(
            const AssetPickerConfig(),
          ),
          assetSourceProvider.overrideWithValue(
            StubAssetSource(thumbnailBytes: tinyPngBytes()),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(home: CropAssetImage(asset: asset)),
        ),
      );
      await tester.pump();

      final image = tester.widget<Image>(find.byType(Image));
      expect(image.fit, BoxFit.fill);
      expect(tester.takeException(), isNull);
    });
  });
}
