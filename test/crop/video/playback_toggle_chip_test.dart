import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/crop/video/playback_target.dart';
import 'package:kutu_asset_picker/src/crop/video/playback_toggle_chip.dart';
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
  const text = AssetPickerTextEn();
  final provider = videoPlaybackControllerProvider(assetId, total);

  Future<dynamic> pumpChip(WidgetTester tester, PlaybackTarget target) =>
      pumpPickerWidget(
        tester,
        const Center(
          child: PlaybackToggleChip(assetId: assetId, total: total),
        ),
        config: const AssetPickerConfig(),
        overrides: [
          videoSeekTargetProvider(assetId).overrideWithValue(FakeSeekTarget()),
          videoPlaybackTargetProvider(assetId).overrideWithValue(target),
        ],
      );

  testWidgets('offers play, as delegate copy, once the player is ready',
      (tester) async {
    await pumpChip(tester, FakePlaybackTarget());

    expect(find.byTooltip(text.cropPlay), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('is inert before the player exists', (tester) async {
    final container = await pumpChip(tester, const NoopPlaybackTarget());

    await tester.tap(find.byType(PlaybackToggleChip));
    await tester.pump();

    expect(container.read(provider).isPlaying, isFalse);
  });

  testWidgets('a tap plays, and the chip turns into pause', (tester) async {
    final target = FakePlaybackTarget();
    final container = await pumpChip(tester, target);

    await tester.tap(find.byType(PlaybackToggleChip));
    await tester.pump();

    expect(container.read(provider).isPlaying, isTrue);
    expect(target.playing, isTrue);
    expect(find.byTooltip(text.cropPause), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsOneWidget);

    await tester.tap(find.byType(PlaybackToggleChip));
    await tester.pump();

    expect(container.read(provider).isPlaying, isFalse);
    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
  });

  testWidgets('is exactly one bar row tall, so the bar height holds',
      (tester) async {
    await pumpChip(tester, FakePlaybackTarget());

    expect(
      tester.getSize(find.byType(PlaybackToggleChip)).height,
      VideoCropConstants.barRowHeight,
    );
  });
}
