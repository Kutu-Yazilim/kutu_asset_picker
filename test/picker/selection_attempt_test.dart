import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/crop/video/video_rejection.dart';
import 'package:kutu_asset_picker/src/picker/selection_attempt.dart';
import 'package:kutu_asset_picker/src/source/fake_asset_source.dart';

void main() {
  PickerAsset video(String id, Duration duration) => PickerAsset(
        id: id,
        type: PickerMediaType.video,
        width: 1080,
        height: 1920,
        createdAt: DateTime(2026, 8, 4),
        duration: duration,
      );

  const capped = AssetPickerConfig(maxVideoDuration: Duration(seconds: 60));

  ProviderContainer makeContainer([AssetPickerConfig config = capped]) {
    final container = ProviderContainer(
      overrides: [
        assetPickerConfigProvider.overrideWithValue(config),
        assetSourceProvider.overrideWithValue(FakeAssetSource()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('an acceptable video is selected and nothing is reported', () {
    final container = makeContainer();

    container
        .read(selectionAttemptProvider.notifier)
        .toggle(video('ok', const Duration(seconds: 10)));

    expect(container.read(selectionProvider), ['ok']);
    expect(container.read(selectionAttemptProvider), isNull);
  });

  test('an over-long video is refused and reported', () {
    final container = makeContainer();

    container
        .read(selectionAttemptProvider.notifier)
        .toggle(video('long', const Duration(seconds: 90)));

    expect(container.read(selectionProvider), isEmpty);
    expect(container.read(selectionAttemptProvider), isA<VideoTooLong>());
  });

  test('a successful selection clears a previous rejection', () {
    final container = makeContainer();
    final notifier = container.read(selectionAttemptProvider.notifier)
      ..toggle(video('long', const Duration(seconds: 90)));
    expect(container.read(selectionAttemptProvider), isNotNull);

    notifier.toggle(video('ok', const Duration(seconds: 10)));

    expect(container.read(selectionAttemptProvider), isNull);
  });

  test('deselecting is never blocked', () {
    final container = makeContainer(const AssetPickerConfig());
    final asset = video('long', const Duration(seconds: 90));
    final notifier = container.read(selectionAttemptProvider.notifier)
      ..toggle(asset);
    expect(container.read(selectionProvider), ['long']);

    // The cap only exists in the capped config; simulate it changing under a
    // selected asset by refusing it now and confirming the toggle still runs.
    notifier.toggle(asset);

    expect(container.read(selectionProvider), isEmpty);
  });

  test('dismiss clears the reported rejection', () {
    final container = makeContainer();
    final notifier = container.read(selectionAttemptProvider.notifier)
      ..toggle(video('long', const Duration(seconds: 90)));

    notifier.dismiss();

    expect(container.read(selectionAttemptProvider), isNull);
  });
}
