import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_asset_image.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_viewport.dart';
import 'package:kutu_asset_picker/src/crop/widgets/image_crop_surface.dart';
import 'package:kutu_asset_picker/testing.dart';

void main() {
  final photo = PickerAsset(
    id: 'a',
    type: PickerMediaType.image,
    width: 1000,
    height: 500,
    createdAt: DateTime.utc(2026, 8, 4),
  );

  Future<void> pumpSurface(WidgetTester tester, Size window) async {
    final source = FakeAssetSource();
    addTearDown(source.dispose);
    final container = ProviderContainer(
      overrides: [
        assetPickerConfigProvider.overrideWithValue(const AssetPickerConfig()),
        assetSourceProvider.overrideWithValue(source),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Center(child: ImageCropSurface(asset: photo, window: window)),
        ),
      ),
    );
  }

  testWidgets('hands the window it was given straight to the viewport',
      (tester) async {
    await pumpSurface(tester, const Size(300, 300));

    expect(
      tester.widget<CropViewport>(find.byType(CropViewport)).window,
      const Size(300, 300),
    );
  });

  testWidgets('gives the viewport the asset id and the asset pixel size',
      (tester) async {
    await pumpSurface(tester, const Size(320, 180));

    final viewport = tester.widget<CropViewport>(find.byType(CropViewport));
    expect(viewport.assetId, 'a');
    expect(viewport.imageSize, const Size(1000, 500));
  });

  testWidgets('puts the photo child under the viewport, unchanged',
      (tester) async {
    await pumpSurface(tester, const Size(300, 300));

    expect(
      find.descendant(
        of: find.byType(CropViewport),
        matching: find.byType(CropAssetImage),
      ),
      findsOneWidget,
    );
  });

  group('the export needs no record of the laid-out window', () {
    // toCropRect is invariant under a uniform rescale of window, scale and
    // offset together, which is precisely what rescaleCropState performs. That
    // invariance is why CropState can be stored against kCanonicalCropArea and
    // the export can reconstruct the rect without being told the layout size.
    // 1e-12 rather than exact equality: 1000/300 is not representable in
    // binary, so the two paths agree to double precision, not to the bit.
    const image = Size(1000, 500);

    void expectSameRect(CropState state, Size layoutWindow, CropAspect aspect) {
      final canonicalWindow = cropWindowSize(aspect, kCanonicalCropArea);
      final fromLayout = toCropRect(state, image, layoutWindow);
      final fromCanonical = toCropRect(
        rescaleCropState(state, from: layoutWindow, to: canonicalWindow),
        image,
        canonicalWindow,
      );

      expect(fromCanonical.left, closeTo(fromLayout.left, 1e-12));
      expect(fromCanonical.top, closeTo(fromLayout.top, 1e-12));
      expect(fromCanonical.right, closeTo(fromLayout.right, 1e-12));
      expect(fromCanonical.bottom, closeTo(fromLayout.bottom, 1e-12));
    }

    test('square, panned and zoomed', () {
      const layoutWindow = Size(300, 300);
      expectSameRect(
        CropState(
          aspect: CropAspect.square,
          scale: scaleToCover(image, layoutWindow) * 1.7,
          offset: const Offset(-23.5, 11.25),
        ),
        layoutWindow,
        CropAspect.square,
      );
    });

    test('16:9, a different layout size, a different framing', () {
      const layoutWindow = Size(320, 180);
      expectSameRect(
        CropState(
          aspect: CropAspect.landscape169,
          scale: scaleToCover(image, layoutWindow) * 2.4,
          offset: const Offset(41, -6.75),
        ),
        layoutWindow,
        CropAspect.landscape169,
      );
    });

    test('at rest, with no pan and no zoom', () {
      const layoutWindow = Size(300, 300);
      expectSameRect(
        CropState(
          aspect: CropAspect.square,
          scale: scaleToCover(image, layoutWindow),
          offset: Offset.zero,
        ),
        layoutWindow,
        CropAspect.square,
      );
    });
  });
}
