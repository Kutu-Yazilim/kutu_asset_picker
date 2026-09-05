import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';

void main() {
  group('PickerPermission.hasAccess', () {
    test('is true for full and limited, false for denied', () {
      // This getter is the whole point of the enum. Limited access is a
      // designed state, not a degraded one (design §2.10, §4.2).
      expect(PickerPermission.full.hasAccess, isTrue);
      expect(PickerPermission.limited.hasAccess, isTrue);
      expect(PickerPermission.denied.hasAccess, isFalse);
    });

    test('covers every enum value, so a new state cannot be forgotten', () {
      expect(PickerPermission.values, hasLength(3));
    });
  });

  group('PickerAsset', () {
    test('accepts a null duration for a video', () {
      // design §4.5: MediaStore's duration column is genuinely null for some
      // Android downloads and third-party recorders. The type must model that
      // rather than pretend every video has a duration.
      final PickerAsset asset = PickerAsset(
        id: 'v1',
        type: PickerMediaType.video,
        width: 1920,
        height: 1080,
        createdAt: DateTime.utc(2026, 8, 4),
      );
      expect(asset.duration, isNull);
    });

    test('compares by value', () {
      final DateTime created = DateTime.utc(2026, 8, 4);
      final PickerAsset a = PickerAsset(
        id: 'a1',
        type: PickerMediaType.image,
        width: 4032,
        height: 3024,
        createdAt: created,
      );
      final PickerAsset b = PickerAsset(
        id: 'a1',
        type: PickerMediaType.image,
        width: 4032,
        height: 3024,
        createdAt: created,
      );
      final PickerAsset other = PickerAsset(
        id: 'a2',
        type: PickerMediaType.image,
        width: 4032,
        height: 3024,
        createdAt: created,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(other)));
    });

    test('defaults isLivePhoto to false', () {
      final PickerAsset asset = PickerAsset(
        id: 'a1',
        type: PickerMediaType.image,
        width: 1,
        height: 1,
        createdAt: DateTime.utc(2026),
      );
      expect(asset.isLivePhoto, isFalse);
    });
  });

  group('PickerAlbum', () {
    test('compares by value and keeps the isAll flag', () {
      const PickerAlbum all = PickerAlbum(
        id: 'isAll__',
        name: 'Recent',
        assetCount: 120,
        isAll: true,
      );
      const PickerAlbum same = PickerAlbum(
        id: 'isAll__',
        name: 'Recent',
        assetCount: 120,
        isAll: true,
      );
      const PickerAlbum fewer = PickerAlbum(
        id: 'isAll__',
        name: 'Recent',
        assetCount: 119,
        isAll: true,
      );

      expect(all, equals(same));
      expect(all.hashCode, equals(same.hashCode));
      // The count participates in equality on purpose: after presentLimited the
      // album identity is unchanged but the count is stale, and a provider that
      // watches albums must see that as a change (design §4.2).
      expect(all, isNot(equals(fewer)));
      expect(all.isAll, isTrue);
    });
  });
}
