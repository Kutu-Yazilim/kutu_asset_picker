import 'package:kutu_asset_picker/src/config/crop_aspect.dart';
import 'package:kutu_asset_picker/src/text/asset_picker_text.dart';
import '../config/picker_enums.dart';

/// The copy on a ratio chip.
///
/// The named ratios go through the text delegate so a consumer can rename them.
/// A custom ratio cannot: [AssetPickerText.aspectLabel] takes a
/// [CropAspectLabel] and has no way to know the numbers, so the chip prints
/// them itself. Trailing `.0` is dropped, because "3.0:2.0" is not a ratio
/// anybody writes.
String aspectChipLabel(CropAspect aspect, AssetPickerText text) =>
    aspect.label == CropAspectLabel.custom
        ? '${_trimZero(aspect.x)}:${_trimZero(aspect.y)}'
        : text.aspectLabel(aspect.label);

String _trimZero(double value) =>
    value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';
