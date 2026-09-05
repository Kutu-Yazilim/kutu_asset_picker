import 'package:kutu_asset_picker/src/result/picked_asset.dart';
import 'package:flutter/foundation.dart';

/// What the picker hands back: the finished assets, in selection order.
@immutable
final class AssetPickerResult {
  /// Creates a [AssetPickerResult].
  const AssetPickerResult({required this.assets});

  /// Selection order — the carousel order the author dragged into place.
  final List<PickedAsset> assets;
}
