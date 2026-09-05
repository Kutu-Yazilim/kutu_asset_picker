import 'package:flutter/widgets.dart';
import 'package:kutu_asset_picker/src/theme/asset_picker_theme.dart';
import 'package:kutu_asset_picker/src/theme/resolved_asset_picker_theme.dart';

/// Carries the resolved theme down the picker's subtree so the three-level
/// resolve runs once per screen rather than once per widget.
///
/// [of] falls back to resolving on the spot when there is no scope, which is
/// what lets every chrome widget be pumped standalone in a golden test without
/// a wrapper.
final class AssetPickerThemeScope extends InheritedWidget {
  /// Creates a [AssetPickerThemeScope].
  const AssetPickerThemeScope({
    required this.resolved,
    required super.child,
    super.key,
  });

  /// The resolved.
  final ResolvedAssetPickerTheme resolved;

  /// Of.
  static ResolvedAssetPickerTheme of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AssetPickerThemeScope>()
          ?.resolved ??
      AssetPickerTheme.resolve(context);

  @override
  bool updateShouldNotify(AssetPickerThemeScope oldWidget) =>
      oldWidget.resolved != resolved;
}

/// Asset picker theme x.
extension AssetPickerThemeX on BuildContext {
  /// The resolved picker theme. Every widget in the package reads colors and
  /// text styles through this and never through `AssetPickerTheme` directly.
  ResolvedAssetPickerTheme get pickerTheme => AssetPickerThemeScope.of(this);
}
