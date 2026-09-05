import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/testing.dart';

const PickerAlbum _recent =
    PickerAlbum(id: 'all', name: 'Recent', assetCount: 3, isAll: true);

PickerAsset _image(String id) => PickerAsset(
      id: id,
      type: PickerMediaType.image,
      width: 100,
      height: 100,
      createdAt: DateTime.utc(2026, 8, 4),
    );

ProviderContainer _container(FakeAssetSource source) {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      assetPickerConfigProvider.overrideWithValue(const AssetPickerConfig()),
      assetSourceProvider.overrideWithValue(source),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('while the albums are still loading it is NOT empty', () async {
    // The naive rule — "the page is empty" — is true here, and acting on it
    // flashes an empty state for a frame on every single open.
    final FakeAssetSource source = FakeAssetSource(
      albumList: const <PickerAlbum>[_recent],
      assetsByAlbum: <String, List<PickerAsset>>{
        'all': <PickerAsset>[_image('a0')],
      },
    )..queryDelay = const Duration(milliseconds: 20);
    addTearDown(source.dispose);
    final ProviderContainer container = _container(source);

    container.read(assetPickerAlbumsProvider);

    expect(container.read(pickerLibraryEmptyProvider), isFalse);

    await container.read(assetPickerAlbumsProvider.future);
    await container.pump();
    await container.read(assetPageProvider.future);

    expect(container.read(pickerLibraryEmptyProvider), isFalse);
  });

  test('no albums at all is empty', () async {
    final FakeAssetSource source = FakeAssetSource();
    addTearDown(source.dispose);
    final ProviderContainer container = _container(source);

    await container.read(assetPickerAlbumsProvider.future);
    await container.pump();

    expect(container.read(pickerLibraryEmptyProvider), isTrue);
  });

  test('an adopted album whose first page came back empty is empty', () async {
    final FakeAssetSource source = FakeAssetSource(
      albumList: const <PickerAlbum>[_recent],
      assetsByAlbum: <String, List<PickerAsset>>{'all': const <PickerAsset>[]},
    );
    addTearDown(source.dispose);
    final ProviderContainer container = _container(source);

    await container.read(assetPickerAlbumsProvider.future);
    await container.pump();
    await container.read(assetPageProvider.future);

    expect(container.read(pickerLibraryEmptyProvider), isTrue);
  });

  test('a populated album is not empty', () async {
    final FakeAssetSource source = FakeAssetSource(
      albumList: const <PickerAlbum>[_recent],
      assetsByAlbum: <String, List<PickerAsset>>{
        'all': <PickerAsset>[_image('a0'), _image('a1')],
      },
    );
    addTearDown(source.dispose);
    final ProviderContainer container = _container(source);

    await container.read(assetPickerAlbumsProvider.future);
    await container.pump();
    await container.read(assetPageProvider.future);

    expect(container.read(pickerLibraryEmptyProvider), isFalse);
  });
}
