import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/crop/video/cover_cursor_overlay.dart';
import 'package:kutu_asset_picker/src/crop/video/crop_gesture_activity.dart';
import 'package:kutu_asset_picker/src/crop/video/floating_video_bar.dart';
import 'package:kutu_asset_picker/src/crop/video/scrubber_mode.dart';
import 'package:kutu_asset_picker/src/crop/video/scrubber_mode_toggle.dart';
import 'package:kutu_asset_picker/src/crop/video/trim_handles_overlay.dart';
import 'package:kutu_asset_picker/src/crop/video/video_crop_constants.dart';
import 'package:kutu_asset_picker/src/crop/video/video_seek_providers.dart';

import '../../support/fake_seek_target.dart';
import '../../support/picker_test_harness.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  const assetId = 'clip-1';
  const total = Duration(seconds: 40);
  const text = AssetPickerTextEn();

  Future<ProviderContainer> pumpBar(
    WidgetTester tester, {
    AssetPickerConfig config = const AssetPickerConfig(),
  }) =>
      pumpPickerWidget(
        tester,
        const SizedBox(
          width: 320,
          height: 140,
          child: FloatingVideoBar(
            assetId: assetId,
            total: total,
            srcPath: '/tmp/clip.mp4',
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

  testWidgets('is fully opaque at rest', (tester) async {
    await pumpBar(tester);

    expect(
      tester.widget<AnimatedOpacity>(_barOpacity).opacity,
      VideoCropConstants.barOpacityIdle,
    );
  });

  testWidgets('fades out while the footage is being dragged', (tester) async {
    final container = await pumpBar(tester);

    container.read(cropGestureActivityProvider.notifier).pointerDown();
    await tester.pump();

    expect(
      tester.widget<AnimatedOpacity>(_barOpacity).opacity,
      VideoCropConstants.barOpacityDragging,
    );
    expect(
        tester
            .widget<IgnorePointer>(find.descendant(
                of: find.byType(FloatingVideoBar),
                matching: find.byType(IgnorePointer)))
            .ignoring,
        isTrue);
  });

  testWidgets('returns on release', (tester) async {
    final container = await pumpBar(tester);
    container.read(cropGestureActivityProvider.notifier).pointerDown();
    await tester.pump();

    container.read(cropGestureActivityProvider.notifier).pointerUp();
    await tester.pump(VideoCropConstants.barFadeDuration);

    expect(
      tester.widget<AnimatedOpacity>(_barOpacity).opacity,
      VideoCropConstants.barOpacityIdle,
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

    expect(_barOpacity, findsNothing);
  });
}

/// The bar's own fade, not any AnimatedOpacity the surrounding chrome adds.
final Finder _barOpacity = find.descendant(
  of: find.byType(FloatingVideoBar),
  matching: find.byType(AnimatedOpacity),
);
