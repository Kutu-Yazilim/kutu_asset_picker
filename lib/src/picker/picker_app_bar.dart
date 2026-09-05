import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../text/asset_picker_text.dart';
import '../text/asset_picker_text_provider.dart';
import '../theme/asset_picker_theme.dart';
import '../theme/resolved_asset_picker_theme.dart';
import 'album_dropdown_button.dart';

/// The picker's app bar: cancel on the left, album switcher in the middle.
///
/// *Next* deliberately lives in the footer with the selected strip rather than
/// here, so the count, the strip and the primary action are one block.
class PickerAppBar extends ConsumerWidget implements PreferredSizeWidget {
  const PickerAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ResolvedAssetPickerTheme theme = AssetPickerTheme.resolve(context);
    final AssetPickerText text = ref.watch(assetPickerTextProvider);

    return AppBar(
      backgroundColor: theme.background,
      foregroundColor: theme.onSurface,
      centerTitle: true,
      leading: IconButton(
        tooltip: text.pickerCancel,
        icon: const Icon(Icons.close),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: const AlbumDropdownButton(),
    );
  }
}
