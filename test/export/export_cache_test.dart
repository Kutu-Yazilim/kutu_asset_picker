import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/src/export/export_cache.dart';
import 'package:kutu_asset_picker/src/result/picked_asset.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

late Directory exportDir;

PickedImage picked(File file) => PickedImage(
      id: file.path,
      file: file,
      mimeType: 'image/jpeg',
      sizeBytes: file.lengthSync(),
      width: 100,
      height: 100,
      aspectRatio: 1,
    );

File write(String name) =>
    File('${exportDir.path}/$name')..writeAsBytesSync(List<int>.filled(8, 1));

void main() {
  setUp(() {
    exportDir = Directory.systemTemp.createTempSync('kutu_media_transform');
    ExportCache.reset();
  });
  tearDown(() {
    if (exportDir.existsSync()) exportDir.deleteSync(recursive: true);
    ExportCache.reset();
  });

  test('rememberAll records the directory the plugin chose', () {
    ExportCache.rememberAll([picked(write('a.jpg')), picked(write('b.jpg'))]);

    // One entry, not two: both files came out of the same namespaced dir.
    expect(ExportCache.directories, {exportDir.path});
  });

  test('clear deletes the directory and forgets it', () async {
    ExportCache.rememberAll([picked(write('a.jpg'))]);

    await ExportCache.clear();

    expect(exportDir.existsSync(), isFalse);
    expect(ExportCache.directories, isEmpty);
  });

  test('clear is safe when the directory is already gone', () async {
    ExportCache.rememberAll([picked(write('a.jpg'))]);
    exportDir.deleteSync(recursive: true);

    // The consumer owns these files and may have moved or deleted them
    // already. Collecting is best-effort by definition.
    await expectLater(ExportCache.clear(), completes);
    expect(ExportCache.directories, isEmpty);
  });

  test('clear on a fresh cache is a no-op, not an error', () async {
    await expectLater(ExportCache.clear(), completes);
    expect(ExportCache.directories, isEmpty);
  });

  test('originals and cover frames are collected too', () async {
    final File original = write('a.orig');
    final File cover = write('a.cover.jpg');
    ExportCache.rememberAll([
      PickedVideo(
        id: 'v',
        file: write('v.mp4'),
        mimeType: 'video/mp4',
        sizeBytes: 8,
        width: 100,
        height: 100,
        aspectRatio: 1,
        originalFile: original,
        duration: const Duration(seconds: 3),
        trimmed: const DurationRange(
          start: Duration.zero,
          end: Duration(seconds: 3),
        ),
        coverFrame: cover,
      ),
    ]);

    await ExportCache.clear();

    expect(original.existsSync(), isFalse);
    expect(cover.existsSync(), isFalse);
  });
}
