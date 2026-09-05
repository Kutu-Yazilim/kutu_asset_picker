import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_quality.dart';
import 'package:kutu_asset_picker/src/crop/preview_thumb_size.dart';
import 'package:kutu_asset_picker/src/picker/thumbnail_fallback.dart';
import 'package:kutu_asset_picker/src/providers/injection_providers.dart';
import 'package:kutu_asset_picker/src/source/picker_asset.dart';
import 'package:kutu_asset_picker/src/source/picker_asset_image_provider.dart';

/// The photo handed to [CropViewport] as its child.
///
/// `BoxFit.fill` is correct here and nothing else is: the parent `SizedBox`
/// already has exactly the asset's pixel dimensions, and `previewThumbSize`
/// requested an aspect-matched box, so "fill" is a no-op stretch. Any other fit
/// would introduce letterboxing the crop math does not know about.
///
/// Goes through `PickerAssetImageProvider` rather than a `FutureBuilder` on
/// bytes: value equality over `(assetId, size, quality)` **is** the dedup
/// mechanism, and handing a provider to a plain `Image` is what buys
/// `ScrollAwareImageProvider` for free (spec §4.4).
class CropAssetImage extends ConsumerWidget {
  const CropAssetImage({required this.asset, super.key});

  final PickerAsset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Image(
        image: PickerAssetImageProvider(
          asset,
          source: ref.watch(assetSourceProvider),
          size: previewThumbSize(asset),
          quality: AssetPickerQuality.preview,
        ),
        fit: BoxFit.fill,
        gaplessPlayback: true,
        // The same degrade-not-crash rule as the grid thumbnail: an undecodable
        // preview still leaves the crop step usable.
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
            const ThumbnailFallback(),
      );
}
