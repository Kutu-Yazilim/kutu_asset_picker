import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/crop/video/floating_video_bar.dart';
import 'package:kutu_asset_picker/src/crop/video/video_crop_error_view.dart';
import 'package:kutu_asset_picker/src/crop/video/video_crop_loading.dart';
import 'package:kutu_asset_picker/src/crop/video/video_crop_stack.dart';
import 'package:kutu_asset_picker/src/crop/video/video_crop_surface.dart';
import 'package:kutu_asset_picker/src/crop/video/video_seek_providers.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_viewport.dart';
import 'package:kutu_asset_picker/testing.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:kutu_media_transform/testing.dart';

import '../../support/fake_seek_target.dart';
import '../../support/picker_test_harness.dart';

void main() {
  const assetId = 'clip-1';
  const surface = Size(360, 480);
  // The window CropStage would lay out for a 1:1 crop inside `surface`. Passed
  // in rather than derived, exactly as the photo branch receives it.
  const window = Size(360, 360);
  const info = VideoInfo(
    duration: Duration(seconds: 30),
    codedWidth: 1920,
    codedHeight: 1080,
    rotationDegrees: 90,
    isHdr: false,
    hasAudio: true,
  );

  late Directory tempDir;
  late File clip;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('kutu_video_crop');
    clip = File('${tempDir.path}/clip.mp4')
      ..writeAsBytesSync(List<int>.filled(2048, 3));
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  FakeAssetSource sourceWith(File file) {
    final source = FakeAssetSource();
    addTearDown(source.dispose);
    source.filesById[assetId] = file;
    return source;
  }

  testWidgets('shows the loading state before the source resolves',
      (tester) async {
    await pumpPickerWidget(
      tester,
      const VideoCropSurface(assetId: assetId, window: window),
      config: const AssetPickerConfig(),
      source: sourceWith(clip),
      transform: FakeMediaTransform(videoInfo: info),
      surfaceSize: surface,
    );

    expect(find.byType(VideoCropLoading), findsOneWidget);
  });

  testWidgets('shows the rejection message when the clip is too long',
      (tester) async {
    await pumpPickerWidget(
      tester,
      const VideoCropSurface(assetId: assetId, window: window),
      config: const AssetPickerConfig(maxVideoDuration: Duration(seconds: 10)),
      source: sourceWith(clip),
      transform: FakeMediaTransform(videoInfo: info),
      surfaceSize: surface,
    );
    await settleIo(tester);

    expect(find.byType(VideoCropErrorView), findsOneWidget);
    expect(
      find.text(
          const AssetPickerTextEn().videoTooLong(const Duration(seconds: 10))),
      findsOneWidget,
    );
  });

  testWidgets(
      'the stack fills its box and the crop window is exactly the '
      'window it was handed — the bar costs it nothing', (tester) async {
    await pumpPickerWidget(
      tester,
      VideoCropStack(
        assetId: assetId,
        preview: (file: clip, info: info, sizeBytes: 2048),
        window: window,
      ),
      config: const AssetPickerConfig(),
      surfaceSize: surface,
      overrides: [
        videoSeekTargetProvider(assetId).overrideWithValue(FakeSeekTarget()),
      ],
    );

    // Spec §2.7: tabbing between a photo and a video must not resize anything.
    // The bar floats over the stack, so it takes no space from the crop area,
    // and the viewport occupies precisely the window CropStage laid out.
    expect(tester.getSize(find.byType(VideoCropStack)), surface);
    expect(tester.getSize(find.byType(CropViewport)), window);
  });

  testWidgets(
      'the trim bar is positioned over the crop area, not stacked under it',
      (tester) async {
    await pumpPickerWidget(
      tester,
      VideoCropStack(
        assetId: assetId,
        preview: (file: clip, info: info, sizeBytes: 2048),
        window: window,
      ),
      config: const AssetPickerConfig(),
      surfaceSize: surface,
      overrides: [
        videoSeekTargetProvider(assetId).overrideWithValue(FakeSeekTarget()),
      ],
    );

    expect(
      find.ancestor(
        of: find.byType(FloatingVideoBar),
        matching: find.byType(Positioned),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.byType(FloatingVideoBar),
        matching: find.byType(Column),
      ),
      findsNothing,
    );
  });

  testWidgets('gives crop_math the ROTATED display size, not the coded one',
      (tester) async {
    await pumpPickerWidget(
      tester,
      VideoCropStack(
        assetId: assetId,
        preview: (file: clip, info: info, sizeBytes: 2048),
        window: window,
      ),
      config: const AssetPickerConfig(),
      surfaceSize: surface,
      overrides: [
        videoSeekTargetProvider(assetId).overrideWithValue(FakeSeekTarget()),
      ],
    );

    final viewport = tester.widget<CropViewport>(find.byType(CropViewport));
    expect(viewport.imageSize, const Size(1080, 1920));
    expect(viewport.window, window);
  });
}

/// The preview provider stats and probes a real file, which only completes on
/// the real event loop; a plain pumpAndSettle would spin on the loading
/// indicator until it timed out.
Future<void> settleIo(WidgetTester tester) async {
  for (var round = 0; round < 4; round += 1) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}
