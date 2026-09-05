import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/src/config/crop_aspect.dart';
import 'package:kutu_asset_picker/src/crop/crop_math.dart';
import 'package:kutu_asset_picker/src/crop/crop_state.dart';

/// Asserts the crop window is fully covered by the image at [state], with no
/// clamping needed to keep the rect inside 0..1.
///
/// `toCropRect` clamps defensively, so a test that only inspected its output
/// could not tell "correct" from "was rescued by the clamp". This recomputes
/// the raw rect and checks it was already legal.
void expectWindowFullyCovered(CropState state, Size image, Size window) {
  final scaled = Size(image.width * state.scale, image.height * state.scale);
  expect(
    scaled.width,
    greaterThanOrEqualTo(window.width - 1e-9),
    reason: 'scaled image is narrower than the window',
  );
  expect(
    scaled.height,
    greaterThanOrEqualTo(window.height - 1e-9),
    reason: 'scaled image is shorter than the window',
  );

  final rawLeft =
      ((scaled.width - window.width) / 2 - state.offset.dx) / scaled.width;
  final rawTop =
      ((scaled.height - window.height) / 2 - state.offset.dy) / scaled.height;

  expect(rawLeft, greaterThanOrEqualTo(-1e-9), reason: 'gap on the left');
  expect(rawTop, greaterThanOrEqualTo(-1e-9), reason: 'gap on the top');
  expect(
    rawLeft + window.width / scaled.width,
    lessThanOrEqualTo(1 + 1e-9),
    reason: 'gap on the right',
  );
  expect(
    rawTop + window.height / scaled.height,
    lessThanOrEqualTo(1 + 1e-9),
    reason: 'gap on the bottom',
  );
  expect(toCropRect(state, image, window).isValid, isTrue);
}

