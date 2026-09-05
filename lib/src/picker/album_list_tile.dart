import 'package:flutter/material.dart';

import '../source/picker_album.dart';
import '../theme/asset_picker_theme.dart';
import '../theme/resolved_asset_picker_theme.dart';

/// One row in the album list.
class AlbumListTile extends StatelessWidget {
  const AlbumListTile({
    super.key,
    required this.album,
    required this.selected,
    required this.onTap,
  });

  final PickerAlbum album;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ResolvedAssetPickerTheme theme = AssetPickerTheme.resolve(context);

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
