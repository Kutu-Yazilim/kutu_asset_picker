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

  /// How often the playhead is refreshed from the player while it plays.
  ///
  /// `video_player` refreshes its own position only every 500 ms, too coarse
  /// for a line the author reads a trim point from, so playback asks the
  /// platform directly at this rate.
  static const Duration playbackPollInterval = Duration(milliseconds: 100);

  /// How far before the in point a polled position may sit before it counts
  /// as the platform having wrapped to the start of the file.
  ///
  /// A frame-accurate seek lands a few milliseconds early — AVPlayer reports
  /// the decoded frame's own time — and without this slack every poll after
  /// a seek to the in point would read as "before the in point" and seek
  /// again, freezing the picture on the first frame.
  static const Duration playbackWrapTolerance = Duration(milliseconds: 500);

  /// The playhead width.
  static const double playheadWidth = 2;

  /// The play/pause icon size.
  static const double playbackIconSize = 20;

  /// Translucency of the control bar's surface.
  static const double barSurfaceOpacity = 0.82;

  /// The gap between the crop window and the bar below it.
  static const double barInset = 12;

  /// The bar padding.
  static const double barPadding = 10;

  /// The bar content gap.
  static const double barContentGap = 8;

  /// Height of the bar's toggle/label row. Fixed rather than intrinsic — the
  /// same height as the aspect chips — so [barHeight] is a constant the stage
  /// can reserve before the bar is built.
  static const double barRowHeight = 32;

  /// The filmstrip height.
  static const double filmstripHeight = 44;

  /// The bar's laid-out height, derived from its parts. `CropStage` reserves
  /// a band of this height plus [barInset] under the crop window for every
  /// asset in a session that contains a video (spec §2.7), and it has to know
  /// the number before the bar exists, or the window could not be computed.
  static const double barHeight =
      barPadding * 2 + barRowHeight + barContentGap + filmstripHeight;

  /// What the stage reserves under the crop window: the bar and the gap above
  /// it.
  static const double barSlotHeight = barInset + barHeight;

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
