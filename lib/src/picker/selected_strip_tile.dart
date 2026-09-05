import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/picker_tuning.dart';
import '../providers/selection_provider.dart';
import '../source/picker_asset.dart';
import '../text/asset_picker_text.dart';
import '../text/asset_picker_text_scope.dart';
import '../theme/asset_picker_theme_scope.dart';
import '../theme/resolved_asset_picker_theme.dart';
import 'asset_thumbnail.dart';

/// One tile in the selected strip: the thumbnail plus its remove affordance.
///
/// Removal is `toggleAsset`, not a bespoke `remove`, so deselecting from the
/// strip and deselecting from the grid are the same operation and the badge
/// numbers renumber identically either way.
class SelectedStripTile extends ConsumerWidget {
  const SelectedStripTile({super.key, required this.asset});

  final PickerAsset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ResolvedAssetPickerTheme theme = context.pickerTheme;
    final AssetPickerText text = context.pickerText;

    return SizedBox(
      width: PickerChromeSizes.selectedStripTileSize,
      height: PickerChromeSizes.selectedStripTileSize,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(theme.cellRadius),
            child: AssetThumbnail(asset: asset),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Tooltip(
              message: text.pickerRemove,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    ref.read(selectionProvider.notifier).toggleAsset(asset),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: theme.selectionBadgeFill,
                  ),
                  child: SizedBox(
                    width: PickerChromeSizes.badgeDiameter,
                    height: PickerChromeSizes.badgeDiameter,
                    child: Icon(
                      Icons.close,
                      size: PickerChromeSizes.badgeDiameter -
                          PickerChromeSizes.badgeInset,
                      color: theme.selectionBadgeText,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
