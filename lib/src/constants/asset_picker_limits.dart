/// Interaction ceilings and fling physics.
abstract final class AssetPickerLimits {
  const AssetPickerLimits._();

  /// Ceiling on pinch, as a multiple of the cover scale. Past roughly 8× a
  /// 12 MP source is showing individual sensor pixels, and the export would be
  /// upsampling.
  static const double maxZoomFactor = 8;

  /// Below this the gesture was a drag that stopped, not a fling.
  static const double minFlingVelocity = 50;

  /// Friction coefficient, and the speed at which a fling counts as stopped.
  /// Both are the values `InteractiveViewer` uses for its own ballistic
  /// animation, so a fling here decelerates exactly like every other Flutter
  /// surface.
  static const double flingDrag = 0.0000135;

  /// The fling motionless.
  static const double flingMotionless = 10;
}
