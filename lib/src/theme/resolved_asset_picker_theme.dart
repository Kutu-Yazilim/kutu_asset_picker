import 'package:flutter/material.dart';

/// The theme after resolution: every field non-null.
///
/// Widgets read **this**, never `AssetPickerTheme` directly, so no widget ever
/// writes a `??` fallback of its own and no two widgets can disagree about
/// what an unset token means.
@immutable
final class ResolvedAssetPickerTheme {
  const ResolvedAssetPickerTheme({
    required this.background,
    required this.surface,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.selectionBadgeFill,
    required this.selectionBadgeText,
    required this.selectionBadgeBorder,
    required this.disabledOverlay,
    required this.danger,
    required this.progressIndicator,
    required this.titleStyle,
    required this.labelStyle,
    required this.badgeStyle,
    required this.cellRadius,
    required this.sheetRadius,
  });

  final Color background;
  final Color surface;
  final Color onSurface;
  final Color onSurfaceMuted;

  final Color selectionBadgeFill;
  final Color selectionBadgeText;
  final Color selectionBadgeBorder;

  final Color disabledOverlay;
  final Color danger;
  final Color progressIndicator;

  final TextStyle titleStyle;
  final TextStyle labelStyle;
  final TextStyle badgeStyle;

  final double cellRadius;
  final double sheetRadius;
}
