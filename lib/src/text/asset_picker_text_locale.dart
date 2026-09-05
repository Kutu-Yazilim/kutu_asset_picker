import 'dart:ui' show Locale;

import 'package:kutu_asset_picker/src/text/asset_picker_text.dart';
import 'package:kutu_asset_picker/src/text/asset_picker_text_en.dart';
import 'package:kutu_asset_picker/src/text/asset_picker_text_tr.dart';

/// The delegate for [locale], defaulting to **English**.
///
/// The default is the whole point. `wechat_assets_picker`'s base delegate is
/// Chinese and silently wins whenever no `Locale` is in the widget tree, which
/// is how a German app ships a Chinese picker. English is the neutral default
/// for a published package (spec §8.2).
///
/// `Locale` does not lowercase what it is constructed with, so the comparison
/// does.
AssetPickerText assetPickerTextFromLocale(Locale? locale) =>
    locale?.languageCode.toLowerCase() == 'tr'
        ? const AssetPickerTextTr()
        : const AssetPickerTextEn();
