import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/selection_provider.dart';
import '../source/picker_asset.dart';
import 'picker_grid_step.dart';

/// The picker, embeddable anywhere: a `go_router` sub-route, a sheet body, a
/// tab.
///
/// **This is the real implementation.** Owning `Navigator.push` and making the
/// selection the route result is the single most-cited structural complaint
/// about `wechat_assets_picker` — it fights `go_router` sub-routes and any
/// Riverpod-driven flow (design §3.3) — so the convenience wrapper wraps this,
/// never the other way round.
///
/// It creates **no** `ProviderScope`. The hosting scope must override
/// `assetPickerConfigProvider` and `assetSourceProvider` (contract §9); a scope
/// created here would shadow the consumer's own overrides.
///
/// The selection arrives through [onCompleted] rather than a `Future`, because
/// a button that awaited one would break Flutter rule 9.
///
/// **Slice 4 extends this**: with the crop step, `AssetPickerResult` and the
/// export controller in place, [onCompleted] becomes
/// `ValueChanged<AssetPickerResult>`, `theme` and `text` parameters arrive, and
/// the body becomes a `switch` over `AssetPickerStep`. The
/// `PickerGridStep(onNext:, onCancel:)` call below is exactly the call it
/// keeps.
class AssetPickerView extends ConsumerWidget {
  const AssetPickerView({
    required this.onCompleted,
    this.onCancelled,
    super.key,
  });

  /// The selected assets, in selection order — which is the order the strip
  /// shows and the order the user dragged them into.
  final ValueChanged<List<PickerAsset>> onCompleted;

  /// Null falls back to popping the enclosing route, which is right for the
  /// common `Navigator.push` host and wrong for an embedded tab — so a host
  /// that is not a route passes its own.
  final VoidCallback? onCancelled;

  @override
  Widget build(BuildContext context, WidgetRef ref) => PickerGridStep(
        onNext: () =>
            onCompleted(ref.read(selectionProvider.notifier).selectedAssets),
        onCancel: onCancelled ??
            () {
              Navigator.of(context).maybePop();
            },
      );
}
