import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/picker_tuning.dart';
import '../theme/asset_picker_theme.dart';
import '../theme/resolved_asset_picker_theme.dart';
import 'picker_app_bar.dart';
import 'picker_body.dart';

/// `PickerSurface.sheet`: a draggable sheet whose controller drives the grid.
///
/// **This widget exists for one line** — `scrollController: controller`.
/// Handing the `DraggableScrollableSheet` builder's controller straight into
/// the `GridView` is the supported way to make sheet-drag and grid-scroll hand
/// off instead of fighting (design §5). Without it there are two scrollables
/// contesting the same vertical drag, and dragging down inside a grid that is
/// already at its top either does nothing or dismisses the sheet mid-scroll.
///
/// `expand: false` is what lets this sit inside a `showModalBottomSheet` route
/// without claiming the whole screen, which is how slice 4's
/// `KutuAssetPicker.show` presents it.
class AssetPickerSheet extends ConsumerWidget {
  const AssetPickerSheet({
    super.key,
    required this.onNext,
    required this.onCancel,
  });

  final VoidCallback onNext;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ResolvedAssetPickerTheme theme = AssetPickerTheme.resolve(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: PickerChromeSizes.sheetInitialExtent,
      minChildSize: PickerChromeSizes.sheetMinExtent,
      maxChildSize: PickerChromeSizes.sheetMaxExtent,
      builder: (BuildContext context, ScrollController controller) => ClipRRect(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(theme.sheetRadius)),
        child: ColoredBox(
          color: theme.background,
          child: Column(
            children: <Widget>[
              PickerAppBar(onCancel: onCancel),
              Expanded(
                child: PickerBody(
                  onNext: onNext,
                  scrollController: controller,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
