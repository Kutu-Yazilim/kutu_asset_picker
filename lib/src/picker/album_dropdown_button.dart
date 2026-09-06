import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/albums_provider.dart';
import '../source/picker_album.dart';
import '../text/asset_picker_text.dart';
import '../text/asset_picker_text_scope.dart';
import '../theme/asset_picker_theme_scope.dart';
import '../theme/resolved_asset_picker_theme.dart';
import 'album_list_sheet.dart';

/// The app-bar album switcher.
///
/// The sheet it opens is a new route on the **host's** navigator — above the
/// `ProviderScope` the picker created for itself, and above its theme and text
/// scopes. So the route is handed all three explicitly: the picker's container
/// through an `UncontrolledProviderScope`, and the resolved theme and copy
/// through the same scope widgets the picker's own subtree uses. Without that
/// the sheet's first `ref.watch` finds no scope at all in a host app that has
/// no Riverpod of its own, and in one that does it finds the wrong scope, with
/// none of the picker's overrides.
class AlbumDropdownButton extends ConsumerWidget {
  /// Creates a [AlbumDropdownButton].
  const AlbumDropdownButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ResolvedAssetPickerTheme theme = context.pickerTheme;
    final AssetPickerText text = context.pickerText;
    final PickerAlbum? current = ref.watch(currentAlbumProvider);

    return TextButton.icon(
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (BuildContext _) => UncontrolledProviderScope(
          container: ProviderScope.containerOf(context, listen: false),
          child: AssetPickerThemeScope(
            resolved: theme,
            child: AssetPickerTextScope(
              text: text,
              child: const AlbumListSheet(),
            ),
          ),
        ),
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
