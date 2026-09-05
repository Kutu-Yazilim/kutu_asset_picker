import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/testing.dart';

const PickerAlbum _recent =
    PickerAlbum(id: 'all', name: 'Recent', assetCount: 200, isAll: true);
const PickerAlbum _camera =
    PickerAlbum(id: 'cam', name: 'Camera', assetCount: 1, isAll: false);

PickerAsset _image(String id) => PickerAsset(
      id: id,
      type: PickerMediaType.image,
      width: 100,
      height: 100,
      createdAt: DateTime.utc(2026, 8, 4),
    );

List<PickerAsset> _images(int count, {String prefix = 'a'}) =>
    <PickerAsset>[for (int i = 0; i < count; i += 1) _image('$prefix$i')];

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
  test('with no album selected the page is empty and no query is issued',
      () async {
    final FakeAssetSource source = FakeAssetSource();
    addTearDown(source.dispose);
    final ProviderContainer container = _container(source);

    expect(await container.read(assetPageProvider.future), isEmpty);
    expect(source.assetQueries, isEmpty);
  });

  test('loads the first page for the current album', () async {
    final FakeAssetSource source = FakeAssetSource(
      albumList: const <PickerAlbum>[_recent],
      assetsByAlbum: <String, List<PickerAsset>>{'all': _images(200)},
    );
    addTearDown(source.dispose);
    final ProviderContainer container = _container(source);

    container.read(currentAlbumProvider.notifier).select(_recent);
    final List<PickerAsset> page =
        await container.read(assetPageProvider.future);

    expect(page, hasLength(PickerGridTuning.pageSize));
    expect(source.assetQueries.single.offset, 0);
    expect(source.assetQueries.single.count, PickerGridTuning.pageSize);
  });

  test('loadMore appends the next page', () async {
    final FakeAssetSource source = FakeAssetSource(
      albumList: const <PickerAlbum>[_recent],
      assetsByAlbum: <String, List<PickerAsset>>{'all': _images(200)},
    );
    addTearDown(source.dispose);
    final ProviderContainer container = _container(source);

    container.read(currentAlbumProvider.notifier).select(_recent);
    await container.read(assetPageProvider.future);
    await container.read(assetPageProvider.notifier).loadMore();

    expect(container.read(assetPageProvider).requireValue,
        hasLength(PickerGridTuning.pageSize * 2));
    expect(source.assetQueries.last.offset, PickerGridTuning.pageSize);
  });

  test('loadMore stops issuing queries once the album is exhausted', () async {
    final FakeAssetSource source = FakeAssetSource(
      albumList: const <PickerAlbum>[_camera],
      assetsByAlbum: <String, List<PickerAsset>>{'cam': _images(3)},
    );
    addTearDown(source.dispose);
    final ProviderContainer container = _container(source);

    container.read(currentAlbumProvider.notifier).select(_camera);
    await container.read(assetPageProvider.future);
    expect(container.read(assetPageProvider.notifier).hasMore, isFalse);

    await container.read(assetPageProvider.notifier).loadMore();
    await container.read(assetPageProvider.notifier).loadMore();

    expect(source.assetQueries, hasLength(1),
        reason: 'a short page means the end; further scrolling must not '
            'hammer the platform');
  });

  test('changing the album restarts paging from zero', () async {
    final FakeAssetSource source = FakeAssetSource(
      albumList: const <PickerAlbum>[_recent, _camera],
      assetsByAlbum: <String, List<PickerAsset>>{
        'all': _images(200),
        'cam': _images(3, prefix: 'c'),
      },
    );
    addTearDown(source.dispose);
    final ProviderContainer container = _container(source);

    container.read(currentAlbumProvider.notifier).select(_recent);
    await container.read(assetPageProvider.future);
    await container.read(assetPageProvider.notifier).loadMore();

    container.read(currentAlbumProvider.notifier).select(_camera);
    final List<PickerAsset> page =
        await container.read(assetPageProvider.future);

    expect(page.map((PickerAsset a) => a.id), <String>['c0', 'c1', 'c2']);
    expect(source.assetQueries.last.offset, 0,
        reason: 'a new album starts at offset 0, not at the old cursor');
  });

  test('a library change re-pages without a manual refresh', () async {
    // design §5: a photo taken via the camera tile appears without the user
    // pulling to refresh.
    final FakeAssetSource source = FakeAssetSource(
      albumList: const <PickerAlbum>[_camera],
      assetsByAlbum: <String, List<PickerAsset>>{'cam': _images(1)},
    );
    addTearDown(source.dispose);
    final ProviderContainer container = _container(source);

    container.read(currentAlbumProvider.notifier).select(_camera);
    await container.read(assetPageProvider.future);
    expect(source.assetQueries, hasLength(1));

    source.assetsByAlbum['cam'] = _images(2);
    source.emitChange();
    await container.pump();
    await container.read(assetPageProvider.future);

    expect(source.assetQueries.length, greaterThanOrEqualTo(2));
    expect(container.read(assetPageProvider).requireValue, hasLength(2));
  });

  test('prepend puts a fresh capture at the head exactly once', () async {
    final FakeAssetSource source = FakeAssetSource(
      albumList: const <PickerAlbum>[_camera],
      assetsByAlbum: <String, List<PickerAsset>>{'cam': _images(1)},
    );
    addTearDown(source.dispose);
    final ProviderContainer container = _container(source);

    container.read(currentAlbumProvider.notifier).select(_camera);
    await container.read(assetPageProvider.future);

    container.read(assetPageProvider.notifier).prepend(_image('fresh'));
    container.read(assetPageProvider.notifier).prepend(_image('fresh'));

    final List<PickerAsset> page =
        container.read(assetPageProvider).requireValue;
    expect(page.first.id, 'fresh');
    expect(page.where((PickerAsset a) => a.id == 'fresh'), hasLength(1));
  });

  test('refreshAfterLimitedChange restarts paging even for an identical album',
      () async {
    // The album value is unchanged, so `ref.watch` alone would not re-run the
    // build. The explicit invalidate in AssetPickerAlbums is what saves this.
    final FakeAssetSource source = FakeAssetSource(
      permission: PickerPermission.limited,
      albumList: const <PickerAlbum>[_camera],
      assetsByAlbum: <String, List<PickerAsset>>{'cam': _images(1)},
    );
    addTearDown(source.dispose);
    final ProviderContainer container = _container(source);

    await container.read(assetPickerAlbumsProvider.future);
    await container.pump();
    await container.read(assetPageProvider.future);
    final int before = source.assetQueries.length;

    source.assetsByAlbum['cam'] = _images(2);
    await container
        .read(assetPickerAlbumsProvider.notifier)
        .refreshAfterLimitedChange();
    await container.read(assetPageProvider.future);

    expect(source.assetQueries.length, greaterThan(before));
    expect(container.read(assetPageProvider).requireValue, hasLength(2));
  });
}
