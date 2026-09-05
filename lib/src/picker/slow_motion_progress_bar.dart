import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/picker_tuning.dart';
import '../providers/picker_commit_provider.dart';
import 'slow_motion_flatten.dart';
import '../theme/asset_picker_theme_scope.dart';
import '../text/asset_picker_text_scope.dart';

/// The slow-motion flatten pass, while it runs.
///
/// spec §7.3: this transcode "cannot happen silently behind *Next*". It sits
/// directly under `CloudProgressBar`, continuing the same wait, and its
/// *Cancel* is `PickerCommit.cancel` — one button for what is, from the
/// author's side, one operation.
///
/// It renders nothing at all when the pass is idle, so the grid's layout never
/// shifts for a selection with no slow-motion clip in it.
class SlowMotionProgressBar extends ConsumerWidget {
  /// Creates a [SlowMotionProgressBar].
  const SlowMotionProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final running =
        ref.watch(slowMotionFlattenProvider.select((state) => state.running));
    if (!running) {
      return const SizedBox.shrink();
    }

    final theme = context.pickerTheme;
    return ColoredBox(
      color: theme.surface,
      child: Padding(
        padding: PickerChromeSizes.limitedBarPadding,
        child: Row(
          children: <Widget>[
            Expanded(
              child: LinearProgressIndicator(
                value: ref.watch(
                  slowMotionFlattenProvider.select((state) => state.progress),
                ),
                color: theme.progressIndicator,
              ),
            ),
            TextButton(
              onPressed: ref.read(pickerCommitProvider.notifier).cancel,
              child: Text(
                context.pickerText.pickerCancel,
                style: theme.labelStyle.copyWith(color: theme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