void main() {
  group('scaleToCover', () {
    test('a wider-than-window source is limited by its height', () {
      // 4000x2000 into a 300x300 window: 0.075 would leave the window half
      // empty vertically, so the height ratio wins.
      expect(
        scaleToCover(const Size(4000, 2000), const Size(300, 300)),
        closeTo(0.15, 1e-12),
      );
    });

    test('a taller-than-window source is limited by its width', () {
      expect(
        scaleToCover(const Size(2000, 4000), const Size(300, 300)),
        closeTo(0.15, 1e-12),
      );
    });

    test('a square source in a square window covers exactly', () {
      expect(
        scaleToCover(const Size(1000, 1000), const Size(250, 250)),
        closeTo(0.25, 1e-12),
      );
    });

    test('a non-square window takes whichever axis is tighter', () {
      // 1000x1000 into 300x168.75 (a 16:9 window): width is the binding axis.
      expect(
        scaleToCover(const Size(1000, 1000), const Size(300, 168.75)),
        closeTo(0.3, 1e-12),
      );
      // 1000x1000 into 225x400 (a 9:16 window): height binds.
      expect(
        scaleToCover(const Size(1000, 1000), const Size(225, 400)),
        closeTo(0.4, 1e-12),
      );
    });

    test('degenerate inputs fall back to 1 rather than 0, NaN or infinity', () {
      // A scale of 0 or NaN would propagate into every downstream division.
      expect(scaleToCover(Size.zero, const Size(300, 300)), 1);
      expect(scaleToCover(const Size(1000, 1000), Size.zero), 1);
      expect(scaleToCover(const Size(-10, 100), const Size(300, 300)), 1);
      expect(
          scaleToCover(const Size(double.nan, 100), const Size(300, 300)), 1);
    });
  });

  group('clampOffset', () {
    const image = Size(1000, 500);
    const window = Size(400, 300);
    // At scale 1 the slack is (1000-400)/2 = 300 horizontally and
    // (500-300)/2 = 100 vertically.

    test('leaves an offset that is already inside the slack alone', () {
      expect(
        clampOffset(const Offset(100, 50), 1, image, window),
        const Offset(100, 50),
      );
    });

    test('clamps at the right edge', () {
      expect(
        clampOffset(const Offset(5000, 0), 1, image, window),
        const Offset(300, 0),
      );
    });

    test('clamps at the left edge', () {
      expect(
        clampOffset(const Offset(-5000, 0), 1, image, window),
        const Offset(-300, 0),
      );
    });

    test('clamps at the bottom edge', () {
      expect(
        clampOffset(const Offset(0, 5000), 1, image, window),
        const Offset(0, 100),
      );
    });

    test('clamps at the top edge', () {
      expect(
        clampOffset(const Offset(0, -5000), 1, image, window),
        const Offset(0, -100),
      );
    });

    test('clamps both axes at once', () {
      expect(
        clampOffset(const Offset(-900, 800), 1, image, window),
        const Offset(-300, 100),
      );
    });

    test('scale widens the slack proportionally', () {
      // At scale 2 the scaled image is 2000x1000, so the slack doubles-plus:
      // (2000-400)/2 = 800 and (1000-300)/2 = 350.
      expect(
        clampOffset(const Offset(5000, 5000), 2, image, window),
        const Offset(800, 350),
      );
    });

    test('an image smaller than the window pins to centre', () {
      // Below the cover scale there is no legal pan at all; centring is the
      // only offset that does not open a gap on one side.
      expect(
        clampOffset(const Offset(50, 50), 1, const Size(100, 100), window),
        Offset.zero,
      );
    });
  });

  group('cropWindowSize', () {
    test('fits by width when the ratio is wider than the available box', () {
      expect(
        cropWindowSize(CropAspect.landscape169, const Size(300, 400)),
        const Size(300, 168.75),
      );
    });

    test('fits by height when the ratio is taller than the available box', () {
      expect(
        cropWindowSize(CropAspect.story916, const Size(300, 400)),
        const Size(225, 400),
      );
    });

    test('a square ratio in a square box fills it', () {
      expect(
        cropWindowSize(CropAspect.square, const Size(400, 400)),
        const Size(400, 400),
      );
    });

    test('a degenerate box produces a degenerate window rather than NaN', () {
      expect(cropWindowSize(CropAspect.square, Size.zero), Size.zero);
      expect(cropWindowSize(CropAspect.square, const Size(-5, 10)), Size.zero);
    });
  });

  group('toCropRect', () {
    test('a centred wider-than-window source yields the middle band', () {
      const image = Size(4000, 2000);
      const window = Size(300, 300);
      const state = CropState(
        aspect: CropAspect.square,
        scale: 0.15,
        offset: Offset.zero,
      );

      final rect = toCropRect(state, image, window);

      expect(rect.left, closeTo(0.25, 1e-12));
      expect(rect.right, closeTo(0.75, 1e-12));
      expect(rect.top, closeTo(0, 1e-12));
      expect(rect.bottom, closeTo(1, 1e-12));
    });

    test('a centred taller-than-window source yields the middle band', () {
      const image = Size(2000, 4000);
      const window = Size(300, 300);
      const state = CropState(
        aspect: CropAspect.square,
        scale: 0.15,
        offset: Offset.zero,
      );

      final rect = toCropRect(state, image, window);

      expect(rect.left, closeTo(0, 1e-12));
      expect(rect.right, closeTo(1, 1e-12));
      expect(rect.top, closeTo(0.25, 1e-12));
      expect(rect.bottom, closeTo(0.75, 1e-12));
    });

    test('a positive offset moves the crop rect towards the origin', () {
      // Dragging the image right and down reveals its top-left, so the rect
      // that survives is the top-left one. Getting this sign backwards is the
      // single easiest way to ship a mirrored crop.
      const image = Size(1000, 1000);
      const window = Size(300, 300);
      const state = CropState(
        aspect: CropAspect.square,
        scale: 0.6,
        offset: Offset(150, 150),
      );

      final rect = toCropRect(state, image, window);

      expect(rect.left, closeTo(0, 1e-12));
      expect(rect.top, closeTo(0, 1e-12));
      expect(rect.right, closeTo(0.5, 1e-12));
      expect(rect.bottom, closeTo(0.5, 1e-12));
    });

    test('zooming in shrinks the rect around the same centre', () {
      const image = Size(1000, 1000);
      const window = Size(300, 300);

      final atCover = toCropRect(
        const CropState(
          aspect: CropAspect.square,
          scale: 0.3,
          offset: Offset.zero,
        ),
        image,
        window,
      );
      final zoomed = toCropRect(
        const CropState(
          aspect: CropAspect.square,
          scale: 0.6,
          offset: Offset.zero,
        ),
        image,
        window,
      );

      expect(atCover.width, closeTo(1, 1e-12));
      expect(zoomed.width, closeTo(0.5, 1e-12));
      expect(zoomed.left, closeTo(0.25, 1e-12));
    });

    test('a degenerate state produces a full rect rather than NaN', () {
      expect(
        toCropRect(
          const CropState.unsized(CropAspect.square),
          const Size(1000, 1000),
          const Size(300, 300),
        ).isFull,
        isTrue,
      );
    });
  });

  group('reclampForAspect', () {
    const image = Size(1000, 1000);
    const available = Size(300, 400);

    test('normalizes an unsized state to exactly the cover scale, centred', () {
      const state = CropState.unsized(CropAspect.square);
      final window = cropWindowSize(CropAspect.square, available);

      final next = reclampForAspect(state, image, window, CropAspect.square);

      expect(next.scale, closeTo(0.3, 1e-12));
      expect(next.offset, Offset.zero);
      expectWindowFullyCovered(next, image, window);
    });

    test(
      'rule 3: zoomed in at 1:1, switching to 16:9 never reveals a gap',
      () {
        // Zoom to 2x cover and pan hard into the bottom-right corner.
        final squareWindow = cropWindowSize(CropAspect.square, available);
        const zoomed = CropState(
          aspect: CropAspect.square,
          scale: 0.6,
          offset: Offset(150, 150),
        );
        expectWindowFullyCovered(zoomed, image, squareWindow);

        final wideWindow = cropWindowSize(CropAspect.landscape169, available);
        final next = reclampForAspect(
          zoomed,
          image,
          wideWindow,
          CropAspect.landscape169,
        );

        expect(next.aspect, CropAspect.landscape169);
        // minScale for the wider, shorter window is lower, so the zoom is kept.
        expect(next.scale, closeTo(0.6, 1e-12));
        // The horizontal pan was already at its limit and stays there; the
        // vertical limit grew, so 150 is still legal.
        expect(next.offset, const Offset(150, 150));
        expectWindowFullyCovered(next, image, wideWindow);

        final rect = toCropRect(next, image, wideWindow);
        expect(rect.left, closeTo(0, 1e-12));
        expect(rect.right, closeTo(0.5, 1e-12));
        expect(rect.top, closeTo(0.109375, 1e-12));
        expect(rect.bottom, closeTo(0.390625, 1e-12));
      },
    );

    test('rule 3: a taller window raises the scale before re-clamping', () {
      final wideWindow = cropWindowSize(CropAspect.landscape169, available);
      final atCover = CropState(
        aspect: CropAspect.landscape169,
        scale: scaleToCover(image, wideWindow),
        offset: Offset.zero,
      );
      expect(atCover.scale, closeTo(0.3, 1e-12));

      final tallWindow = cropWindowSize(CropAspect.story916, available);
      final next = reclampForAspect(
        atCover,
        image,
        tallWindow,
        CropAspect.story916,
      );

      // 0.3 would leave the 400 px tall window 100 px short, so the scale is
      // raised to 0.4 FIRST and only then is the offset re-clamped. Doing it
      // the other way round is what produces a one-frame gap.
      expect(next.scale, closeTo(0.4, 1e-12));
      expectWindowFullyCovered(next, image, tallWindow);

      final rect = toCropRect(next, image, tallWindow);
      expect(rect.left, closeTo(0.21875, 1e-12));
      expect(rect.right, closeTo(0.78125, 1e-12));
      expect(rect.top, closeTo(0, 1e-12));
      expect(rect.bottom, closeTo(1, 1e-12));
    });

    test('rule 3: an out-of-range pan is pulled back to the new limit', () {
      final tallWindow = cropWindowSize(CropAspect.story916, available);
      const panned = CropState(
        aspect: CropAspect.landscape169,
        scale: 0.4,
        offset: Offset(0, 200),
      );

      final next = reclampForAspect(
        panned,
        image,
        tallWindow,
        CropAspect.story916,
      );

      // Scaled image is 400x400 and the window is 225x400, so there is no
      // vertical slack at all.
      expect(next.offset, Offset.zero);
      expectWindowFullyCovered(next, image, tallWindow);
    });

    test('a wide source in a tall window keeps its horizontal pan', () {
      const wide = Size(4000, 1000);
      final tallWindow = cropWindowSize(CropAspect.story916, available);
      const state = CropState(
        aspect: CropAspect.square,
        scale: 0.1,
        offset: Offset(1000, 0),
      );

      final next = reclampForAspect(
        state,
        wide,
        tallWindow,
        CropAspect.story916,
      );

      // minScale = max(225/4000, 400/1000) = 0.4, so the scale is raised and
      // the horizontal slack becomes (1600-225)/2 = 687.5.
      expect(next.scale, closeTo(0.4, 1e-12));
      expect(next.offset.dx, closeTo(687.5, 1e-9));
      expectWindowFullyCovered(next, wide, tallWindow);
    });
  });

  group('focalAnchoredOffset', () {
    const window = Size(300, 300);

    test('with no zoom it is a pure pan by the focal delta', () {
      expect(
        focalAnchoredOffset(
          startFocal: const Offset(100, 100),
          focal: const Offset(140, 90),
          startOffset: const Offset(10, 10),
          startScale: 2,
          nextScale: 2,
          window: window,
        ),
        const Offset(50, 0),
      );
    });

    test('a pinch keeps the image point under the fingers', () {
      const startFocal = Offset(100, 100);
      const startOffset = Offset.zero;
      const startScale = 1.0;
      const nextScale = 2.0;

      final next = focalAnchoredOffset(
        startFocal: startFocal,
        focal: startFocal,
        startOffset: startOffset,
        startScale: startScale,
        nextScale: nextScale,
        window: window,
      );

      // Same image point under the focal point before and after.
      const centre = Offset(150, 150);
      final before = (startFocal - centre - startOffset) / startScale;
      final after = (startFocal - centre - next) / nextScale;
      expect(after.dx, closeTo(before.dx, 1e-9));
      expect(after.dy, closeTo(before.dy, 1e-9));
    });

    test('a zero start scale degrades to a pure pan instead of dividing', () {
      expect(
        focalAnchoredOffset(
          startFocal: const Offset(100, 100),
          focal: const Offset(120, 100),
          startOffset: const Offset(5, 5),
          startScale: 0,
          nextScale: 0.3,
          window: window,
        ),
        const Offset(25, 5),
      );
    });
  });

  group('rescaleCropState', () {
    test('the crop rect is identical in a small and a large window', () {
      // This is what makes CropState device-independent: the framing survives
      // a rotation, a different phone, and the jump from layout pixels to the
      // canonical export frame (spec §7.4 invariant 2).
      const image = Size(1000, 1000);
      const smallWindow = Size(300, 300);
      const bigWindow = Size(1000, 1000);
      const state = CropState(
        aspect: CropAspect.square,
        scale: 0.6,
        offset: Offset(150, 150),
      );

      final rescaled =
          rescaleCropState(state, from: smallWindow, to: bigWindow);

      expect(rescaled.scale, closeTo(2, 1e-12));
      expect(rescaled.offset, const Offset(500, 500));

      final a = toCropRect(state, image, smallWindow);
      final b = toCropRect(rescaled, image, bigWindow);
      expect(b.left, closeTo(a.left, 1e-12));
      expect(b.top, closeTo(a.top, 1e-12));
      expect(b.right, closeTo(a.right, 1e-12));
      expect(b.bottom, closeTo(a.bottom, 1e-12));
    });

    test('round-tripping is lossless', () {
      const state = CropState(
        aspect: CropAspect.landscape169,
        scale: 0.42,
        offset: Offset(-17.5, 3.25),
      );

      final there = rescaleCropState(
        state,
        from: const Size(400, 225),
        to: const Size(1000, 562.5),
      );
      final back = rescaleCropState(
        there,
        from: const Size(1000, 562.5),
        to: const Size(400, 225),
      );

      expect(back.scale, closeTo(state.scale, 1e-12));
      expect(back.offset.dx, closeTo(state.offset.dx, 1e-12));
      expect(back.offset.dy, closeTo(state.offset.dy, 1e-12));
    });

    test('an unsized state stays unsized', () {
      final rescaled = rescaleCropState(
        const CropState.unsized(CropAspect.square),
        from: const Size(300, 300),
        to: const Size(1000, 1000),
      );

      expect(rescaled.isUnsized, isTrue);
    });

    test('a degenerate source window is a no-op', () {
      const state = CropState(
        aspect: CropAspect.square,
        scale: 2,
        offset: Offset(1, 2),
      );

      expect(
        rescaleCropState(state, from: Size.zero, to: const Size(300, 300)),
        state,
      );
    });
  });

  group('cropMatrix', () {
    test('is scale on the diagonal and offset in the translation column', () {
      const state = CropState(
        aspect: CropAspect.square,
        scale: 2,
        offset: Offset(10, -4),
      );

      final matrix = cropMatrix(state);

      expect(matrix.storage[0], 2);
      expect(matrix.storage[5], 2);
      expect(matrix.getTranslation().x, 10);
      expect(matrix.getTranslation().y, -4);
    });

    test('maps the image centre to the offset', () {
      const state = CropState(
        aspect: CropAspect.square,
        scale: 3,
        offset: Offset(7, 8),
      );

      final transformed = MatrixUtils.transformPoint(
        cropMatrix(state),
        Offset.zero,
      );

      expect(transformed, const Offset(7, 8));
    });
  });

  test('kCanonicalCropArea is square so no aspect is privileged', () {
    expect(kCanonicalCropArea.width, kCanonicalCropArea.height);
    expect(kCanonicalCropArea.width, greaterThan(0));
  });
}
