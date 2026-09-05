import 'package:flutter/foundation.dart';
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
    required this.cropMask,
    required this.cropGridLine,
    required this.cropWindowBorder,
    required this.chipSelectedFill,
    required this.chipUnselectedFill,
    required this.chipSelectedText,
    required this.chipUnselectedText,
    required this.disabledOverlay,
    required this.danger,
    required this.progressIndicator,
    required this.titleStyle,
    required this.labelStyle,
    required this.badgeStyle,
    required this.cellRadius,
    required this.chipRadius,
    required this.sheetRadius,
  });

  final Color background;
  final Color surface;
  final Color onSurface;
  final Color onSurfaceMuted;

  final Color selectionBadgeFill;
  final Color selectionBadgeText;
  final Color selectionBadgeBorder;

  /// Dimming outside the crop window.
  final Color cropMask;

  /// Rule-of-thirds lines.
  final Color cropGridLine;

  final Color cropWindowBorder;
  final Color chipSelectedFill;
  final Color chipUnselectedFill;
  final Color chipSelectedText;
  final Color chipUnselectedText;

  final Color disabledOverlay;
  final Color danger;
  final Color progressIndicator;

  final TextStyle titleStyle;
  final TextStyle labelStyle;
  final TextStyle badgeStyle;

  final double cellRadius;
  final double chipRadius;
  final double sheetRadius;

  List<Object> get _props => <Object>[
        background,
        surface,
        onSurface,
        onSurfaceMuted,
        selectionBadgeFill,
        selectionBadgeText,
        selectionBadgeBorder,
        cropMask,
        cropGridLine,
        cropWindowBorder,
        chipSelectedFill,
        chipUnselectedFill,
        chipSelectedText,
        chipUnselectedText,
        disabledOverlay,
        danger,
        progressIndicator,
        titleStyle,
        labelStyle,
        badgeStyle,
        cellRadius,
        chipRadius,
        sheetRadius,
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResolvedAssetPickerTheme && listEquals(other._props, _props);

  @override
  int get hashCode => Object.hashAll(_props);
}
