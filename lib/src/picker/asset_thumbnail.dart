import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/asset_picker_config.dart';
import '../config/picker_tuning.dart';
import '../providers/injection_providers.dart';
import '../source/asset_source.dart';
import '../source/picker_asset.dart';
import '../source/picker_asset_image_provider.dart';
import 'thumbnail_fallback.dart';

/// One asset thumbnail.
///
/// This is the **only** place in the package that resolves thumbnail bytes,
/// and it does so by handing a [PickerAssetImageProvider] to a plain [Image].
///
/// A `FutureBuilder(future: asset.thumbnailDataWithSize(...))` inside `build`
/// is **forbidden here and everywhere else** (design §4.4). It re-fires the
/// platform channel call and re-decodes on every single rebuild — and a grid
/// cell rebuilds constantly — and it bypasses `ScrollAwareImageProvider`,
/// which the `Image` widget wraps around any provider for free and which is
/// what defers decodes during a fling (flutter#48536). The whole product feel
/// of the grid rests on this one structural choice.
class AssetThumbnail extends ConsumerWidget {
  /// Creates a [AssetThumbnail].
  const AssetThumbnail({super.key, required this.asset});

  /// The asset.
  final PickerAsset asset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AssetPickerConfig config = ref.watch(assetPickerConfigProvider);
    final AssetSource source = ref.watch(assetSourceProvider);

    return Image(
      image: PickerAssetImageProvider(
        asset,
        source: source,
        size: config.thumbSize,
        quality: PickerGridTuning.thumbnailQuality,
      ),
      fit: BoxFit.cover,
      // Keep the previous frame while a new one decodes, so scrolling back
      // over a cell does not flash empty.
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
          const ThumbnailFallback(),
    );
  }
}
