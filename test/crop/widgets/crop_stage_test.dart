import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_sizes.dart';
import 'package:kutu_asset_picker/src/crop/video/video_bar_slot.dart';
import 'package:kutu_asset_picker/src/crop/video/video_control_bar.dart';
import 'package:kutu_asset_picker/src/crop/video/video_seek_providers.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_dimming_mask.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_stage.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_thirds_overlay.dart';
import 'package:kutu_asset_picker/testing.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:kutu_media_transform/testing.dart';

import '../../support/fake_seek_target.dart';
import '../../support/picker_test_harness.dart';

const videoId = 'clip-1';
const photoId = 'photo-1';
// The harness box; the stage insets `cropStageInset` on every side of it.
const surface = Size(360, 480);
const info = VideoInfo(
  duration: Duration(seconds: 30),
  codedWidth: 1920,
  codedHeight: 1080,
  rotationDegrees: 0,
  isHdr: false,
  hasAudio: true,
);

PickerAsset photo() => PickerAsset(
      id: photoId,
      type: PickerMediaType.image,
      width: 1000,
      height: 500,
      createdAt: DateTime.utc(2026, 8, 4),
    );

PickerAsset video() => PickerAsset(
      id: videoId,
      type: PickerMediaType.video,
      width: 1920,
      height: 1080,
      createdAt: DateTime.utc(2026, 8, 4),
      duration: info.duration,
    );

/// Slice 3's ordered selection, pinned to a fixed list.
///
/// It overrides `selectedAssets` as well as `build`: the real notifier resolves
/// that getter through the registry `toggleAsset` fills, and this double never
/// sees a tap.
class _FixedSelection extends Selection {
  _FixedSelection(this.assets);
  final List<PickerAsset> assets;
  @override
  List<String> build() => [for (final asset in assets) asset.id];
  @override
  List<PickerAsset> get selectedAssets => assets;
}

late Directory tempDir;
late File clip;

Future<void> pumpStage(
  WidgetTester tester, {
  required PickerAsset focused,
  required List<PickerAsset> selection,
  CropAspect aspect = CropAspect.square,
}) async {
  final source = FakeAssetSource();
  addTearDown(source.dispose);
  source.filesById[videoId] = clip;
  final transform = FakeMediaTransform(videoInfo: info);
  addTearDown(transform.dispose);

  await pumpPickerWidget(
    tester,
    CropStage(asset: focused),
    config: AssetPickerConfig(aspects: [aspect]),
    source: source,
    transform: transform,
    surfaceSize: surface,
    overrides: [
      selectionProvider.overrideWith(() => _FixedSelection(selection)),
      videoSeekTargetProvider(videoId).overrideWithValue(FakeSeekTarget()),
    ],
  );
  await settleIo(tester);
}

/// Riverpod schedules an auto-dispose on a zero-length timer when a consumer
/// unmounts; the framework's own end-of-test unmount happens after fake time
/// stops advancing, so a test that replaced a tree ends with one pending.
Future<void> unmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  // pump() only flushes microtasks; the zero-length timer needs fake time.
  await tester.pumpAndSettle();
}

/// The preview provider stats and probes a real file, which only completes on
/// the real event loop.
Future<void> settleIo(WidgetTester tester) async {
  for (var round = 0; round < 4; round += 1) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump();
  }
}

void main() {
  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('kutu_crop_stage');
    clip = File('${tempDir.path}/clip.mp4')
      ..writeAsBytesSync(List<int>.filled(2048, 3));
  });

  tearDown(() => tempDir.deleteSync(recursive: true));

  testWidgets('THE VIDEO BAR SITS BELOW THE CROP WINDOW, NEVER OVER IT', (
    tester,
  ) async {
    // The bar used to be `Positioned` at the bottom of the stage while the
    // window was centred in that same stage, so any window tall enough to reach
    // the bottom — 1:1 on a phone, every 9:16 — had its lower edge covered by
    // the controls that were meant to sit beside it.
    await pumpStage(tester, focused: video(), selection: [video()]);

    final Rect window = tester.getRect(find.byType(CropThirdsOverlay));
    final Rect bar = tester.getRect(find.byType(VideoControlBar));
    expect(bar.top, greaterThanOrEqualTo(window.bottom));
    expect(
      bar.bottom,
      lessThanOrEqualTo(tester.getRect(find.byType(CropStage)).bottom),
    );
    await unmount(tester);
  });

  testWidgets('a photo and a video in one session get the same window', (
    tester,
  ) async {
    // Spec §2.7: the crop area must not resize as the author tabs between a
    // photo and a video. The band under the window is reserved for every asset
    // in a session that contains a video — empty under the photo.
    await pumpStage(
      tester,
      focused: photo(),
      selection: [photo(), video()],
      aspect: CropAspect.story916,
    );
    final Size underPhoto = tester.getSize(find.byType(CropThirdsOverlay));
    expect(find.byType(VideoBarSlot), findsOneWidget);
    expect(find.byType(VideoControlBar), findsNothing);

    await pumpStage(
      tester,
      focused: video(),
      selection: [photo(), video()],
      aspect: CropAspect.story916,
    );

    expect(tester.getSize(find.byType(CropThirdsOverlay)), underPhoto);
    expect(find.byType(VideoControlBar), findsOneWidget);
    await unmount(tester);
  });

  testWidgets('a photo-only session reserves nothing', (tester) async {
    await pumpStage(
      tester,
      focused: photo(),
      selection: [photo(), video()],
      aspect: CropAspect.story916,
    );
    final double shared = tester.getSize(find.byType(CropThirdsOverlay)).height;

    await pumpStage(
      tester,
      focused: photo(),
      selection: [photo()],
      aspect: CropAspect.story916,
    );

    expect(find.byType(VideoBarSlot), findsNothing);
    expect(
      tester.getSize(find.byType(CropThirdsOverlay)).height,
      greaterThan(shared),
    );
    await unmount(tester);
  });

  testWidgets('the mask spans the whole stage even when the window is narrower',
      (tester) async {
    // 9:16 in a 328×448 stage is height-limited and 252 wide. The mask must
    // still dim all 328, or the bands beside a narrow window would be the plain
    // background for a photo and the mask colour for a video.
    await pumpStage(
      tester,
      focused: photo(),
      selection: [photo()],
      aspect: CropAspect.story916,
    );

    final Size mask = tester.getSize(find.byType(CropDimmingMask));
    final Size window = tester.getSize(find.byType(CropThirdsOverlay));
    expect(mask.width, greaterThan(window.width));
    expect(
      mask.width,
      closeTo(surface.width - 2 * AssetPickerSizes.cropStageInset, 1e-6),
    );
    await unmount(tester);
  });
}
