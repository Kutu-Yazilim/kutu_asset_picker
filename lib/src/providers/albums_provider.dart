import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../source/picker_album.dart';
import 'injection_providers.dart';

import 'asset_page_provider.dart';

part 'albums_provider.g.dart';

/// The album list for the configured media types.
@Riverpod(keepAlive: true)
class AssetPickerAlbums extends _$AssetPickerAlbums {
  @override
  Future<List<PickerAlbum>> build() async {
    final List<PickerAlbum> albums = await _query();
    // Writing to another notifier during a build is illegal, so hand the
    // first album over on the next microtask. The grid has nothing to page
    // until this lands.
    scheduleMicrotask(() => _adoptFirst(albums));
    return albums;
  }

  Future<List<PickerAlbum>> _query() {
    final config = ref.read(assetPickerConfigProvider);
    return ref.read(assetSourceProvider).albums(
          config.mediaTypes,
          maxVideoDuration: config.maxVideoDuration,
        );
  }

  void _adoptFirst(List<PickerAlbum> albums) {
    final CurrentAlbum current = ref.read(currentAlbumProvider.notifier);
    if (albums.isEmpty) {
      current.reset();
      return;
    }
    current.select(albums.first);
  }

  /// Presents the OS "manage limited selection" UI and reconciles afterwards.
  ///
  /// One call, so the *Manage selection* bar carries no logic (Flutter rule 6).
  Future<void> manageLimitedSelection() async {
    final config = ref.read(assetPickerConfigProvider);
    await ref
        .read(assetSourceProvider)
        .manageLimitedSelection(config.mediaTypes);
    await refreshAfterLimitedChange();
  }

  /// Re-queries albums and restarts paging.
  ///
  /// When `presentLimited` returns, album lists and counts are stale
  /// (design §4.2). The page is invalidated explicitly rather than relying on
  /// the current album changing identity: a user who adds one photo to an
  /// album that already had it re-selected produces an identical
  /// [PickerAlbum], `ref.watch` would not fire, and the grid would keep
  /// showing the pre-change page.
  Future<void> refreshAfterLimitedChange() async {
    state = await AsyncValue.guard<List<PickerAlbum>>(_query);
    _adoptFirst(state.value ?? const <PickerAlbum>[]);
    ref.invalidate(assetPageProvider);
  }
}

/// Which album the grid is showing.
@Riverpod(keepAlive: true)
class CurrentAlbum extends _$CurrentAlbum {
  @override
  PickerAlbum? build() => null;

  void select(PickerAlbum album) => state = album;

  /// Clears the selection — the library has no albums to show.
  void reset() => state = null;
}
