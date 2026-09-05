import 'package:flutter/material.dart';

import '../source/picker_album.dart';
import '../theme/asset_picker_theme_scope.dart';
import '../theme/resolved_asset_picker_theme.dart';

/// One row in the album list.
class AlbumListTile extends StatelessWidget {
  /// Creates a [AlbumListTile].
  const AlbumListTile({
    super.key,
    required this.album,
    required this.selected,
    required this.onTap,
  });

  /// The album.
  final PickerAlbum album;

  /// The selected.
  final bool selected;

  /// The on tap.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ResolvedAssetPickerTheme theme = context.pickerTheme;

    return ListTile(
      selected: selected,
      onTap: onTap,
      title: Text(
        album.name,
        style: theme.titleStyle.copyWith(color: theme.onSurface),
      ),
      trailing: Text(
        '${album.assetCount}',
        style: theme.labelStyle.copyWith(color: theme.onSurfaceMuted),
      ),
    );
  }
}
