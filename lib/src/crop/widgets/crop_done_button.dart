import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:kutu_asset_picker/src/export/export_controller.dart';
import 'package:kutu_asset_picker/src/export/export_progress.dart';
import 'package:kutu_asset_picker/src/text/asset_picker_text_scope.dart';
import 'package:kutu_asset_picker/src/theme/asset_picker_theme_scope.dart';

/// Starts the export and shows its progress in place of its own label.
///
/// `run()` is called and not awaited — Flutter rule 9 forbids `await` in UI, so
/// the result reaches the caller through `ref.listen` on
/// `exportControllerProvider` in `AssetPickerView`. `ExportController.run` is
/// documented never to throw precisely so this call is safe to drop.
class CropDoneButton extends ConsumerWidget {
  const CropDoneButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(exportControllerProvider);
    final running = progress is ExportRunning;
    return TextButton(
      onPressed:
          running ? null : ref.read(exportControllerProvider.notifier).run,
      child: Text(
        running
            ? context.pickerText.exportProgress(progress.done, progress.total)
            : context.pickerText.pickerDone,
        style: context.pickerTheme.labelStyle.copyWith(
          color: running
              ? context.pickerTheme.onSurfaceMuted
              : context.pickerTheme.selectionBadgeFill,
        ),
      ),
    );
  }
}
