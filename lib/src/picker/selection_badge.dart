import 'package:flutter/material.dart';

import '../config/picker_tuning.dart';
import '../theme/asset_picker_theme_scope.dart';
import '../theme/resolved_asset_picker_theme.dart';

/// The numbered selection badge on a grid cell.
///
/// [index] is 1-based; 0 means unselected and renders the empty ring, which is
/// the affordance that tells the user the cell is selectable at all.
class SelectionBadge extends StatelessWidget {
  const SelectionBadge({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final ResolvedAssetPickerTheme theme = context.pickerTheme;
    final bool selected = index > 0;

    return AnimatedContainer(
      duration: PickerDurations.badgeAnimation,
      width: PickerChromeSizes.badgeDiameter,
      height: PickerChromeSizes.badgeDiameter,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? theme.selectionBadgeFill : null,
        border: Border.all(
          color: theme.selectionBadgeBorder,
          width: PickerChromeSizes.badgeBorderWidth,
        ),
      ),
      child: selected
          ? Text(
              '$index',
              style: theme.badgeStyle.copyWith(color: theme.selectionBadgeText),
            )
          : null,
    );
  }
}
