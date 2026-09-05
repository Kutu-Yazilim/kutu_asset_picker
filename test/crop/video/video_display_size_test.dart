import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/src/config/crop_aspect.dart';
import 'package:kutu_asset_picker/src/crop/crop_math.dart';
import 'package:kutu_asset_picker/src/crop/crop_state.dart';
import 'package:kutu_asset_picker/src/crop/video/video_display_size.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

void main() {
  group('videoDisplaySize', () {
    test('is the coded size when the track is upright', () {
      const info = VideoInfo(
        duration: Duration(seconds: 12),
        codedWidth: 1920,
        codedHeight: 1080,
        rotationDegrees: 0,
        isHdr: false,
        hasAudio: true,
      );

      expect(videoDisplaySize(info), const Size(1920, 1080));
    });

    test('swaps the axes for a quarter-turn rotation tag', () {
      const info = VideoInfo(
        duration: Duration(seconds: 12),
        codedWidth: 1920,
        codedHeight: 1080,
        rotationDegrees: 90,
        isHdr: false,
        hasAudio: true,
      );

      expect(videoDisplaySize(info), const Size(1080, 1920));
    });

    test('swaps the axes for 270 too, and leaves 180 alone', () {
      const base = VideoInfo(
        duration: Duration(seconds: 12),
        codedWidth: 1920,
        codedHeight: 1080,
        rotationDegrees: 270,
        isHdr: false,
        hasAudio: true,
      );
      const halfTurn = VideoInfo(
        duration: Duration(seconds: 12),
        codedWidth: 1920,
        codedHeight: 1080,
        rotationDegrees: 180,
        isHdr: false,
        hasAudio: true,
      );

      expect(videoDisplaySize(base), const Size(1080, 1920));
      expect(videoDisplaySize(halfTurn), const Size(1920, 1080));
    });
  });

  group('videoSizesAgree', () {
    test('tolerates a one-pixel disagreement and rejects more', () {
      expect(videoSizesAgree(const Size(1080, 1920), const Size(1080, 1921)),
          isTrue);
      expect(videoSizesAgree(const Size(1080, 1920), const Size(1080, 1924)),
          isFalse);
    });
  });

  group('crop-math parity between the photo path and the video path', () {
    // A rotated 1080x1920 video and a 1080x1920 still must be indistinguishable
    // to crop_math: the player is just a widget under the same Transform stack,
    // so identical scale/offset/window MUST yield an identical CropRect.
    const rotatedPortraitVideo = VideoInfo(
      duration: Duration(seconds: 9),
      codedWidth: 1920,
      codedHeight: 1080,
      rotationDegrees: 90,
      isHdr: false,
      hasAudio: true,
    );
    const stillSize = Size(1080, 1920);

    test('produces the same CropRect at rest', () {
      const window = Size(300, 300);
      final state = CropState(
        aspect: CropAspect.square,
        scale: scaleToCover(stillSize, window),
        offset: Offset.zero,
      );

      expect(
        toCropRect(state, videoDisplaySize(rotatedPortraitVideo), window),
        toCropRect(state, stillSize, window),
      );
    });

    test('produces the same CropRect after a pan and a zoom', () {
      const window = Size(320, 180);
      final state = CropState(
        aspect: CropAspect.landscape169,
        scale: scaleToCover(stillSize, window) * 1.8,
        offset: const Offset(-37.5, 12.25),
      );

      expect(
        toCropRect(state, videoDisplaySize(rotatedPortraitVideo), window),
        toCropRect(state, stillSize, window),
      );
    });

    test('agrees through cropWindowSize, so the whole chain is shared', () {
      const available = Size(360, 480);
      final window = cropWindowSize(CropAspect.square, available);
      final state = CropState(
        aspect: CropAspect.square,
        scale: scaleToCover(stillSize, window) * 1.35,
        offset: const Offset(11, -4),
      );

      expect(
        toCropRect(state, videoDisplaySize(rotatedPortraitVideo), window),
        toCropRect(state, stillSize, window),
      );
    });
  });
}
