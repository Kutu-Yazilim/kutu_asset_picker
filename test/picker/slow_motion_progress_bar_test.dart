import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/picker/slow_motion_flatten.dart';
import 'package:kutu_asset_picker/src/picker/slow_motion_progress_bar.dart';
import 'package:kutu_asset_picker/testing.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:kutu_media_transform/testing.dart';

import '../support/picker_test_harness.dart';

void main() {
  const slowMotionInfo = VideoInfo(
    duration: Duration(seconds: 3),
    codedWidth: 1920,
    codedHeight: 1080,
    rotationDegrees: 0,
    isHdr: false,
    hasAudio: true,
  );

  late Directory tempDir;
  late FakeAssetSource source;

  final clip = PickerAsset(
    id: 'slow',
    type: PickerMediaType.video,
    width: 1080,
    height: 1920,
    createdAt: DateTime(2026, 8, 4),
    duration: const Duration(seconds: 12),
  );

  /// A transcode that reports halfway and then stalls, so the bar can be
  /// inspected mid-pass.
  FakeMediaTransform stalledAt(double fraction, Completer<void> gate) {
    final fake = FakeMediaTransform(videoInfo: slowMotionInfo)
      ..onExportVideo = (report) async {
        report(fraction);
        await gate.future;
      };
    addTearDown(fake.dispose);
    return fake;
  }

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('kutu_flatten_bar');
    source = FakeAssetSource();
    source.filesById['slow'] = File('${tempDir.path}/slow.mov')
      ..writeAsBytesSync([1, 2, 3]);
  });

  tearDown(() async {
    await source.dispose();
    tempDir.deleteSync(recursive: true);
  });

  testWidgets('an idle pass occupies no space at all', (tester) async {
    await pumpPickerWidget(
      tester,
      const SlowMotionProgressBar(),
      config: const AssetPickerConfig(),
      source: source,
    );

    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.byType(TextButton), findsNothing);
  });

  testWidgets('a running pass shows batch progress and a cancel',
      (tester) async {
    final gate = Completer<void>();
    final container = await pumpPickerWidget(
      tester,
      const SlowMotionProgressBar(),
      config: const AssetPickerConfig(),
      source: source,
      transform: stalledAt(0.5, gate),
    );
    container.read(selectionProvider.notifier).toggleAsset(clip);
    unawaited(container.read(slowMotionFlattenProvider.notifier).run());

    // Two zero-length pumps: the first lets the pass reach the fake's export
    // and report 0.5, the second rebuilds the bar with it.
    await tester.pump(Duration.zero);
    await tester.pump(Duration.zero);

    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      closeTo(0.5, 1e-9),
    );
    expect(find.text(const AssetPickerTextEn().pickerCancel), findsOneWidget);

    gate.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('the cancel stops the pass and the bar goes away',
      (tester) async {
    final gate = Completer<void>();
    final container = await pumpPickerWidget(
      tester,
      const SlowMotionProgressBar(),
      config: const AssetPickerConfig(),
      source: source,
      transform: stalledAt(0.5, gate),
    );
    container.read(selectionProvider.notifier).toggleAsset(clip);
    unawaited(container.read(slowMotionFlattenProvider.notifier).run());
    await tester.pump(Duration.zero);
    await tester.pump(Duration.zero);

    // The button is PickerCommit.cancel, which cancels the pass with it — that
    // indirection is the point, so the test taps rather than calling.
    await tester.tap(find.text(const AssetPickerTextEn().pickerCancel));
    await tester.pump();

    expect(container.read(slowMotionFlattenProvider).running, isFalse);
    expect(find.byType(LinearProgressIndicator), findsNothing);

    gate.complete();
    await tester.pumpAndSettle();
  });
}
