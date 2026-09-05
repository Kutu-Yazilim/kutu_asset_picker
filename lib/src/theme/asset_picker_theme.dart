import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import '../config/picker_tuning.dart';
import '../constants/asset_picker_radii.dart';
import 'asset_picker_media_colors.dart';
import 'asset_picker_fallback_text_styles.dart';
import 'resolved_asset_picker_theme.dart';

/// The picker's design tokens.
///
/// Every field is nullable and resolution runs
/// *widget argument → the app's `ThemeExtension` → `ColorScheme`/`TextTheme`*
/// (design §8.1). Nullable-plus-`ColorScheme`-fallback is the adoption-critical
/// property: configure nothing and the picker still looks native.
///
/// Being a `ThemeExtension` rather than a plain config object also buys [lerp],
/// so a light/dark switch cross-fades instead of hard-cutting.
///
/// Slice 4 adds the crop tokens — `cropMask`, `cropGridLine`,
/// `cropWindowBorder`, the four `chip*` colors and `chipRadius` — to this
/// class, to [ResolvedAssetPickerTheme], and to [copyWith]/[lerp]/[resolve].
@immutable
final class AssetPickerTheme extends ThemeExtension<AssetPickerTheme> {
  const AssetPickerTheme({
    this.background,
    this.surface,
    this.onSurface,
    this.onSurfaceMuted,
    this.selectionBadgeFill,
    this.selectionBadgeText,
    this.selectionBadgeBorder,
    this.cropMask,
    this.cropGridLine,
    this.cropWindowBorder,
    this.chipSelectedFill,
    this.chipUnselectedFill,
    this.chipSelectedText,
    this.chipUnselectedText,
    this.disabledOverlay,
    this.danger,
    this.progressIndicator,
    this.titleStyle,
    this.labelStyle,
    this.badgeStyle,
    this.cellRadius,
    this.chipRadius,
    this.sheetRadius,
  });

  final Color? background;
  final Color? surface;
  final Color? onSurface;
  final Color? onSurfaceMuted;

  final Color? selectionBadgeFill;
  final Color? selectionBadgeText;
  final Color? selectionBadgeBorder;

  /// Dimming outside the crop window.
  final Color? cropMask;

  /// Rule-of-thirds lines.
  final Color? cropGridLine;

  final Color? cropWindowBorder;
  final Color? chipSelectedFill;
  final Color? chipUnselectedFill;
  final Color? chipSelectedText;
  final Color? chipUnselectedText;

  final Color? disabledOverlay;
  final Color? danger;
  final Color? progressIndicator;

  final TextStyle? titleStyle;
  final TextStyle? labelStyle;
  final TextStyle? badgeStyle;

  final double? cellRadius;
  final double? chipRadius;
  final double? sheetRadius;

  @override
  AssetPickerTheme copyWith({
    Color? background,
    Color? surface,
    Color? onSurface,
    Color? onSurfaceMuted,
    Color? selectionBadgeFill,
    Color? selectionBadgeText,
    Color? selectionBadgeBorder,
    Color? cropMask,
    Color? cropGridLine,
    Color? cropWindowBorder,
    Color? chipSelectedFill,
    Color? chipUnselectedFill,
    Color? chipSelectedText,
    Color? chipUnselectedText,
    double? chipRadius,
    Color? disabledOverlay,
    Color? danger,
    Color? progressIndicator,
    TextStyle? titleStyle,
    TextStyle? labelStyle,
    TextStyle? badgeStyle,
    double? cellRadius,
    double? sheetRadius,
  }) =>
      AssetPickerTheme(
        background: background ?? this.background,
        surface: surface ?? this.surface,
        onSurface: onSurface ?? this.onSurface,
        onSurfaceMuted: onSurfaceMuted ?? this.onSurfaceMuted,
        selectionBadgeFill: selectionBadgeFill ?? this.selectionBadgeFill,
        selectionBadgeText: selectionBadgeText ?? this.selectionBadgeText,
        selectionBadgeBorder: selectionBadgeBorder ?? this.selectionBadgeBorder,
        cropMask: cropMask ?? this.cropMask,
        cropGridLine: cropGridLine ?? this.cropGridLine,
        cropWindowBorder: cropWindowBorder ?? this.cropWindowBorder,
        chipSelectedFill: chipSelectedFill ?? this.chipSelectedFill,
        chipUnselectedFill: chipUnselectedFill ?? this.chipUnselectedFill,
        chipSelectedText: chipSelectedText ?? this.chipSelectedText,
        chipUnselectedText: chipUnselectedText ?? this.chipUnselectedText,
        chipRadius: chipRadius ?? this.chipRadius,
        disabledOverlay: disabledOverlay ?? this.disabledOverlay,
        danger: danger ?? this.danger,
        progressIndicator: progressIndicator ?? this.progressIndicator,
        titleStyle: titleStyle ?? this.titleStyle,
        labelStyle: labelStyle ?? this.labelStyle,
        badgeStyle: badgeStyle ?? this.badgeStyle,
        cellRadius: cellRadius ?? this.cellRadius,
        sheetRadius: sheetRadius ?? this.sheetRadius,
      );

