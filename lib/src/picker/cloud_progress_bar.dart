import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/picker_tuning.dart';
import '../providers/picker_commit_provider.dart';
import '../text/asset_picker_text.dart';
import '../text/asset_picker_text_provider.dart';
import '../theme/asset_picker_theme.dart';
import '../theme/resolved_asset_picker_theme.dart';

/// The iCloud download strip, shown between the selected strip and the footer.
///
/// It exists so the wait has a face: without it, tapping *Next* on a selection
/// that lives in iCloud looks like the button is broken (design §4.5). It stays
/// on screen after a failure so the user gets *Retry* rather than a bar that
/// vanishes and a *Next* that silently does nothing.
class CloudProgressBar extends ConsumerWidget {
  const CloudProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final PickerCommitState commit = ref.watch(pickerCommitProvider);
    if (!commit.running && !commit.hasFailures) {
      return const SizedBox.shrink();
    }

    final ResolvedAssetPickerTheme theme = AssetPickerTheme.resolve(context);
    final AssetPickerText text = ref.watch(assetPickerTextProvider);
    final bool failed = commit.hasFailures;

    return ColoredBox(
      color: theme.surface,
      child: Padding(
        padding: PickerChromeSizes.limitedBarPadding,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    failed
                        ? text.pickerDownloadFailed
                        : text.pickerDownloadingFromCloud,
                    style: theme.labelStyle.copyWith(
                      color: failed ? theme.danger : theme.onSurface,
                    ),
                  ),
                  LinearProgressIndicator(
                    value: commit.progress,
                    color: theme.progressIndicator,
                  ),
                ],
              ),
            ),
            if (failed)
              TextButton(
                onPressed: ref.read(pickerCommitProvider.notifier).retry,
                child: Text(
                  text.pickerRetry,
                  style: theme.labelStyle.copyWith(color: theme.onSurface),
                ),
              )
            else
              TextButton(
                onPressed: ref.read(pickerCommitProvider.notifier).cancel,
                child: Text(
                  text.pickerCancel,
                  style: theme.labelStyle.copyWith(color: theme.onSurface),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
