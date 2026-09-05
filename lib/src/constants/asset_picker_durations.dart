/// Animation timings. Flutter rule 3.
abstract final class AssetPickerDurations {
  const AssetPickerDurations._();

  /// Rule-of-thirds grid fading in as a gesture starts and out on release.
  /// Short: it is a guide, not a transition.
  static const Duration thirdsFade = Duration(milliseconds: 160);

  /// Chip fill/label cross-fade on ratio change.
  static const Duration chipSwap = Duration(milliseconds: 150);

  /// Only used if a fling's computed duration is not finite.
  static const Duration flingFallback = Duration(milliseconds: 300);
}
