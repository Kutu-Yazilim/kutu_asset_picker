import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/source/photo_manager_mappers.dart';
import 'package:photo_manager/photo_manager.dart';

/// `AssetType.other == 0`, `image == 1`, `video == 2`, `audio == 3`.
const int _imageTypeInt = 1;
const int _videoTypeInt = 2;
const int _audioTypeInt = 3;

void main() {
  group('pickerAssetFrom', () {
    test('maps an image, leaving duration null', () {
      final AssetEntity entity = AssetEntity(
        id: 'img-1',
        typeInt: _imageTypeInt,
        width: 4032,
        height: 3024,
        createDateSecond: 1785000000,
      );

      final PickerAsset asset = pickerAssetFrom(entity)!;

      expect(asset.id, 'img-1');
      expect(asset.type, PickerMediaType.image);
      expect(asset.width, 4032);
      expect(asset.height, 3024);
      expect(asset.duration, isNull);
      expect(asset.createdAt,
          DateTime.fromMillisecondsSinceEpoch(1785000000 * 1000));
    });

    test('maps a video duration from seconds to a Duration', () {
      final AssetEntity entity = AssetEntity(
        id: 'vid-1',
        typeInt: _videoTypeInt,
        width: 1920,
        height: 1080,
        duration: 47,
        createDateSecond: 1785000000,
      );

      final PickerAsset asset = pickerAssetFrom(entity)!;

      expect(asset.type, PickerMediaType.video);
      expect(asset.duration, const Duration(seconds: 47));
    });

    test('a video with absent duration metadata maps to a null duration', () {
      // photo_manager types `AssetEntity.duration` as a non-nullable int and
      // reports 0 when the platform has no value. Passing that straight
      // through would render a "0:00" chip on a video that is minutes long;
      // null lets the UI omit the chip instead (design §4.5). This is the same
      // asset class the query filter's `allowNullable: true` keeps visible —
      // the two fixes are useless apart.
      final AssetEntity entity = AssetEntity(
        id: 'vid-null-duration',
        typeInt: _videoTypeInt,
        width: 1920,
        height: 1080,
        createDateSecond: 1785000000,
      );

      final PickerAsset asset = pickerAssetFrom(entity)!;

      expect(entity.duration, 0, reason: 'photo_manager reports 0, not null');
      expect(asset.type, PickerMediaType.video);
      expect(asset.duration, isNull);
    });

    test('does not apply Android-only orientation to the dimensions', () {
      // design §7.2: `AssetEntity.orientation` is Android-only and always 0 on
      // iOS/macOS, so `orientatedWidth`/`orientatedHeight` would make the same
      // photo report different dimensions per platform.
      final AssetEntity entity = AssetEntity(
        id: 'img-rotated',
        typeInt: _imageTypeInt,
        width: 4032,
        height: 3024,
        orientation: 90,
        createDateSecond: 1785000000,
      );

      final PickerAsset asset = pickerAssetFrom(entity)!;

      expect(entity.orientatedWidth, 3024, reason: 'photo_manager would flip');
      expect(asset.width, 4032);
      expect(asset.height, 3024);
    });

    test('drops audio and other, which the picker never surfaces', () {
      final AssetEntity audio = AssetEntity(
        id: 'aud-1',
        typeInt: _audioTypeInt,
        width: 0,
        height: 0,
        createDateSecond: 1785000000,
      );
      final AssetEntity other = AssetEntity(
        id: 'oth-1',
        typeInt: 0,
        width: 0,
        height: 0,
        createDateSecond: 1785000000,
      );

      expect(pickerAssetFrom(audio), isNull);
      expect(pickerAssetFrom(other), isNull);
    });
  });

  group('pickerAlbumFrom', () {
    test('carries id, name, count and the isAll flag', () {
      final AssetPathEntity path = AssetPathEntity(
        id: 'bucket-42',
        name: 'Camera',
        isAll: false,
      );

      final PickerAlbum album = pickerAlbumFrom(path, 128);

      expect(album.id, 'bucket-42');
      expect(album.name, 'Camera');
      expect(album.assetCount, 128);
      expect(album.isAll, isFalse);
    });

    test('preserves the root album flag', () {
      final AssetPathEntity path = AssetPathEntity(
        id: 'isAll__',
        name: 'Recent',
        isAll: true,
      );

      expect(pickerAlbumFrom(path, 900).isAll, isTrue);
    });
  });
}
