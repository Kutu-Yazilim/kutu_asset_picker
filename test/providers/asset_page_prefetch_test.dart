import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/testing.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

const PickerAlbum _recent =
    PickerAlbum(id: 'all', name: 'Recent', assetCount: 200, isAll: true);

PickerAsset _image(String id) => PickerAsset(
      id: id,
      type: PickerMediaType.image,
      width: 100,
      height: 100,
      createdAt: DateTime.utc(2026, 8, 4),
    );

List<PickerAsset> _images(int count) =>
    <PickerAsset>[for (int i = 0; i < count; i += 1) _image('a$i')];

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
  test('the loaded page is warmed at the configured size and quality',
      () async {
    final FakeAssetSource source = FakeAssetSource(
      albumList: const <PickerAlbum>[_recent],
      assetsByAlbum: <String, List<PickerAsset>>{'all': _images(200)},
    );
    addTearDown(source.dispose);
    final ProviderContainer container = _container(
      source,
      config: const AssetPickerConfig(thumbSize: ThumbSize.square(320)),
    );

    container.read(currentAlbumProvider.notifier).select(_recent);
    await container.read(assetPageProvider.future);
    await container.pump();

    expect(source.prefetchQueries, hasLength(1));
    expect(source.prefetchQueries.single.ids,
        hasLength(PickerGridTuning.pageSize));
    expect(source.prefetchQueries.single.ids.first, 'a0');
    expect(source.prefetchQueries.single.size.width, 320);
    expect(source.prefetchQueries.single.quality,
        PickerGridTuning.thumbnailQuality);
  });

  test('loadMore warms the page it just appended, not the whole list',
      () async {
    final FakeAssetSource source = FakeAssetSource(
      albumList: const <PickerAlbum>[_recent],
      assetsByAlbum: <String, List<PickerAsset>>{'all': _images(200)},
    );
    addTearDown(source.dispose);
    final ProviderContainer container = _container(source);

    container.read(currentAlbumProvider.notifier).select(_recent);
    await container.read(assetPageProvider.future);
    await container.read(assetPageProvider.notifier).loadMore();
    await container.pump();

    expect(source.prefetchQueries, hasLength(2));
    expect(
        source.prefetchQueries.last.ids, hasLength(PickerGridTuning.pageSize));
    expect(
        source.prefetchQueries.last.ids.first, 'a${PickerGridTuning.pageSize}');
  });

  test('AN EXPERIMENTAL PREFETCH THAT THROWS MUST NOT BREAK PAGING', () async {
    // design §4.4: photo_manager files PhotoCachingManager under
    // "Experimental". A warm-ahead is an optimisation; it is never allowed to
    // take the grid down with it, so the caller guards even though the
    // production implementation already swallows.
    final FakeAssetSource source = FakeAssetSource(
      albumList: const <PickerAlbum>[_recent],
      assetsByAlbum: <String, List<PickerAsset>>{'all': _images(200)},
    )..prefetchThrows = true;
    addTearDown(source.dispose);
    final ProviderContainer container = _container(source);

    container.read(currentAlbumProvider.notifier).select(_recent);
    final List<PickerAsset> page =
        await container.read(assetPageProvider.future);
    await container.pump();

    expect(page, hasLength(PickerGridTuning.pageSize));
    expect(container.read(assetPageProvider).hasError, isFalse);
    expect(source.prefetchQueries, hasLength(1),
        reason: 'it was attempted, it failed, and paging carried on');
  });

  test('an empty page warms nothing', () async {
    final FakeAssetSource source = FakeAssetSource(
      albumList: const <PickerAlbum>[_recent],
      assetsByAlbum: <String, List<PickerAsset>>{'all': const <PickerAsset>[]},
    );
    addTearDown(source.dispose);
    final ProviderContainer container = _container(source);

    container.read(currentAlbumProvider.notifier).select(_recent);
    await container.read(assetPageProvider.future);
    await container.pump();

    expect(source.prefetchQueries, isEmpty);
  });
}
