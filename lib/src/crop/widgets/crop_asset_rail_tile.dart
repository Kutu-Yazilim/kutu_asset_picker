import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_quality.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_sizes.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_spacing.dart';
import 'package:kutu_asset_picker/src/crop/crop_providers.dart';
import 'package:kutu_asset_picker/src/picker/thumbnail_fallback.dart';
import 'package:kutu_asset_picker/src/providers/injection_providers.dart';
import 'package:kutu_asset_picker/src/source/picker_asset.dart';
import 'package:kutu_asset_picker/src/source/picker_asset_image_provider.dart';
import 'package:kutu_asset_picker/src/theme/asset_picker_theme_scope.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

/// One asset in the rail. Tapping focuses it; the crop state it already has is
/// untouched, because that state lives in `CropStates` and not here.
class CropAssetRailTile extends ConsumerWidget {
  /// Creates a [CropAssetRailTile].
  const CropAssetRailTile({required this.asset, super.key});

  /// The asset.
  final PickerAsset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.pickerTheme;
    final isFocused =
        ref.watch(focusedAssetProvider.select((id) => id == asset.id));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AssetPickerSpacing.xs),
      child: GestureDetector(
        onTap: () => ref.read(focusedAssetProvider.notifier).focus(asset.id),
        child: Container(
          width: AssetPickerSizes.railTile,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(theme.cellRadius),
            border: Border.all(
              color: isFocused ? theme.selectionBadgeFill : theme.surface,
              width: AssetPickerSizes.railTileBorder,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Image(
            image: PickerAssetImageProvider(
              asset,
              source: ref.watch(assetSourceProvider),
              // One flat, clamped size for every rail tile. Per-cell DPR
              // scaling multiplies cache keys, which is the thing to avoid
              // (spec §4.4).
              size: const ThumbSize.square(AssetPickerSizes.railTileThumb),
              quality: AssetPickerQuality.thumbnail,
            ),
            fit: BoxFit.cover,
            gaplessPlayback: true,
            errorBuilder:
                (BuildContext context, Object error, StackTrace? stack) =>
                    const ThumbnailFallback(),
          ),
        ),
      ),
    );
  }
}
