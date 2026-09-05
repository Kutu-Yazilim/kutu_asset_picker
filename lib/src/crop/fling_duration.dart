import 'dart:math' as math;

import 'package:kutu_asset_picker/src/constants/asset_picker_limits.dart';

/// Seconds for a fling at [velocity] px/s to decelerate to a standstill.
///
/// The same closed form `InteractiveViewer` uses for its own ballistic
/// animation, so a fling here decays exactly like every other Flutter surface.
/// Returns 0 when the gesture was already effectively motionless, which is the
/// caller's signal not to animate at all.
double flingDuration(double velocity) {
  if (velocity <= AssetPickerLimits.flingMotionless) return 0;
  return math.log(AssetPickerLimits.flingMotionless / velocity) /
      math.log(AssetPickerLimits.flingDrag / 100);
}
