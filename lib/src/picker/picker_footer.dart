import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/asset_picker_config.dart';
import '../config/picker_tuning.dart';
import '../providers/injection_providers.dart';
import '../providers/picker_commit_provider.dart';
import '../providers/selection_provider.dart';
import '../text/asset_picker_text.dart';
import '../text/asset_picker_text_scope.dart';
import '../theme/asset_picker_theme_scope.dart';
import '../theme/resolved_asset_picker_theme.dart';

/// The selected count and the primary action.
///
/// *Next* is enabled **at `minSelection`** (design §5) — not at one item, which
/// only looks equivalent because the default minimum is one.
///
/// Pressing it starts the iCloud pre-flight rather than advancing directly.
/// [onNext] fires when every selected asset is actually on the device; until
/// then the button is inert and `CloudProgressBar` owns the explanation. That
/// ordering is design §4.5's whole point: the failure has to be found here,
/// with a progress bar and a *Retry*, not two screens later at export.
class PickerFooter extends ConsumerWidget {
  const PickerFooter({super.key, required this.onNext});

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ResolvedAssetPickerTheme theme = context.pickerTheme;
    final AssetPickerText text = context.pickerText;
    final AssetPickerConfig config = ref.watch(assetPickerConfigProvider);
    final int count = ref.watch(selectionProvider).length;
    final bool preflighting = ref.watch(pickerCommitProvider).running;

    return ColoredBox(
      color: theme.background,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: PickerChromeSizes.footerPadding,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  count >= config.maxSelection
                      ? text.limitReached(config.maxSelection)
                      : text.selectedCount(count),
                  style: theme.labelStyle.copyWith(color: theme.onSurfaceMuted),
                ),
              ),
              FilledButton(
                onPressed: count >= config.minSelection && !preflighting
                    ? () => ref
                        .read(pickerCommitProvider.notifier)
                        .commit(onReady: onNext)
                    : null,
                child: Text(text.pickerNext),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
