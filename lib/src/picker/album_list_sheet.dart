import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/albums_provider.dart';
import '../source/picker_album.dart';
import '../theme/asset_picker_theme_scope.dart';
import '../theme/resolved_asset_picker_theme.dart';
import 'album_list_tile.dart';
import '../config/picker_tuning.dart';

/// The album list the dropdown opens.
///
/// Popping is navigation, not business logic, so it stays in the tap handler
/// alongside the single notifier call.
class AlbumListSheet extends ConsumerWidget {
  /// Creates a [AlbumListSheet].
  const AlbumListSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ResolvedAssetPickerTheme theme = context.pickerTheme;
    final AsyncValue<List<PickerAlbum>> albums =
        ref.watch(assetPickerAlbumsProvider);
    final PickerAlbum? current = ref.watch(currentAlbumProvider);

    // A Material, not a ColoredBox: ListTile paints its selection and ink on
    // the nearest Material, and a plain coloured box above it hides both.
    return SafeArea(
      child: Material(
        color: theme.background,
        child: albums.when(
          loading: () => Padding(
            padding: PickerChromeSizes.statePadding,
            child: Center(
              child: CircularProgressIndicator(color: theme.progressIndicator),
            ),
          ),
          error: (Object error, StackTrace stack) => Padding(
            padding: PickerChromeSizes.statePadding,
            child: Icon(Icons.error_outline, color: theme.danger),
          ),
          data: (List<PickerAlbum> list) => ListView.builder(
            shrinkWrap: true,
            itemCount: list.length,
            itemBuilder: (BuildContext context, int index) => AlbumListTile(
              album: list[index],
              selected: list[index].id == current?.id,
              onTap: () {
                ref.read(currentAlbumProvider.notifier).select(list[index]);
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),
    );
  }
}
