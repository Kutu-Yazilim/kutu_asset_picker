import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/crop/video/trim_handle.dart';
import 'package:kutu_asset_picker/src/crop/video/trim_handles_overlay.dart';
import 'package:kutu_asset_picker/src/crop/video/video_crop_constants.dart';
import 'package:kutu_asset_picker/src/crop/video/video_seek_providers.dart';
import 'package:kutu_asset_picker/src/crop/video/video_trim_controller.dart';

import '../../support/fake_seek_target.dart';
import '../../support/picker_test_harness.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  const assetId = 'clip-1';
  const total = Duration(seconds: 40);
  const trackWidth = 300.0;

  Future<ProviderContainer> pumpOverlay(
    WidgetTester tester, {
    AssetPickerConfig config = const AssetPickerConfig(),
  }) =>
      pumpPickerWidget(
        tester,
        const SizedBox(
          width: trackWidth,
          height: VideoCropConstants.filmstripHeight,
          child: TrimHandlesOverlay(
            assetId: assetId,
            total: total,
            trackWidth: trackWidth,
          ),
        ),
        config: config,
        overrides: [
          videoSeekTargetProvider(assetId).overrideWithValue(FakeSeekTarget()),
        ],
      );

  testWidgets('shows exactly two handles', (tester) async {
    await pumpOverlay(tester);

    expect(find.byType(TrimHandle), findsNWidgets(2));
  });

  testWidgets('DRAGGING THE KEPT ZONE CARRIES IT WHOLE', (tester) async {
    // Instead of moving the in point and then the out point, the author
    // grabs the zone between the handles and slides it. Keep 0:00–0:20,
    // drag its middle a quarter of the track: 0:10–0:30.
    final container = await pumpOverlay(tester);
    container
        .read(videoTrimControllerProvider(assetId, total).notifier)
        .nudgeEnd(-0.5);
    await tester.pump();

    await tester.drag(
      find.byKey(TrimHandlesOverlay.rangeKey),
      const Offset(trackWidth / 4, 0),
    );
    await tester.pump();

    final trim =
        container.read(videoTrimControllerProvider(assetId, total)).trim;
    expect(trim.start, const Duration(seconds: 10));
    expect(trim.end, const Duration(seconds: 30));
  });

  testWidgets('the zone sits between the handles and never over them',
      (tester) async {
    final container = await pumpOverlay(tester);
    container
        .read(videoTrimControllerProvider(assetId, total).notifier)
        .nudgeEnd(-0.5);
    await tester.pump();

    final Rect zone = tester.getRect(find.byKey(TrimHandlesOverlay.rangeKey));
    final Rect startHandle = tester.getRect(find.byWidgetPredicate(
      (w) => w is TrimHandle && w.side == TrimHandleSide.start,
    ));
    final Rect endHandle = tester.getRect(find.byWidgetPredicate(
      (w) => w is TrimHandle && w.side == TrimHandleSide.end,
    ));
    expect(zone.left, greaterThanOrEqualTo(startHandle.right));
    expect(zone.right, lessThanOrEqualTo(endHandle.left));
  });

  testWidgets('dragging the in handle right moves the in point',
      (tester) async {
    final container = await pumpOverlay(tester);

    await tester.drag(
      find.byWidgetPredicate(
        (w) => w is TrimHandle && w.side == TrimHandleSide.start,
      ),
      const Offset(trackWidth / 4, 0),
    );
    await tester.pump();

    expect(
      container.read(videoTrimControllerProvider(assetId, total)).trim.start,
      const Duration(seconds: 10),
    );
  });

  testWidgets('dragging the out handle left moves the out point',
      (tester) async {
    final container = await pumpOverlay(tester);

    await tester.drag(
      find.byWidgetPredicate(
        (w) => w is TrimHandle && w.side == TrimHandleSide.end,
      ),
      const Offset(-trackWidth / 4, 0),
    );
    await tester.pump();

    expect(
      container.read(videoTrimControllerProvider(assetId, total)).trim.end,
      const Duration(seconds: 30),
    );
  });

  testWidgets('the handles honour the duration cap while dragging',
      (tester) async {
    final container = await pumpOverlay(
      tester,
      config: const AssetPickerConfig(maxVideoDuration: Duration(seconds: 10)),
    );

    await tester.drag(
      find.byWidgetPredicate(
        (w) => w is TrimHandle && w.side == TrimHandleSide.end,
      ),
      const Offset(trackWidth, 0),
    );
    await tester.pump();

    expect(
      container.read(videoTrimControllerProvider(assetId, total)).trim.duration,
      const Duration(seconds: 10),
    );
  });

  testWidgets('dims the excluded head and tail of the strip', (tester) async {
    await pumpOverlay(tester);
    await tester.drag(
      find.byWidgetPredicate(
        (w) => w is TrimHandle && w.side == TrimHandleSide.start,
      ),
      const Offset(trackWidth / 4, 0),
    );
    await tester.pump();

    expect(
      find.byKey(TrimHandlesOverlay.leadingMaskKey),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(TrimHandlesOverlay.leadingMaskKey)).width,
      closeTo(trackWidth / 4, 0.5),
    );
  });

  testWidgets('the in handle cannot be dragged past the out handle',
      (tester) async {
    final container = await pumpOverlay(tester);

    await tester.drag(
      find.byWidgetPredicate(
        (w) => w is TrimHandle && w.side == TrimHandleSide.start,
      ),
      const Offset(trackWidth * 2, 0),
    );
    await tester.pump();

    final DurationRange trim =
        container.read(videoTrimControllerProvider(assetId, total)).trim;
    expect(trim.duration,
        greaterThanOrEqualTo(VideoCropConstants.minTrimDuration));
    expect(trim.start, lessThan(trim.end));
  });
}
