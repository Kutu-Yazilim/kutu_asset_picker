import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/crop/video/playhead_overlay.dart';
import 'package:kutu_asset_picker/src/crop/video/video_crop_constants.dart';
import 'package:kutu_asset_picker/src/crop/video/video_playback_controller.dart';
import 'package:kutu_asset_picker/src/crop/video/video_playback_providers.dart';
import 'package:kutu_asset_picker/src/crop/video/video_seek_providers.dart';

import '../../support/fake_playback_target.dart';
import '../../support/fake_seek_target.dart';
import '../../support/picker_test_harness.dart';

void main() {
  const assetId = 'clip-1';
  const total = Duration(seconds: 40);
  const trackWidth = 300.0;
  final provider = videoPlaybackControllerProvider(assetId, total);

  late FakePlaybackTarget target;

  Future<dynamic> pumpPlayhead(WidgetTester tester) => pumpPickerWidget(
        tester,
        const SizedBox(
          width: trackWidth,
          height: VideoCropConstants.filmstripHeight,
          child: PlayheadOverlay(
            assetId: assetId,
            total: total,
            trackWidth: trackWidth,
          ),
        ),
        config: const AssetPickerConfig(),
        overrides: [
          videoSeekTargetProvider(assetId).overrideWithValue(FakeSeekTarget()),
          videoPlaybackTargetProvider(assetId).overrideWithValue(target),
        ],
      );

  setUp(() => target = FakePlaybackTarget());

  testWidgets('shows nothing until the clip has been played', (tester) async {
    await pumpPlayhead(tester);

    expect(find.byKey(PlayheadOverlay.playheadKey), findsNothing);
  });

  testWidgets('marks the playhead at its fraction of the track',
      (tester) async {
    final container = await pumpPlayhead(tester);
    container.read(provider.notifier).play();
    await tester.pump();
    target.at = const Duration(seconds: 10);
    await tester.pump(VideoCropConstants.playbackPollInterval);

    final Rect line = tester.getRect(find.byKey(PlayheadOverlay.playheadKey));
    final Rect track = tester.getRect(find.byType(PlayheadOverlay));
    expect(line.center.dx, closeTo(track.left + trackWidth / 4, 1e-6));

    container.read(provider.notifier).pause();
    await tester.pump();
    // Paused, the line stays: it is the reference the handles are dragged to.
    expect(find.byKey(PlayheadOverlay.playheadKey), findsOneWidget);
  });

  testWidgets('never intercepts a drag meant for a handle', (tester) async {
    await pumpPlayhead(tester);

    expect(
      find.descendant(
        of: find.byType(PlayheadOverlay),
        matching: find.byType(IgnorePointer),
      ),
      findsOneWidget,
    );
  });
}
