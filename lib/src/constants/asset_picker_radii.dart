/// The chip corner radius the resolved theme falls back to when the consumer
/// supplies none. Kept out of the theme file so the theme reads as pure
/// plumbing.
///
/// Only `chip` lives here. The cell and sheet radii are slice 3's
/// `PickerChromeSizes.cellRadius` / `PickerChromeSizes.sheetRadius` and
/// `AssetPickerTheme.resolve` already falls back to those — a second copy of
/// those two numbers is exactly the drift Flutter rule 3 exists to prevent.
abstract final class AssetPickerRadii {
  const AssetPickerRadii._();

  /// A pill: half of `AssetPickerSizes.chipHeight`, rounded up.
  static const double chip = 20;
}
