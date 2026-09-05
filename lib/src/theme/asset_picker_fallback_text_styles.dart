import 'package:flutter/painting.dart';

/// Used when the ambient `TextTheme` slot is null.
///
/// `TextTheme`'s getters are nullable and a bare `ThemeData()` does populate
/// them, but a consumer who hands in a hand-built `TextTheme` can leave holes.
/// The resolved theme promises non-null, so the holes are filled here.
abstract final class AssetPickerFallbackTextStyles {
  const AssetPickerFallbackTextStyles._();

  static const TextStyle title =
      TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  static const TextStyle label =
      TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
  static const TextStyle badge =
      TextStyle(fontSize: 11, fontWeight: FontWeight.w700);
}
