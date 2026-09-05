import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/src/config/crop_aspect.dart';
import 'package:kutu_asset_picker/src/crop/crop_state.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

void main() {
  group('CropState', () {
    test('is value-comparable', () {
      // Storing scale + offset instead of a Matrix4 is what makes this
      // possible, and it is why every clamp is unit-testable (contract §6).
      const a = CropState(
        aspect: CropAspect.square,
        scale: 2,
        offset: Offset(10, -4),
      );
      const b = CropState(
        aspect: CropAspect.square,
        scale: 2,
        offset: Offset(10, -4),
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differs when any single field differs', () {
      const base = CropState(
        aspect: CropAspect.square,
        scale: 2,
        offset: Offset.zero,
      );

      expect(base == base.copyWith(scale: 2.5), isFalse);
      expect(base == base.copyWith(offset: const Offset(1, 0)), isFalse);
      expect(base == base.copyWith(aspect: CropAspect.story916), isFalse);
      expect(
        base ==
            base.copyWith(
              trim: const DurationRange(
                start: Duration.zero,
                end: Duration(seconds: 3),
              ),
            ),
        isFalse,
      );
      expect(
        base == base.copyWith(coverAt: const Duration(seconds: 1)),
        isFalse,
      );
    });

    test('copyWith leaves unnamed fields alone', () {
      const base = CropState(
        aspect: CropAspect.landscape169,
        scale: 3,
        offset: Offset(5, 6),
        coverAt: Duration(seconds: 2),
      );

      final next = base.copyWith(scale: 4);

      expect(next.scale, 4);
      expect(next.aspect, CropAspect.landscape169);
      expect(next.offset, const Offset(5, 6));
      expect(next.coverAt, const Duration(seconds: 2));
    });

    test('unsized marks a state that has not met a layout yet', () {
      const state = CropState.unsized(CropAspect.square);

      // Scale 0 is below every real cover scale, so the first reclamp raises it
      // to exactly `scaleToCover` — which is how a freshly selected asset gets
      // its opening framing without anyone writing to a provider during layout.
      expect(state.scale, 0);
      expect(state.offset, Offset.zero);
      expect(state.isUnsized, isTrue);
      expect(
        const CropState(
          aspect: CropAspect.square,
          scale: 1,
          offset: Offset.zero,
        ).isUnsized,
        isFalse,
      );
    });

    test('video fields default to null for a photo', () {
      const state = CropState.unsized(CropAspect.square);

      expect(state.trim, isNull);
      expect(state.coverAt, isNull);
    });
  });
}
