import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../crop/widgets/crop_step_host.dart';
import '../export/export_controller.dart';
import '../export/export_progress.dart';
import '../result/asset_picker_result.dart';
import '../text/asset_picker_text.dart';
import '../text/asset_picker_text_locale.dart';
import '../text/asset_picker_text_scope.dart';
import '../theme/asset_picker_theme.dart';
import '../theme/asset_picker_theme_scope.dart';
import '../view/picker_step_controller.dart';
import 'picker_grid_step.dart';

void _ignore() {}

/// The picker, embeddable anywhere: a go_router sub-route, a sheet body, a tab.
///
/// **This is the real implementation.** `KutuAssetPicker.show` is a thin
/// wrapper over it, not the other way round. Owning `Navigator.push` and making
/// the selection the route result is the single most-cited structural complaint
/// about `wechat_assets_picker` — it fights go_router sub-routes and any
/// Riverpod-driven flow (spec §3.3).
///
/// It creates **no** `ProviderScope`. The hosting scope must override
/// `assetPickerConfigProvider` and `assetSourceProvider` (contract §9);
/// `AssetPickerScope` does exactly that and is what `KutuAssetPicker.show`
/// mounts. A scope created here would shadow the consumer's own overrides.
///
/// The result arrives through [onCompleted] rather than a `Future`, because a
/// button that awaited one would break Flutter rule 9. `ref.listen` on the
/// export controller is the same pattern every screen in `apps/mobile` uses.
class AssetPickerView extends ConsumerWidget {
  const AssetPickerView({
    required this.onCompleted,
    this.onCancelled,
    this.theme,
    this.text,
    super.key,
  });

  /// The finished assets, in selection order — the order the strip shows and
  /// the order the author dragged them into.
  final ValueChanged<AssetPickerResult> onCompleted;

  final VoidCallback? onCancelled;

  /// Level one of the three-level theme resolve (spec §8.1). It reaches every
  /// widget in both steps through [AssetPickerThemeScope].
  final AssetPickerTheme? theme;

  /// An explicit copy delegate. Null resolves from the ambient locale, and
  /// falls back to English when there is no `Localizations` in the tree.
  final AssetPickerText? text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(exportControllerProvider, (previous, next) {
      if (next is ExportSucceeded) onCompleted(next.result);
    });

    return AssetPickerThemeScope(
      resolved: AssetPickerTheme.resolve(context, theme),
      child: AssetPickerTextScope(
        text: text ??
            assetPickerTextFromLocale(Localizations.maybeLocaleOf(context)),
        child: switch (ref.watch(pickerStepControllerProvider)) {
          AssetPickerStep.grid => PickerGridStep(
              onNext: ref.read(pickerStepControllerProvider.notifier).next,
              onCancel: onCancelled ?? _ignore,
            ),
          AssetPickerStep.crop => CropStepHost(
              onBack: ref.read(pickerStepControllerProvider.notifier).back,
            ),
        },
      ),
    );
  }
}
