import 'package:flutter/material.dart';

import '../theme/asset_picker_theme_scope.dart';
import '../theme/resolved_asset_picker_theme.dart';
import '../config/picker_tuning.dart';

/// What a cell shows when its thumbnail cannot be decoded.
///
/// A neutral tile, not an error dialog: one unreadable asset in a library of
/// thousands is a normal occurrence and must not interrupt browsing.
class ThumbnailFallback extends StatelessWidget {
  /// Creates a [ThumbnailFallback].
  const ThumbnailFallback({super.key});

  @override
  Widget build(BuildContext context) {
    final ResolvedAssetPickerTheme theme = context.pickerTheme;
    return ColoredBox(
      color: theme.surface,
      child: Center(
        child: Icon(
          Icons.broken_image_outlined,
          color: theme.onSurfaceMuted,
          size: PickerChromeSizes.stateIconSize,
        ),
      ),
    );
  }
}
