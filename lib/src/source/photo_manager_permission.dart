import 'package:photo_manager/photo_manager.dart';

import 'picker_media_type.dart';
import 'picker_permission.dart';

/// Maps `photo_manager`'s five-state permission enum onto the three states the
/// picker draws.
///
/// The gate is [PermissionStateExt.hasAccess] — authorized ∪ limited — and
/// **never** `isAuth`, which is true only for `authorized`. That single
/// mistake is what shows iOS-14-and-later limited users an empty grid
/// (design §4.2).
///
/// The negative test comes first on purpose: writing it as
/// `if (state == PermissionState.limited) return limited;` first would make
/// the `isAuth`/`hasAccess` substitution invisible to the test suite, because
/// the second branch would then only ever see non-limited states.
PickerPermission pickerPermissionFrom(PermissionState state) {
  if (!state.hasAccess) {
    return PickerPermission.denied;
  }
  return state == PermissionState.limited
      ? PickerPermission.limited
      : PickerPermission.full;
}

/// Translates the configured media kinds into a `photo_manager` request mask.
///
/// Audio is never requested: it is out of scope (design §14), and asking for
/// it would widen the runtime permission prompt for nothing.
RequestType requestTypeFor(Set<PickerMediaType> kinds) {
  RequestType type = const RequestType(0);
  if (kinds.contains(PickerMediaType.image)) {
    type = type | RequestType.image;
  }
  if (kinds.contains(PickerMediaType.video)) {
    type = type | RequestType.video;
  }
  // A zero mask would query for nothing and return an empty library, which is
  // indistinguishable from a permission failure to the user.
  return type.value == 0 ? RequestType.common : type;
}
