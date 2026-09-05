import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/source/photo_manager_permission.dart';
import 'package:photo_manager/photo_manager.dart';

void main() {
  group('pickerPermissionFrom', () {
    test('authorized is full access', () {
      expect(
        pickerPermissionFrom(PermissionState.authorized),
        PickerPermission.full,
      );
    });

    test('LIMITED IS ACCESS, NOT DENIAL', () {
      // THE regression test for this package (design §4.2).
      //
      // `PermissionState.limited.isAuth` is FALSE — `isAuth` is true only for
      // `authorized`. An implementation that gates on `isAuth` therefore maps
      // limited to denied, and every iOS-14+ limited user and Android 14+
      // partial-access user sees an empty grid instead of their granted
      // subset. The gate must branch on `hasAccess`, which is
      // authorized ∪ limited.
      //
      // If you are reading this because the test just went red: you changed
      // `hasAccess` to `isAuth`. Change it back.
      expect(PermissionState.limited.isAuth, isFalse,
          reason: 'photo_manager contract this test depends on');
      expect(PermissionState.limited.hasAccess, isTrue,
          reason: 'photo_manager contract this test depends on');

      expect(
        pickerPermissionFrom(PermissionState.limited),
        PickerPermission.limited,
      );
    });

    test('every non-access state is denied', () {
      expect(
        pickerPermissionFrom(PermissionState.denied),
        PickerPermission.denied,
      );
      expect(
        pickerPermissionFrom(PermissionState.restricted),
        PickerPermission.denied,
      );
      expect(
        pickerPermissionFrom(PermissionState.notDetermined),
        PickerPermission.denied,
      );
    });

    test('maps every PermissionState value, so a new one cannot be missed', () {
      for (final PermissionState state in PermissionState.values) {
        expect(() => pickerPermissionFrom(state), returnsNormally);
      }
      // Exactly one state maps to limited.
      expect(
        PermissionState.values
            .where((PermissionState s) =>
                pickerPermissionFrom(s) == PickerPermission.limited)
            .length,
        1,
      );
    });
  });

  group('requestTypeFor', () {
    test('images only', () {
      expect(
        requestTypeFor(<PickerMediaType>{PickerMediaType.image}).value,
        RequestType.image.value,
      );
    });

    test('videos only', () {
      expect(
        requestTypeFor(<PickerMediaType>{PickerMediaType.video}).value,
        RequestType.video.value,
      );
    });

    test('both is the common type, and never includes audio', () {
      final RequestType both = requestTypeFor(<PickerMediaType>{
        PickerMediaType.image,
        PickerMediaType.video,
      });
      expect(both.value, RequestType.common.value);
      expect(both.containsAudio(), isFalse);
    });

    test('an empty set degrades to common rather than requesting nothing', () {
      // A zero-valued RequestType would ask the platform for no media at all
      // and return an empty library, which reads to the user exactly like a
      // permission failure. AssetPickerConfig already asserts a non-empty
      // mediaTypes set; this is the belt.
      expect(
        requestTypeFor(const <PickerMediaType>{}).value,
        RequestType.common.value,
      );
    });
  });
}
