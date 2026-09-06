import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/crop/video/cover_cursor_overlay.dart';
import 'package:kutu_asset_picker/src/crop/video/scrubber_mode.dart';
import 'package:kutu_asset_picker/src/crop/video/video_crop_constants.dart';
import 'package:kutu_asset_picker/src/crop/video/video_playback_controller.dart';
import 'package:kutu_asset_picker/src/crop/video/video_playback_providers.dart';
import 'package:kutu_asset_picker/src/crop/video/video_seek_providers.dart';
import 'package:kutu_asset_picker/src/crop/video/video_trim_controller.dart';

import '../../support/fake_playback_target.dart';
import '../../support/fake_seek_target.dart';
import '../../support/picker_test_harness.dart';

void main() {
  const assetId = 'clip-1';
  const total = Duration(seconds: 40);
  const trackWidth = 300.0;

  late FakeSeekTarget seekTarget;
  late FakePlaybackTarget playbackTarget;

  Future<dynamic> pumpCursor(WidgetTester tester) => pumpPickerWidget(
        tester,
        const SizedBox(
          width: trackWidth,
          height: VideoCropConstants.filmstripHeight,
          child: CoverCursorOverlay(
            assetId: assetId,
            total: total,
            trackWidth: trackWidth,
          ),
        ),
        config: const AssetPickerConfig(),
        overrides: [
          videoSeekTargetProvider(assetId).overrideWithValue(seekTarget),
          videoPlaybackTargetProvider(assetId)
              .overrideWithValue(playbackTarget),
        ],
      );

  setUp(() {
    seekTarget = FakeSeekTarget();
    playbackTarget = FakePlaybackTarget();
  });

  testWidgets('starts at the in point', (tester) async {
    final container = await pumpCursor(tester);

    expect(
      container.read(videoTrimControllerProvider(assetId, total)).coverAt,
      Duration.zero,
    );
    expect(find.byKey(CoverCursorOverlay.cursorKey), findsOneWidget);
  });

  testWidgets('dragging moves the cover instant', (tester) async {
    final container = await pumpCursor(tester);

    await tester.drag(
      find.byKey(CoverCursorOverlay.cursorKey),
      const Offset(trackWidth / 4, 0),
    );
    await tester.pump();

    expect(
      container.read(videoTrimControllerProvider(assetId, total)).coverAt,
      const Duration(seconds: 10),
    );
  });

  testWidgets('cannot be dragged outside the trim range', (tester) async {
    final container = await pumpCursor(tester);
    container
        .read(videoTrimControllerProvider(assetId, total).notifier)
        .nudgeEnd(-0.5);
    await tester.pump();

    await tester.drag(
      find.byKey(CoverCursorOverlay.cursorKey),
      const Offset(trackWidth * 2, 0),
    );
    await tester.pump();

    expect(
      container.read(videoTrimControllerProvider(assetId, total)).coverAt,
      const Duration(seconds: 20),
    );
  });

  testWidgets('seeks the player so the author sees the frame they are picking',
      (tester) async {
    await pumpCursor(tester);

    await tester.drag(
      find.byKey(CoverCursorOverlay.cursorKey),
      const Offset(trackWidth / 4, 0),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(seekTarget.seeks, isNotEmpty);
    expect(seekTarget.seeks.last, const Duration(seconds: 10));
  });

  testWidgets('FOLLOWS THE PLAYHEAD WHILE PLAYING, AND A PAUSE COMMITS IT',
      (tester) async {
    // In cover mode the cursor is the frame being chosen, so while the clip
    // plays the cursor rides the playhead and pausing keeps whatever frame
    // it stopped on — the author watches for the moment instead of guessing
    // from twelve filmstrip thumbnails.
    final container = await pumpCursor(tester);
    final playback = videoPlaybackControllerProvider(assetId, total);
    container
        .read(scrubberModeControllerProvider.notifier)
        .select(ScrubberMode.cover);
    container.read(playback.notifier).play();
    await tester.pump();
    playbackTarget.at = const Duration(seconds: 20);
    await tester.pump(VideoCropConstants.playbackPollInterval);

    final Rect track = tester.getRect(find.byType(CoverCursorOverlay));
    final Rect cursor =
        tester.getRect(find.byKey(CoverCursorOverlay.cursorKey));
    expect(cursor.center.dx, closeTo(track.left + trackWidth / 2, 1e-6));
    expect(
      container.read(videoTrimControllerProvider(assetId, total)).coverAt,
      Duration.zero,
      reason: 'following is visual; nothing is committed until the pause',
    );

    container.read(playback.notifier).pause();
    await tester.pump();

    expect(
      container.read(videoTrimControllerProvider(assetId, total)).coverAt,
      const Duration(seconds: 20),
    );
  });

  testWidgets('grabbing the cursor mid-playback pauses where it was',
      (tester) async {
    final container = await pumpCursor(tester);
    final playback = videoPlaybackControllerProvider(assetId, total);
    container
        .read(scrubberModeControllerProvider.notifier)
        .select(ScrubberMode.cover);
    container.read(playback.notifier).play();
    await tester.pump();
    playbackTarget.at = const Duration(seconds: 20);
    await tester.pump(VideoCropConstants.playbackPollInterval);

    await tester.drag(
      find.byKey(CoverCursorOverlay.cursorKey),
      const Offset(trackWidth / 4, 0),
    );
    await tester.pump();

    expect(container.read(playback).isPlaying, isFalse);
    // Committed at 0:20 on the grab, then dragged a quarter of the clip.
    expect(
      container.read(videoTrimControllerProvider(assetId, total)).coverAt,
      const Duration(seconds: 30),
    );
  });
}
