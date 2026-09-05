import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/crop/video/video_seek_providers.dart';
import 'package:kutu_asset_picker/src/crop/video/video_trim_controller.dart';

import '../../support/fake_seek_target.dart';

void main() {
  const total = Duration(seconds: 40);
  const assetId = 'clip-1';

  late FakeSeekTarget seekTarget;

  ProviderContainer containerWith(AssetPickerConfig config) {
    final container = ProviderContainer(
      overrides: [
        assetPickerConfigProvider.overrideWithValue(config),
        videoSeekTargetProvider(assetId).overrideWithValue(seekTarget),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  setUp(() => seekTarget = FakeSeekTarget());

  test('starts at the whole clip when there is no cap', () {
    final container = containerWith(const AssetPickerConfig());

    final state = container.read(videoTrimControllerProvider(assetId, total));

    expect(state.trim.start, Duration.zero);
    expect(state.trim.end, total);
    expect(state.coverAt, Duration.zero);
  });

  test('starts at the leading cap window when the clip is longer', () {
    final container = containerWith(
      const AssetPickerConfig(maxVideoDuration: Duration(seconds: 15)),
    );

    final state = container.read(videoTrimControllerProvider(assetId, total));

    expect(state.trim.end, const Duration(seconds: 15));
  });

  test('nudging the in point moves it by that fraction of the clip', () {
    final container = containerWith(const AssetPickerConfig());
    final notifier =
        container.read(videoTrimControllerProvider(assetId, total).notifier);

    notifier.nudgeStart(0.25);

    expect(
      container.read(videoTrimControllerProvider(assetId, total)).trim.start,
      const Duration(seconds: 10),
    );
  });

  test('nudging the out point left shortens the range', () {
    final container = containerWith(const AssetPickerConfig());
    final notifier =
        container.read(videoTrimControllerProvider(assetId, total).notifier);

    notifier.nudgeEnd(-0.5);

    expect(
      container.read(videoTrimControllerProvider(assetId, total)).trim.end,
      const Duration(seconds: 20),
    );
  });

  test('the cap survives a widening nudge', () {
    final container = containerWith(
      const AssetPickerConfig(maxVideoDuration: Duration(seconds: 10)),
    );
    final notifier =
        container.read(videoTrimControllerProvider(assetId, total).notifier);

    notifier.nudgeEnd(0.5);

    final trim =
        container.read(videoTrimControllerProvider(assetId, total)).trim;
    expect(trim.duration, const Duration(seconds: 10));
    expect(trim.end, const Duration(seconds: 30));
    expect(trim.start, const Duration(seconds: 20));
  });

  test('the cover frame is pulled back inside a shrinking range', () {
    final container = containerWith(const AssetPickerConfig());
    final notifier = container
        .read(videoTrimControllerProvider(assetId, total).notifier)
      ..setCover(const Duration(seconds: 30));
    expect(
      container.read(videoTrimControllerProvider(assetId, total)).coverAt,
      const Duration(seconds: 30),
    );

    notifier.nudgeEnd(-0.5);

    expect(
      container.read(videoTrimControllerProvider(assetId, total)).coverAt,
      const Duration(seconds: 20),
    );
  });

  test('nudging the cover moves it and keeps it inside the range', () {
    final container = containerWith(const AssetPickerConfig());
    final notifier = container
        .read(videoTrimControllerProvider(assetId, total).notifier)
      ..nudgeCover(0.1);
    expect(
      container.read(videoTrimControllerProvider(assetId, total)).coverAt,
      const Duration(seconds: 4),
    );

    notifier.nudgeCover(-9);

    expect(
      container.read(videoTrimControllerProvider(assetId, total)).coverAt,
      Duration.zero,
    );
  });

  test('writes through to CropStates, so framing survives an asset switch', () {
    final container = containerWith(const AssetPickerConfig());

    container.read(videoTrimControllerProvider(assetId, total).notifier)
      ..nudgeStart(0.25)
      ..setCover(const Duration(seconds: 12));

    final stored = container.read(cropStatesProvider)[assetId]!;
    expect(stored.trim!.start, const Duration(seconds: 10));
    expect(stored.coverAt, const Duration(seconds: 12));
  });

  test('rehydrates from CropStates rather than resetting', () {
    final container = containerWith(const AssetPickerConfig());
    container.read(videoTrimControllerProvider(assetId, total).notifier)
      ..nudgeStart(0.25)
      ..endDrag();
    container.invalidate(videoTrimControllerProvider(assetId, total));

    expect(
      container.read(videoTrimControllerProvider(assetId, total)).trim.start,
      const Duration(seconds: 10),
    );
  });

  test('every nudge asks the coalescer for the frame under the handle', () {
    fakeAsync((async) {
      final container = containerWith(const AssetPickerConfig());

      container
          .read(videoTrimControllerProvider(assetId, total).notifier)
          .nudgeStart(0.25);
      async.flushMicrotasks();

      expect(seekTarget.seeks, const [Duration(seconds: 10)]);
    });
  });

  test('a released handle flushes the pending seek', () {
    fakeAsync((async) {
      final container = ProviderContainer(
        overrides: [
          assetPickerConfigProvider
              .overrideWithValue(const AssetPickerConfig()),
          videoSeekTargetProvider(assetId).overrideWithValue(
            FakeSeekTarget(latency: const Duration(milliseconds: 200)),
          ),
        ],
      );
      addTearDown(container.dispose);
      final notifier = container
          .read(videoTrimControllerProvider(assetId, total).notifier)
        ..nudgeStart(0.1);
      async.elapse(const Duration(milliseconds: 20));
      notifier
        ..nudgeStart(0.1)
        ..endDrag();
      async.elapse(const Duration(seconds: 2));

      expect(
        container.read(videoSeekCoalescerProvider(assetId)).pending,
        isNull,
      );
    });
  });
}
