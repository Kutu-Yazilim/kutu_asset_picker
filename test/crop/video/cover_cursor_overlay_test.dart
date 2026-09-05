import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/crop/video/cover_cursor_overlay.dart';
import 'package:kutu_asset_picker/src/crop/video/video_crop_constants.dart';
import 'package:kutu_asset_picker/src/crop/video/video_seek_providers.dart';
import 'package:kutu_asset_picker/src/crop/video/video_trim_controller.dart';

import '../../support/fake_seek_target.dart';
import '../../support/picker_test_harness.dart';

void main() {
  const assetId = 'clip-1';
  const total = Duration(seconds: 40);
  const trackWidth = 300.0;

  late FakeSeekTarget seekTarget;

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
        ],
      );

  setUp(() => seekTarget = FakeSeekTarget());

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
}
