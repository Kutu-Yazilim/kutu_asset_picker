import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/crop/video/cover_cursor_overlay.dart';
import 'package:kutu_asset_picker/src/crop/video/scrubber_mode.dart';
import 'package:kutu_asset_picker/src/crop/video/scrubber_mode_toggle.dart';
import 'package:kutu_asset_picker/src/crop/video/trim_handles_overlay.dart';
import 'package:kutu_asset_picker/src/crop/video/video_control_bar.dart';
import 'package:kutu_asset_picker/src/crop/video/video_crop_constants.dart';
import 'package:kutu_asset_picker/src/crop/video/video_seek_providers.dart';

import '../../support/fake_seek_target.dart';
import '../../support/picker_test_harness.dart';

void main() {
  const assetId = 'clip-1';
  const total = Duration(seconds: 40);
  const text = AssetPickerTextEn();

  // Loose height on purpose: the bar's laid-out height is the thing under
  // test, so nothing here may impose one.
  Future<ProviderContainer> pumpBar(
    WidgetTester tester, {
    AssetPickerConfig config = const AssetPickerConfig(),
  }) =>
      pumpPickerWidget(
        tester,
        const Center(
          child: SizedBox(
            width: 320,
            child: VideoControlBar(
              assetId: assetId,
              total: total,
              srcPath: '/tmp/clip.mp4',
            ),
          ),
        ),
        config: config,
        overrides: [
          videoSeekTargetProvider(assetId).overrideWithValue(FakeSeekTarget()),
        ],
      );

  testWidgets('shows the trim range as delegate copy', (tester) async {
    await pumpBar(tester);

    expect(
      find.text(text.durationRange(Duration.zero, total)),
      findsOneWidget,
    );
  });

  testWidgets('starts in trim mode with the handles up', (tester) async {
    await pumpBar(tester);

    expect(find.byType(TrimHandlesOverlay), findsOneWidget);
    expect(find.byType(CoverCursorOverlay), findsNothing);
  });

  testWidgets('switching mode swaps the overlay on the same filmstrip',
      (tester) async {
    final container = await pumpBar(tester);

    container
        .read(scrubberModeControllerProvider.notifier)
        .select(ScrubberMode.cover);
    await tester.pump();

    expect(find.byType(CoverCursorOverlay), findsOneWidget);
    expect(find.byType(TrimHandlesOverlay), findsNothing);
  });

  testWidgets('LAYS OUT AT EXACTLY THE HEIGHT THE STAGE RESERVES FOR IT',
      (tester) async {
    // `CropStage` reserves `barSlotHeight` under the crop window before the
    // bar exists — it has to, or the window could not be computed — so the
    // bar's height is a constant derived from its parts, not something the
    // theme's text metrics decide at runtime. A bar taller than this would
    // overflow the band; a shorter one would leave a gap the chip row below
    // reads as misalignment.
    await pumpBar(tester);

    expect(
      tester.getSize(find.byType(VideoControlBar)).height,
      VideoCropConstants.barHeight,
    );
  });

  testWidgets('hides the mode toggle when only one mode exists',
      (tester) async {
    await pumpBar(
      tester,
      config: const AssetPickerConfig(enableCoverFrame: false),
    );

    expect(find.byType(ScrubberModeToggle), findsOneWidget);
    expect(find.text(text.cropCoverFrame), findsNothing);
  });

  testWidgets('renders nothing at all when both video sub-steps are off',
      (tester) async {
    await pumpBar(
      tester,
      config: const AssetPickerConfig(
        enableTrim: false,
        enableCoverFrame: false,
      ),
    );

    // The harness fixes the width; the bar's own contribution is the height.
    expect(tester.getSize(find.byType(VideoControlBar)).height, 0);
  });
}
