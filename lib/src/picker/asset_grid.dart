import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/asset_picker_config.dart';
import '../config/picker_tuning.dart';
import '../providers/asset_page_provider.dart';
import '../providers/injection_providers.dart';
import '../source/picker_asset.dart';
import '../theme/asset_picker_theme.dart';
import '../theme/resolved_asset_picker_theme.dart';
import 'asset_grid_cell.dart';
import 'camera_tile.dart';

/// The paged asset grid.
///
/// [scrollController] is the sheet's controller in sheet mode and null in page
/// mode. Passing the `DraggableScrollableSheet` builder's controller straight
/// into the `GridView` is the supported way to make sheet-drag and grid-scroll
/// hand off instead of fighting (design §5).
class AssetGrid extends ConsumerWidget {
  const AssetGrid({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AssetPickerConfig config = ref.watch(assetPickerConfigProvider);
    final ResolvedAssetPickerTheme theme = AssetPickerTheme.resolve(context);
    final AsyncValue<List<PickerAsset>> page = ref.watch(assetPageProvider);
    final bool showCamera =
        config.enableCamera && ref.watch(pickerCameraDelegateProvider) != null;

    return page.when(
      loading: () => Center(
        child: CircularProgressIndicator(color: theme.progressIndicator),
      ),
      error: (Object error, StackTrace stack) => Center(
        child: Icon(Icons.error_outline, color: theme.danger),
      ),
      data: (List<PickerAsset> assets) {
        final int leading = showCamera ? 1 : 0;

        return NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification) {
            final ScrollMetrics m = notification.metrics;
            if (m.pixels >=
                m.maxScrollExtent - PickerGridTuning.loadMoreThreshold) {
              // A no-op while a fetch is in flight or the album is exhausted;
              // the guard lives in the notifier, not here.
              ref.read(assetPageProvider.notifier).loadMore();
            }
            return false;
          },
          child: GridView.builder(
            controller: scrollController,
            padding: EdgeInsets.all(config.gridSpacing),
            scrollCacheExtent:
                ScrollCacheExtent.pixels(PickerGridTuning.cacheExtent),
            // Exactly one RepaintBoundary per cell, declared in AssetGridCell.
            addRepaintBoundaries: false,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: config.gridColumns,
              mainAxisSpacing: config.gridSpacing,
              crossAxisSpacing: config.gridSpacing,
              childAspectRatio: config.cellAspectRatio,
            ),
            itemCount: assets.length + leading,
            // Without this, prepending a capture shifts every index by one and
            // the framework re-creates every element in the viewport.
            findChildIndexCallback: (Key key) {
              if (key is! ValueKey<String>) {
                return null;
              }
              if (key.value == PickerGridKeys.cameraTile) {
                return showCamera ? 0 : null;
              }
              final int index =
                  assets.indexWhere((PickerAsset a) => a.id == key.value);
              return index < 0 ? null : index + leading;
            },
            itemBuilder: (BuildContext context, int index) {
              if (showCamera && index == 0) {
                return const CameraTile(
                  key: ValueKey<String>(PickerGridKeys.cameraTile),
                );
              }
              final PickerAsset asset = assets[index - leading];
              return AssetGridCell(
                key: ValueKey<String>(asset.id),
                asset: asset,
              );
            },
          ),
        );
      },
    );
  }
}
