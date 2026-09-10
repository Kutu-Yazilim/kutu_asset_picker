import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/testing.dart';

import '../support/pump_picker.dart';

class _FakeCamera implements PickerCameraDelegate {
  _FakeCamera(this._result);

  final CapturedMedia? _result;
  final List<Set<PickerMediaType>> calls = <Set<PickerMediaType>>[];
  Completer<void>? gate;

  @override
  Future<CapturedMedia?> capture(Set<PickerMediaType> kinds) async {
    calls.add(kinds);
    if (gate case final Completer<void> g) {
      await g.future;
    }
    return _result;
  }
}

CapturedMedia _shot() =>
    CapturedMedia(file: File('/tmp/shot.jpg'), kind: PickerMediaType.image);

ProviderContainer _container({
  required PickerCameraDelegate camera,
  required FakeAssetSource source,
  Set<PickerMediaType> kinds = const {PickerMediaType.image},
}) {
  final container = ProviderContainer(
    overrides: [
      assetSourceProvider.overrideWithValue(source),
      pickerCameraDelegateProvider.overrideWithValue(camera),
      assetPickerConfigProvider
          .overrideWithValue(AssetPickerConfig(mediaTypes: kinds)),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('a successful capture is saved, prepended and selected', () async {
    // fakeSourceWith gives one album already wired to the id the page
    // provider selects, which is what makes `prepend` have a list to prepend
    // to. `selectionProvider` holds asset IDS, not assets.
    final source = fakeSourceWith(testAssets(2));
    addTearDown(source.dispose);
    final camera = _FakeCamera(_shot());
    final container = _container(camera: camera, source: source);

    container.read(currentAlbumProvider.notifier).select(
          const PickerAlbum(
              id: 'all', name: 'Recent', assetCount: 2, isAll: true),
        );
    await container.read(assetPageProvider.future);

    await container.read(cameraCaptureProvider.notifier).capture();

    expect(camera.calls.single, {PickerMediaType.image});
    expect(source.savedCaptures.single.file.path, '/tmp/shot.jpg');
    expect(container.read(assetPageProvider).requireValue.first.id, 'captured');
    expect(container.read(selectionProvider), <String>['captured']);
    expect(container.read(cameraCaptureProvider), CameraCaptureStatus.idle);
  });

  test('a cancelled capture saves nothing and reports no failure', () async {
    final source = FakeAssetSource();
    final container = _container(camera: _FakeCamera(null), source: source);

    await container.read(cameraCaptureProvider.notifier).capture();

    expect(source.savedCaptures, isEmpty);
    expect(container.read(cameraCaptureProvider), CameraCaptureStatus.idle);
  });

  test('a refused save reports failure rather than swallowing it', () async {
    final source = FakeAssetSource()..saveThrows = true;
    final container = _container(camera: _FakeCamera(_shot()), source: source);

    await container.read(cameraCaptureProvider.notifier).capture();

    expect(container.read(cameraCaptureProvider), CameraCaptureStatus.failed);
  });

  test('a save that yields nothing usable also reports failure', () async {
    final source = FakeAssetSource()..saveResult = null;
    final container = _container(camera: _FakeCamera(_shot()), source: source);

    await container.read(cameraCaptureProvider.notifier).capture();

    expect(container.read(cameraCaptureProvider), CameraCaptureStatus.failed);
  });

  test('a second capture while one is in flight is ignored', () async {
    final source = FakeAssetSource();
    final camera = _FakeCamera(_shot())..gate = Completer<void>();
    final container = _container(camera: camera, source: source);
    final notifier = container.read(cameraCaptureProvider.notifier);

    final first = notifier.capture();
    await notifier.capture();
    camera.gate!.complete();
    await first;

    expect(camera.calls, hasLength(1));
  });

  test('retrying after a failure clears the failed state', () async {
    final source = FakeAssetSource()..saveThrows = true;
    final container = _container(camera: _FakeCamera(_shot()), source: source);
    final notifier = container.read(cameraCaptureProvider.notifier);

    await notifier.capture();
    expect(container.read(cameraCaptureProvider), CameraCaptureStatus.failed);

    source.saveThrows = false;
    await notifier.capture();
    expect(container.read(cameraCaptureProvider), CameraCaptureStatus.idle);
  });
}
