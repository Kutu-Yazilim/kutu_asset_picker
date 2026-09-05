import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'asset_picker_text.dart';
import 'asset_picker_text_en.dart';

/// The strings the picker renders. Override at the hosting scope to supply
/// your app's own copy — PatikaX feeds its 8-locale ARB pipeline through here.
final Provider<AssetPickerText> assetPickerTextProvider =
    Provider<AssetPickerText>((Ref ref) => const AssetPickerTextEn());
