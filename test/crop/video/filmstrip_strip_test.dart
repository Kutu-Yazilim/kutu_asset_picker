import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/crop/video/filmstrip_frame_tile.dart';
import 'package:kutu_asset_picker/src/crop/video/filmstrip_strip.dart';
import 'package:kutu_asset_picker/src/crop/video/video_crop_constants.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:kutu_media_transform/testing.dart';

import '../../support/picker_test_harness.dart';

void main() {
  const info = VideoInfo(
    duration: Duration(seconds: 12),
    codedWidth: 1920,
    codedHeight: 1080,
    rotationDegrees: 0,
    isHdr: false,
    hasAudio: true,
  );

  // A one-pixel opaque PNG, so Image.memory has something real to decode.
  const onePixelPng = <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ];

  testWidgets('shows one tile per extracted frame', (tester) async {
    await pumpStrip(
        tester,
        FakeMediaTransform(
          videoInfo: info,
          frameBytes: onePixelPng,
        ));
    await tester.pump();

    expect(
      find.byType(FilmstripFrameTile),
      findsNWidgets(VideoCropConstants.filmstripFrameCount),
    );
  });

  testWidgets('asks for frames across the whole clip, not the trim range',
      (tester) async {
    final transform = FakeMediaTransform(
      videoInfo: info,
      frameBytes: onePixelPng,
    );
    await pumpStrip(tester, transform);
    await tester.pump();

    expect(transform.frameExtractions.single.times.first,
        lessThan(const Duration(seconds: 1)));
    expect(transform.frameExtractions.single.times.last,
        greaterThan(const Duration(seconds: 11)));
  });

  testWidgets('shows a masked placeholder while frames are still extracting',
      (tester) async {
    await pumpStrip(
        tester,
        FakeMediaTransform(
          videoInfo: info,
          frameBytes: onePixelPng,
        ));

    expect(find.byType(FilmstripFrameTile), findsNothing);
    expect(find.byType(ColoredBox), findsWidgets);
  });

  testWidgets('the tiles share the width equally', (tester) async {
    await pumpStrip(
        tester,
        FakeMediaTransform(
          videoInfo: info,
          frameBytes: onePixelPng,
        ));
    await tester.pump();

    final sizes = tester
        .widgetList<FilmstripFrameTile>(find.byType(FilmstripFrameTile))
        .map((tile) => tester.getSize(find.byWidget(tile)).width)
        .toSet();

    expect(sizes, hasLength(1));
  });
}

Future<void> pumpStrip(
  WidgetTester tester,
  FakeMediaTransform transform,
) =>
    pumpPickerWidget(
      tester,
      const SizedBox(
        width: 300,
        height: VideoCropConstants.filmstripHeight,
        child: FilmstripStrip(
          srcPath: '/tmp/clip.mp4',
          total: Duration(seconds: 12),
        ),
      ),
      config: const AssetPickerConfig(),
      transform: transform,
    );
