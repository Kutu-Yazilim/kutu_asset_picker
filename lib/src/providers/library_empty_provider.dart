import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../source/picker_album.dart';
import '../source/picker_asset.dart';
import 'albums_provider.dart';
import 'asset_page_provider.dart';

part 'library_empty_provider.g.dart';

/// Whether the grid genuinely has nothing to show.
///
/// Deliberately not "the page is empty". Albums arrive asynchronously and the
/// first album is adopted on a microtask, so there is always a window where the
/// page is legitimately empty and the library is not — acting on the naive rule
/// flashes an empty state for a frame on every open.
///
/// Empty means: the album list has settled, **and** either there are no albums
/// at all, or the adopted album's first page came back with nothing in it.
///
/// It lives here rather than in the two body widgets so both empty states read
/// one definition and cannot drift apart (Flutter rule 6).
@Riverpod(keepAlive: true)
bool pickerLibraryEmpty(Ref ref) {
  final AsyncValue<List<PickerAlbum>> albums =
      ref.watch(assetPickerAlbumsProvider);
  if (!albums.hasValue) {
    return false;
  }
  if (albums.requireValue.isEmpty) {
    return true;
  }
  if (ref.watch(currentAlbumProvider) == null) {
    return false;
  }
  final AsyncValue<List<PickerAsset>> page = ref.watch(assetPageProvider);
  return page.hasValue && page.requireValue.isEmpty;
}
