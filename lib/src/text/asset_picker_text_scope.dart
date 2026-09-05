import 'package:flutter/widgets.dart';
import 'package:kutu_asset_picker/src/text/asset_picker_text.dart';
import 'package:kutu_asset_picker/src/text/asset_picker_text_locale.dart';

/// Carries the picker's text delegate down its subtree.
///
/// [of] falls back to resolving from the ambient locale — and to English when
/// there is no `Localizations` at all — so a widget pumped standalone in a
/// golden test still renders real copy.
final class AssetPickerTextScope extends InheritedWidget {
  /// Creates a [AssetPickerTextScope].
  const AssetPickerTextScope({
    required this.text,
    required super.child,
    super.key,
  });

  /// The text.
  final AssetPickerText text;

  /// Of.
  static AssetPickerText of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<AssetPickerTextScope>()
          ?.text ??
      assetPickerTextFromLocale(Localizations.maybeLocaleOf(context));

  @override
  bool updateShouldNotify(AssetPickerTextScope oldWidget) =>
      oldWidget.text != text;
}

/// Asset picker text x.
extension AssetPickerTextX on BuildContext {
  /// The picker's copy. Every string a widget renders comes from here; a
  /// literal in a widget is a rule violation.
  AssetPickerText get pickerText => AssetPickerTextScope.of(this);
}
