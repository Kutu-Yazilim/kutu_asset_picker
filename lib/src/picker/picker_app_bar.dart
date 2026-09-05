import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../text/asset_picker_text.dart';
import '../text/asset_picker_text_scope.dart';
import '../theme/asset_picker_theme_scope.dart';
import '../theme/resolved_asset_picker_theme.dart';
import 'album_dropdown_button.dart';

/// The picker's app bar: cancel on the left, album switcher in the middle.
///
/// *Next* deliberately lives in the footer with the selected strip rather than
/// here, so the count, the strip and the primary action are one block.
///
/// [onCancel] is optional and defaults to `Navigator.maybePop`. A host that
/// owns the route — `AssetPickerView`, and slice 4's `KutuAssetPicker.show`
/// behind it — passes its own, because the widget is embeddable and popping
/// somebody else's route is not the picker's call to make.
class PickerAppBar extends ConsumerWidget implements PreferredSizeWidget {
  /// Creates a [PickerAppBar].
  const PickerAppBar({super.key, this.onCancel});

  /// The on cancel.
  final VoidCallback? onCancel;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ResolvedAssetPickerTheme theme = context.pickerTheme;
    final AssetPickerText text = context.pickerText;

    return AppBar(
      backgroundColor: theme.background,
      foregroundColor: theme.onSurface,
      centerTitle: true,
      leading: IconButton(
        tooltip: text.pickerCancel,
        icon: const Icon(Icons.close),
        onPressed: onCancel ??
            () {
              Navigator.of(context).maybePop();
            },
      ),
      title: const AlbumDropdownButton(),
    );
  }
}
