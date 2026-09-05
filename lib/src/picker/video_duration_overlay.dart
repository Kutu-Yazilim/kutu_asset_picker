import 'package:flutter/material.dart';

import '../config/picker_tuning.dart';
import '../source/picker_asset.dart';
import '../source/picker_media_type.dart';
import '../theme/asset_picker_theme_scope.dart';
import '../theme/resolved_asset_picker_theme.dart';
import 'duration_format.dart';

/// The duration chip on a video cell.
///
/// Renders nothing when the asset is an image **or** when its duration is null.
/// A null duration is a real state, not an error: MediaStore's duration column
/// is genuinely absent for some Android downloads and third-party recorders
/// (design §4.5). Those videos stay in the grid — they just have no chip.
/// Rendering "0:00" on a two-minute clip would be worse than rendering nothing.
class VideoDurationOverlay extends StatelessWidget {
  const VideoDurationOverlay({super.key, required this.asset});

  final PickerAsset asset;

  @override
  Widget build(BuildContext context) {
    final Duration? duration = asset.duration;
    if (asset.type != PickerMediaType.video || duration == null) {
      return const SizedBox.shrink();
    }

    final ResolvedAssetPickerTheme theme = context.pickerTheme;

    return Container(
      padding: PickerChromeSizes.durationChipPadding,
      decoration: BoxDecoration(
        color: theme.background.withValues(
          alpha: PickerChromeSizes.durationChipBackgroundOpacity,
        ),
        borderRadius:
            BorderRadius.circular(PickerChromeSizes.durationChipRadius),
      ),
      child: Text(
        formatPickerDuration(duration),
        style: theme.labelStyle.copyWith(color: theme.onSurface),
      ),
    );
  }
}