  @override
  AssetPickerTheme lerp(ThemeExtension<AssetPickerTheme>? other, double t) {
    if (other is! AssetPickerTheme) {
      return this;
    }
    return AssetPickerTheme(
      background: Color.lerp(background, other.background, t),
      surface: Color.lerp(surface, other.surface, t),
      onSurface: Color.lerp(onSurface, other.onSurface, t),
      onSurfaceMuted: Color.lerp(onSurfaceMuted, other.onSurfaceMuted, t),
      selectionBadgeFill:
          Color.lerp(selectionBadgeFill, other.selectionBadgeFill, t),
      selectionBadgeText:
          Color.lerp(selectionBadgeText, other.selectionBadgeText, t),
      selectionBadgeBorder:
          Color.lerp(selectionBadgeBorder, other.selectionBadgeBorder, t),
      cropMask: Color.lerp(cropMask, other.cropMask, t),
      cropGridLine: Color.lerp(cropGridLine, other.cropGridLine, t),
      cropWindowBorder: Color.lerp(cropWindowBorder, other.cropWindowBorder, t),
      chipSelectedFill: Color.lerp(chipSelectedFill, other.chipSelectedFill, t),
      chipUnselectedFill:
          Color.lerp(chipUnselectedFill, other.chipUnselectedFill, t),
      chipSelectedText: Color.lerp(chipSelectedText, other.chipSelectedText, t),
      chipUnselectedText:
          Color.lerp(chipUnselectedText, other.chipUnselectedText, t),
      chipRadius: lerpDouble(chipRadius, other.chipRadius, t),
      disabledOverlay: Color.lerp(disabledOverlay, other.disabledOverlay, t),
      danger: Color.lerp(danger, other.danger, t),
      progressIndicator:
          Color.lerp(progressIndicator, other.progressIndicator, t),
      titleStyle: TextStyle.lerp(titleStyle, other.titleStyle, t),
      labelStyle: TextStyle.lerp(labelStyle, other.labelStyle, t),
      badgeStyle: TextStyle.lerp(badgeStyle, other.badgeStyle, t),
      cellRadius: lerpDouble(cellRadius, other.cellRadius, t),
      sheetRadius: lerpDouble(sheetRadius, other.sheetRadius, t),
    );
  }

  /// Resolves tokens for [context]: [override] → the app's extension →
  /// `ColorScheme`/`TextTheme`.
  static ResolvedAssetPickerTheme resolve(
    BuildContext context, [
    AssetPickerTheme? override,
  ]) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final TextTheme text = theme.textTheme;
    final AssetPickerTheme? extension = theme.extension<AssetPickerTheme>();

    T pick<T extends Object>(
      T? Function(AssetPickerTheme source) read,
      T fallback,
    ) {
      final T? fromOverride = override == null ? null : read(override);
      if (fromOverride != null) {
        return fromOverride;
      }
      final T? fromExtension = extension == null ? null : read(extension);
      return fromExtension ?? fallback;
    }

    return ResolvedAssetPickerTheme(
      background: pick((AssetPickerTheme t) => t.background, colors.surface),
      surface: pick(
          (AssetPickerTheme t) => t.surface, colors.surfaceContainerHighest),
      onSurface: pick((AssetPickerTheme t) => t.onSurface, colors.onSurface),
      onSurfaceMuted: pick(
          (AssetPickerTheme t) => t.onSurfaceMuted, colors.onSurfaceVariant),
      selectionBadgeFill:
          pick((AssetPickerTheme t) => t.selectionBadgeFill, colors.primary),
      selectionBadgeText:
          pick((AssetPickerTheme t) => t.selectionBadgeText, colors.onPrimary),
      selectionBadgeBorder: pick(
          (AssetPickerTheme t) => t.selectionBadgeBorder, colors.onPrimary),
      cropMask: pick(
        (AssetPickerTheme t) => t.cropMask,
        AssetPickerMediaColors.scrim.withValues(alpha: 0.72),
      ),
      cropGridLine: pick(
        (AssetPickerTheme t) => t.cropGridLine,
        AssetPickerMediaColors.onMedia.withValues(alpha: 0.55),
      ),
      cropWindowBorder: pick(
        (AssetPickerTheme t) => t.cropWindowBorder,
        AssetPickerMediaColors.onMedia.withValues(alpha: 0.9),
      ),
      chipSelectedFill:
          pick((AssetPickerTheme t) => t.chipSelectedFill, colors.primary),
      chipUnselectedFill: pick(
        (AssetPickerTheme t) => t.chipUnselectedFill,
        colors.surfaceContainerHighest,
      ),
      chipSelectedText:
          pick((AssetPickerTheme t) => t.chipSelectedText, colors.onPrimary),
      chipUnselectedText: pick(
        (AssetPickerTheme t) => t.chipUnselectedText,
        colors.onSurfaceVariant,
      ),
      chipRadius:
          pick((AssetPickerTheme t) => t.chipRadius, AssetPickerRadii.chip),
      disabledOverlay: pick(
        (AssetPickerTheme t) => t.disabledOverlay,
        colors.scrim
            .withValues(alpha: PickerChromeSizes.disabledOverlayOpacity),
      ),
      danger: pick((AssetPickerTheme t) => t.danger, colors.error),
      progressIndicator:
          pick((AssetPickerTheme t) => t.progressIndicator, colors.primary),
      titleStyle: pick(
        (AssetPickerTheme t) => t.titleStyle,
        text.titleMedium ?? AssetPickerFallbackTextStyles.title,
      ),
      labelStyle: pick(
        (AssetPickerTheme t) => t.labelStyle,
        text.bodySmall ?? AssetPickerFallbackTextStyles.label,
      ),
      badgeStyle: pick(
        (AssetPickerTheme t) => t.badgeStyle,
        text.labelSmall ?? AssetPickerFallbackTextStyles.badge,
      ),
      cellRadius: pick(
          (AssetPickerTheme t) => t.cellRadius, PickerChromeSizes.cellRadius),
      sheetRadius: pick(
          (AssetPickerTheme t) => t.sheetRadius, PickerChromeSizes.sheetRadius),
    );
  }
}
