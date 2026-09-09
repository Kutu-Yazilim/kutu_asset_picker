import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/testing.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

void main() {
  test('reading the config unoverridden fails loudly', () {
    // Contract §9: a missing override is a WIRING BUG. It must fail loudly,
    // not silently pick a default that quietly disagrees with the host app.
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () => container.read(assetPickerConfigProvider),
      throwsA(isA<ProviderException>().having(
          (ProviderException e) => e.exception,
          'exception',
          isA<StateError>())),
    );
  });

  test('reading the source unoverridden fails loudly', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () => container.read(assetSourceProvider),
      throwsA(isA<ProviderException>().having(
          (ProviderException e) => e.exception,
          'exception',
          isA<StateError>())),
    );
  });

  test('the StateError names the provider that needs overriding', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () => container.read(assetSourceProvider),
      throwsA(
        isA<ProviderException>().having(
          (ProviderException e) => (e.exception as StateError).message,
          'message',
          contains('assetSourceProvider'),
        ),
      ),
    );
  });

  test('overrides are what the picker actually runs on', () {
    final FakeAssetSource source = FakeAssetSource();
    addTearDown(source.dispose);
    const AssetPickerConfig config = AssetPickerConfig(maxSelection: 3);

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        assetPickerConfigProvider.overrideWithValue(config),
        assetSourceProvider.overrideWithValue(source),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(assetPickerConfigProvider).maxSelection, 3);
    expect(container.read(assetSourceProvider), same(source));
  });

  test('the media transform has a real default, because production wants one',
      () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(mediaTransformProvider), isA<KutuMediaTransform>());
  });

  test('the camera delegate defaults to null, so the tile is opt-in', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(pickerCameraDelegateProvider), isNull);
  });

  test('a camera delegate can be injected', () {
    final _FakeCamera camera = _FakeCamera();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        pickerCameraDelegateProvider.overrideWithValue(camera),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(pickerCameraDelegateProvider), same(camera));
  });

  test('the settings opener is overridable', () async {
    int opened = 0;
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        pickerSettingsOpenerProvider.overrideWithValue(() async {
          opened += 1;
        }),
      ],
    );
    addTearDown(container.dispose);

    await container.read(pickerSettingsOpenerProvider)();

    expect(opened, 1);
  });
}

final class _FakeCamera implements PickerCameraDelegate {
  @override
  Future<CapturedMedia?> capture(Set<PickerMediaType> kinds) async => null;
}
