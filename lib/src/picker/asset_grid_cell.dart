import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/picker_tuning.dart';
import '../providers/selection_provider.dart';
import '../source/picker_asset.dart';
import '../theme/asset_picker_theme_scope.dart';
import '../theme/resolved_asset_picker_theme.dart';
import 'asset_thumbnail.dart';
import 'selection_badge.dart';
import 'video_duration_overlay.dart';
import 'selection_attempt.dart';

/// One grid cell.
///
/// **Rebuild granularity lives here** (contract §9, design §5). This widget
/// watches `selectionIndexProvider(asset.id)` — its own id and nothing else —
/// so toggling one asset rebuilds one cell rather than the grid.
///
/// [selectionCapReachedProvider] is the single deliberate exception: reaching
/// the cap has to dim every unselected cell at once, and that provider's value
/// changes only at the boundary, so it costs one grid-wide rebuild per cap
/// crossing rather than one per tap.
///
/// The [RepaintBoundary] is explicit here, and Task 20's `GridView.builder`
/// passes `addRepaintBoundaries: false`, so there is exactly one boundary per
/// cell and it is visible where a reader is looking for it.
class AssetGridCell extends ConsumerWidget {
  const AssetGridCell({super.key, required this.asset});

  final PickerAsset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int index = ref.watch(selectionIndexProvider(asset.id));
    final bool capReached = ref.watch(selectionCapReachedProvider);
    final ResolvedAssetPickerTheme theme = context.pickerTheme;

    final bool disabled = capReached && index == 0;

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: disabled
            ? null
            : () => ref.read(selectionAttemptProvider.notifier).toggle(asset),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(theme.cellRadius),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              AssetThumbnail(asset: asset),
              if (disabled) ColoredBox(color: theme.disabledOverlay),
              Positioned(
                right: PickerChromeSizes.badgeInset,
                top: PickerChromeSizes.badgeInset,
                child: SelectionBadge(index: index),
              ),
              Positioned(
                left: PickerChromeSizes.durationChipInset,
                bottom: PickerChromeSizes.durationChipInset,
                child: VideoDurationOverlay(asset: asset),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
