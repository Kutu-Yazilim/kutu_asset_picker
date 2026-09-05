import 'package:flutter/painting.dart';
import 'package:kutu_asset_picker/src/source/picker_asset.dart';

/// The asset's pixel dimensions as a [Size].
///
/// These are already display-oriented. `AssetEntity.orientation` is
/// Android-only and always 0 on iOS and macOS, so it is never used as an input;
/// EXIF orientation is baked once, natively, at export (spec §7.2). Reading it
/// here as well is how a photo ends up rotated twice.
Size pickerAssetSize(PickerAsset asset) =>
    Size(asset.width.toDouble(), asset.height.toDouble());
