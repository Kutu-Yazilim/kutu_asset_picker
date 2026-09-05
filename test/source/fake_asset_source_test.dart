import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/testing.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

PickerAsset _image(String id) => PickerAsset(
      id: id,
      type: PickerMediaType.image,
      width: 100,
      height: 100,
      createdAt: DateTime.utc(2026, 8, 4),
    );

void main() {
  test('FakeAssetSource satisfies the AssetSource interface', () {
    expect(FakeAssetSource(), isA<AssetSource>());
  });

  test('records permission requests and returns the configured state', () async {
    final FakeAssetSource source =
        FakeAssetSource(permission: PickerPermission.limited);
    addTearDown(source.dispose);

    final PickerPermission result =
        await source.requestPermission(<PickerMediaType>{PickerMediaType.image});

    expect(result, PickerPermission.limited);
    expect(source.permissionRequests, <Set<PickerMediaType>>[
      <PickerMediaType>{PickerMediaType.image},
    ]);
  });

  test('pages assets by offset and count, clamping at the end', () async {
    const PickerAlbum album = PickerAlbum(
      id: 'all',
      name: 'Recent',
      assetCount: 5,
      isAll: true,
    );
    final FakeAssetSource source = FakeAssetSource(
      albumList: const <PickerAlbum>[album],
      assetsByAlbum: <String, List<PickerAsset>>{
        'all': <PickerAsset>[
          _image('a0'),
          _image('a1'),
          _image('a2'),
          _image('a3'),
          _image('a4'),
        ],
      },
    );
    addTearDown(source.dispose);

    final List<PickerAsset> first =
        await source.assets(album: album, offset: 0, count: 2);
    final List<PickerAsset> tail =
        await source.assets(album: album, offset: 4, count: 10);
    final List<PickerAsset> past =
        await source.assets(album: album, offset: 99, count: 10);

    expect(first.map((PickerAsset a) => a.id), <String>['a0', 'a1']);
    expect(tail.map((PickerAsset a) => a.id), <String>['a4']);
    expect(past, isEmpty);
    expect(source.assetQueries, hasLength(3));
    expect(source.assetQueries.first.offset, 0);
    expect(source.assetQueries.first.count, 2);
  });

  test('records the duration filter passed to albums()', () async {
    final FakeAssetSource source = FakeAssetSource();
    addTearDown(source.dispose);

    await source.albums(
      <PickerMediaType>{PickerMediaType.video},
      maxVideoDuration: const Duration(seconds: 60),
    );

    expect(source.albumQueries.single.maxVideoDuration,
        const Duration(seconds: 60));
  });

  test('file() can be held open and completed by the test', () async {
    final FakeAssetSource source = FakeAssetSource();
    addTearDown(source.dispose);
    source.pendingFiles.add('slow');

    final List<double> progress = <double>[];
    final Future<File?> pending =
        source.file('slow', onProgress: progress.add);

    source.emitFileProgress('slow', 0.5);
    expect(progress, <double>[0.5]);

    source.completeFile('slow', File('/tmp/slow.mp4'));
    expect((await pending)!.path, '/tmp/slow.mp4');
  });

  test('file() honours a cancel token by completing with null', () async {
    final FakeAssetSource source = FakeAssetSource();
    addTearDown(source.dispose);
    source.pendingFiles.add('slow');

    final TransformCancelToken token = TransformCancelToken();
    final Future<File?> pending = source.file('slow', cancelToken: token);
    source.completeFile('slow', null);

    expect(await pending, isNull);
    expect(token.isCancelled, isFalse);
  });

  test('isLocallyAvailable reports the configured cloud-only set', () async {
    final FakeAssetSource source = FakeAssetSource();
    addTearDown(source.dispose);
    source.locallyUnavailable.add('cloud');

    expect(await source.isLocallyAvailable('cloud'), isFalse);
    expect(await source.isLocallyAvailable('local'), isTrue);
  });

  test('manageLimitedSelection is counted and emits a change', () async {
    final FakeAssetSource source = FakeAssetSource();
    addTearDown(source.dispose);

    final Future<void> seen = source.changes.first;
    await source.manageLimitedSelection(<PickerMediaType>{PickerMediaType.image});
    source.emitChange();
    await seen;

    expect(source.manageLimitedSelectionCalls, 1);
  });

  test('thumbnail returns the configured bytes', () async {
    final FakeAssetSource source = FakeAssetSource();
    addTearDown(source.dispose);

    final Uint8List? bytes =
        await source.thumbnail('a0', const ThumbSize.square(200));

    expect(bytes, isNotNull);
    expect(bytes, same(source.thumbnailBytes));
  });
}
