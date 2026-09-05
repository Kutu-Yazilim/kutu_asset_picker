import 'package:kutu_asset_picker/src/source/picker_asset.dart';

/// The asset the crop step is editing.
///
/// `FocusedAsset` holds an id and is deliberately dependency-free — deriving
/// its default from the selection inside the notifier would reset the focus
/// every time the grid paged in more assets. The fallback lives here instead.
PickerAsset? resolveFocusedAsset(List<PickerAsset> assets, String? focusedId) {
  if (assets.isEmpty) return null;
  for (final asset in assets) {
    if (asset.id == focusedId) return asset;
  }
  return assets.first;
}
