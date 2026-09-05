import 'dart:ui' show Color;

/// The only raw `Color` literals in the package.
///
/// Chrome that sits **on top of an arbitrary photograph** cannot be derived
/// from the consumer's `ColorScheme`: a dark scheme's `onSurface` is nearly
/// black, which is invisible over a night shot. `apps/mobile` keeps
/// `AppColorsCommon.onMedia` for the identical reason. Flutter rule 8 forbids
/// raw colors in *widgets* — this is the theme layer, which is where they are
/// allowed to live, and every one of them is still overridable through
/// [AssetPickerTheme].
abstract final class AssetPickerMediaColors {
  const AssetPickerMediaColors._();

  static const Color onMedia = Color(0xFFFFFFFF);
  static const Color scrim = Color(0xFF000000);
}
