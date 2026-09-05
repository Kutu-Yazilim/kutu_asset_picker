/// Every number the video crop step uses.
///
/// Flutter rule 3: no magic numbers in widgets or logic. If a value appears in
/// a widget in this directory and is not here, it is a rule violation.
abstract final class VideoCropConstants {
  /// The shortest clip a trim may produce. Below this the handles become
  /// impossible to separate and the encoder has almost nothing to work with.
  static const Duration minTrimDuration = Duration(milliseconds: 500);

  /// Frames sampled across the whole clip for the filmstrip.
  static const int filmstripFrameCount = 12;

  /// Long edge requested per filmstrip frame. Deliberately small: Android has
  /// no batch frame API, so each of these is a separate
  /// `MediaMetadataRetriever.getFrameAtTime` call (spec §6.3).
  static const int filmstripFrameEdge = 96;

  /// Floor between two seeks. Apple QA1820: rapid successive `seekToTime:`
  /// calls cancel one another.
  static const Duration seekDebounce = Duration(milliseconds: 40);

  /// The bar fade duration.
  static const Duration barFadeDuration = Duration(milliseconds: 160);

  /// The bar opacity idle.
  static const double barOpacityIdle = 1;

  /// The bar opacity dragging.
  static const double barOpacityDragging = 0;

  /// Translucency of the floating bar over the footage (spec §2.7).
  static const double barSurfaceOpacity = 0.82;

  /// The bar inset.
  static const double barInset = 12;

  /// The bar padding.
  static const double barPadding = 10;

  /// The bar content gap.
  static const double barContentGap = 8;

  /// The filmstrip height.
  static const double filmstripHeight = 44;

  /// The handle width.
  static const double handleWidth = 14;

  /// The handle grip width.
  static const double handleGripWidth = 2;

  /// The handle grip height.
  static const double handleGripHeight = 14;

  /// The cover cursor width.
  static const double coverCursorWidth = 4;

  /// Dimming over the parts of the filmstrip outside the trim range.
  static const double maskOpacity = 0.6;

  /// The toggle gap.
  static const double toggleGap = 6;
}
