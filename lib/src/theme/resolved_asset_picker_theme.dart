import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// The theme after resolution: every field non-null.
///
/// Widgets read **this**, never `AssetPickerTheme` directly, so no widget ever
/// writes a `??` fallback of its own and no two widgets can disagree about
/// what an unset token means.
@immutable
final class ResolvedAssetPickerTheme {
  /// Creates a [ResolvedAssetPickerTheme].
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

  /// The background.
  final Color background;

  /// The surface.
  final Color surface;

  /// The on surface.
  final Color onSurface;

  /// The on surface muted.
  final Color onSurfaceMuted;

  /// The selection badge fill.
  final Color selectionBadgeFill;

  /// The selection badge text.
  final Color selectionBadgeText;

  /// The selection badge border.
  final Color selectionBadgeBorder;

  /// Dimming outside the crop window.
  final Color cropMask;

  /// Rule-of-thirds lines.
  final Color cropGridLine;

  /// The crop window border.
  final Color cropWindowBorder;

  /// The chip selected fill.
  final Color chipSelectedFill;

  /// The chip unselected fill.
  final Color chipUnselectedFill;

  /// The chip selected text.
  final Color chipSelectedText;

  /// The chip unselected text.
  final Color chipUnselectedText;

  /// The disabled overlay.
  final Color disabledOverlay;

  /// The danger.
  final Color danger;

  /// The progress indicator.
  final Color progressIndicator;

  /// The title style.
  final TextStyle titleStyle;

  /// The label style.
  final TextStyle labelStyle;

  /// The badge style.
  final TextStyle badgeStyle;

  /// The cell radius.
  final double cellRadius;

  /// The chip radius.
  final double chipRadius;

  /// The sheet radius.
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
