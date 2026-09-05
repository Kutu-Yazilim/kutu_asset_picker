import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/picker/flattened_asset_source.dart';
import 'package:kutu_asset_picker/testing.dart';

void main() {
  late Directory tempDir;
  late File rewritten;
  late FakeAssetSource delegate;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('kutu_flattened_source');
    rewritten = File('${tempDir.path}/flat.mp4')..writeAsBytesSync([9]);
    delegate = FakeAssetSource(
      albumList: const [
        PickerAlbum(id: 'all', name: 'All', assetCount: 2, isAll: true),
      ],
    );
  });

  tearDown(() async {
    await delegate.dispose();
    tempDir.deleteSync(recursive: true);
  });

  FlattenedAssetSource sourceWith(Map<String, File> flattened) =>
      FlattenedAssetSource(delegate: delegate, flattened: flattened);

  test('a rewritten id serves the flattened file, not the gallery original',
      () async {
    expect((await sourceWith({'slow': rewritten}).file('slow'))!.path,
        rewritten.path);
  });

  test('an untouched id falls straight through to the delegate', () async {
    delegate.filesById['plain'] = File('${tempDir.path}/plain.mp4')
      ..writeAsBytesSync([1]);

    expect(
      (await sourceWith({'slow': rewritten}).file('plain'))!.path,
      endsWith('plain.mp4'),
    );
  });

  test('a rewritten file reports complete rather than stalling at zero',
      () async {
    final seen = <double>[];

    await sourceWith({'slow': rewritten}).file('slow', onProgress: seen.add);

    expect(seen, [1]);
  });

  test('a rewritten id is locally available by definition', () async {
    // It is a file this process just wrote. Asking the gallery whether its
    // iCloud original is downloaded would be answering a different question.
    delegate.locallyUnavailable.add('slow');

    expect(
      await sourceWith({'slow': rewritten}).isLocallyAvailable('slow'),
      isTrue,
    );
    expect(
      await sourceWith(const <String, File>{}).isLocallyAvailable('slow'),
      isFalse,
    );
  });

  test('everything that is not a file lookup is the delegate, untouched',
      () async {
    final source = sourceWith({'slow': rewritten});

    expect(
      await source.requestPermission(const {PickerMediaType.image}),
      PickerPermission.full,
    );
    expect(
        (await source.albums(const {PickerMediaType.video})).single.id, 'all');
    expect(delegate.permissionRequests.single, const {PickerMediaType.image});

    await source.manageLimitedSelection(const {PickerMediaType.video});
    expect(delegate.manageLimitedSelectionCalls, 1);
  });

  test('library-change events pass through', () async {
    final source = sourceWith({'slow': rewritten});
    final first = source.changes.first;

    delegate.emitChange();

    await first; // A dropped stream would hang here until the test times out.
  });
}
