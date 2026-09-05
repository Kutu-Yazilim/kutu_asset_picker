import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/testing.dart';

const PickerAlbum _recent =
    PickerAlbum(id: 'all', name: 'Recent', assetCount: 12, isAll: true);
const PickerAlbum _camera =
    PickerAlbum(id: 'cam', name: 'Camera', assetCount: 4, isAll: false);

ProviderContainer _container(
  FakeAssetSource source, {
  AssetPickerConfig config = const AssetPickerConfig(),
}) {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      assetPickerConfigProvider.overrideWithValue(config),
      assetSourceProvider.overrideWithValue(source),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('lists albums for the configured media types', () async {
    final FakeAssetSource source = FakeAssetSource(
      albumList: const <PickerAlbum>[_recent, _camera],
    );
    addTearDown(source.dispose);
    final ProviderContainer container = _container(
      source,
      config: const AssetPickerConfig(
        mediaTypes: <PickerMediaType>{PickerMediaType.image},
        maxVideoDuration: Duration(seconds: 60),
      ),
    );

    final List<PickerAlbum> albums =
        await container.read(assetPickerAlbumsProvider.future);

    expect(albums, <PickerAlbum>[_recent, _camera]);
    expect(source.albumQueries.single.kinds,
        <PickerMediaType>{PickerMediaType.image});
    expect(source.albumQueries.single.maxVideoDuration,
        const Duration(seconds: 60));
  });

  test('the first album becomes the current one', () async {
    final FakeAssetSource source = FakeAssetSource(
      albumList: const <PickerAlbum>[_recent, _camera],
    );
    addTearDown(source.dispose);
    final ProviderContainer container = _container(source);

    await container.read(assetPickerAlbumsProvider.future);
    await container.pump();

    expect(container.read(currentAlbumProvider), _recent);
  });

  test('selecting an album replaces the current one', () async {
    final FakeAssetSource source = FakeAssetSource(
      albumList: const <PickerAlbum>[_recent, _camera],
    );
    addTearDown(source.dispose);
    final ProviderContainer container = _container(source);

    await container.read(assetPickerAlbumsProvider.future);
    await container.pump();
    container.read(currentAlbumProvider.notifier).select(_camera);

    expect(container.read(currentAlbumProvider), _camera);
  });

  test('manageLimitedSelection presents the OS UI then re-queries albums',
      () async {
    // design §4.2: when presentLimited returns, album lists and counts are
    // STALE. Re-querying is not an optimisation — the grid is showing a
    // library the user just changed.
    final FakeAssetSource source = FakeAssetSource(
      permission: PickerPermission.limited,
      albumList: const <PickerAlbum>[_recent],
    );
    addTearDown(source.dispose);
    final ProviderContainer container = _container(
      source,
      config: const AssetPickerConfig(
        mediaTypes: <PickerMediaType>{PickerMediaType.image},
      ),
    );

    await container.read(assetPickerAlbumsProvider.future);
    await container.pump();
    expect(source.albumQueries, hasLength(1));

    // The user adds a photo to the granted subset while they are away.
    source.albumList = const <PickerAlbum>[
      PickerAlbum(id: 'all', name: 'Recent', assetCount: 13, isAll: true),
    ];

    await container
        .read(assetPickerAlbumsProvider.notifier)
        .manageLimitedSelection();

    expect(source.manageLimitedSelectionCalls, 1);
    expect(source.albumQueries, hasLength(2),
        reason: 'albums must be re-queried after presentLimited returns');
    expect(container.read(currentAlbumProvider)!.assetCount, 13);
  });

  test('a refresh that finds no albums clears the current one', () async {
    final FakeAssetSource source = FakeAssetSource(
      permission: PickerPermission.limited,
      albumList: const <PickerAlbum>[_recent],
    );
    addTearDown(source.dispose);
    final ProviderContainer container = _container(source);

    await container.read(assetPickerAlbumsProvider.future);
    await container.pump();
    expect(container.read(currentAlbumProvider), isNotNull);

    // The user revokes every granted item.
    source.albumList = const <PickerAlbum>[];
    await container
        .read(assetPickerAlbumsProvider.notifier)
        .refreshAfterLimitedChange();

    expect(container.read(assetPickerAlbumsProvider).value, isEmpty);
    expect(container.read(currentAlbumProvider), isNull);
  });

  test('a failing album query surfaces as an AsyncError, not a throw',
      () async {
    final FakeAssetSource source = FakeAssetSource(
      albumList: const <PickerAlbum>[_recent],
    );
    addTearDown(source.dispose);
    final ProviderContainer container = _container(source);

    await container.read(assetPickerAlbumsProvider.future);
    await container.pump();

    source.albumList = const <PickerAlbum>[];
    source.queryDelay = const Duration(milliseconds: 1);
    await container
        .read(assetPickerAlbumsProvider.notifier)
        .refreshAfterLimitedChange();

    expect(container.read(assetPickerAlbumsProvider).hasError, isFalse);
    expect(container.read(assetPickerAlbumsProvider).value, isEmpty);
  });
}
