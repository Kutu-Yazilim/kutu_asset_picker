import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_sizes.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_done_button.dart';
import 'package:kutu_asset_picker/src/text/asset_picker_text_scope.dart';
import 'package:kutu_asset_picker/src/theme/asset_picker_theme_scope.dart';

/// Cancel, title, Done.
class CropStepAppBar extends ConsumerWidget {
  /// Creates a [CropStepAppBar].
  const CropStepAppBar({required this.onBack, super.key});

  /// The on back.
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) => SizedBox(
        height: AssetPickerSizes.appBarHeight,
        child: Row(
          children: [
            TextButton(
              onPressed: onBack,
              child: Text(
                context.pickerText.pickerCancel,
                style: context.pickerTheme.labelStyle.copyWith(
                  color: context.pickerTheme.onSurface,
                ),
              ),
            ),
            Expanded(
              child: Text(
                context.pickerText.cropTitle,
                textAlign: TextAlign.center,
                style: context.pickerTheme.titleStyle.copyWith(
                  color: context.pickerTheme.onSurface,
                ),
              ),
            ),
            const CropDoneButton(),
          ],
        ),
      );
}
