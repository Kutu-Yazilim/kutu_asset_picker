import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/albums_provider.dart';
import '../source/picker_album.dart';
import '../text/asset_picker_text.dart';
import '../text/asset_picker_text_provider.dart';
import '../theme/asset_picker_theme.dart';
import '../theme/resolved_asset_picker_theme.dart';
import 'album_list_sheet.dart';

/// The app-bar album switcher.
class AlbumDropdownButton extends ConsumerWidget {
  const AlbumDropdownButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ResolvedAssetPickerTheme theme = AssetPickerTheme.resolve(context);
    final AssetPickerText text = ref.watch(assetPickerTextProvider);
    final PickerAlbum? current = ref.watch(currentAlbumProvider);

    return TextButton.icon(
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (BuildContext context) => const AlbumListSheet(),
      ),
      icon: Icon(Icons.expand_more, color: theme.onSurface),
      iconAlignment: IconAlignment.end,
      label: Text(
        current?.name ?? text.pickerAlbumAll,
        style: theme.titleStyle.copyWith(color: theme.onSurface),
      ),
    );
  }
}
