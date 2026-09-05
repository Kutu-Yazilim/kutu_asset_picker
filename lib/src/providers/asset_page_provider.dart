import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../config/picker_tuning.dart';
import '../source/asset_source.dart';
import '../source/picker_album.dart';
import '../source/picker_asset.dart';
import 'albums_provider.dart';
import 'injection_providers.dart';

part 'asset_page_provider.g.dart';

/// The current album's assets, loaded a page at a time.
///
/// Rebuilding — a new album, or an explicit invalidate after the limited
/// selection changed — restarts paging from offset zero.
@Riverpod(keepAlive: true)
class AssetPage extends _$AssetPage {
  int _offset = 0;
  bool _endReached = false;
  bool _loading = false;

  /// Whether another page might exist.
  bool get hasMore => !_endReached;

  @override
  Future<List<PickerAsset>> build() async {
    final AssetSource source = ref.watch(assetSourceProvider);
    final PickerAlbum? album = ref.watch(currentAlbumProvider);

    // A library change — a new capture, a changed limited selection, a
    // deletion — re-pages without the user pulling to refresh (design §5).
    final StreamSubscription<void> sub =
        source.changes.listen((void _) => ref.invalidateSelf());
    ref.onDispose(sub.cancel);

    _offset = 0;
    _endReached = false;
    _loading = false;

    if (album == null) {
      _endReached = true;
      return const <PickerAsset>[];
    }

    final List<PickerAsset> page = await source.assets(
      album: album,
      offset: 0,
      count: PickerGridTuning.pageSize,
    );
    _offset = page.length;
    _endReached = page.length < PickerGridTuning.pageSize;
    unawaited(_warmAhead(page));
    return page;
  }

  /// Appends the next page. Safe to call on every scroll notification: it is a
  /// no-op while a fetch is in flight or the album is exhausted.
  Future<void> loadMore() async {
    if (_loading || _endReached) {
      return;
    }
    final PickerAlbum? album = ref.read(currentAlbumProvider);
    final List<PickerAsset>? current = state.value;
    if (album == null || current == null) {
      return;
    }

    _loading = true;
    try {
      final List<PickerAsset> next = await ref.read(assetSourceProvider).assets(
            album: album,
            offset: _offset,
            count: PickerGridTuning.pageSize,
          );
      _offset += next.length;
      _endReached = next.length < PickerGridTuning.pageSize;
      state = AsyncData<List<PickerAsset>>(<PickerAsset>[...current, ...next]);
      unawaited(_warmAhead(next));
    } finally {
      _loading = false;
    }
  }

  /// Warms the platform thumbnail cache for a page that has just landed.
  ///
  /// Fire-and-forget and double-guarded: the implementation swallows, and this
  /// swallows again, so paging survives a plugin that starts throwing.
  Future<void> _warmAhead(List<PickerAsset> page) async {
    if (page.isEmpty) {
      return;
    }
    try {
      await ref.read(assetSourceProvider).prefetch(
        <String>[for (final PickerAsset asset in page) asset.id],
        ref.read(assetPickerConfigProvider).thumbSize,
        quality: PickerGridTuning.thumbnailQuality,
      );
    } on Object {
      // Best-effort (design §4.4).
    }
  }

  /// Inserts a just-captured asset at the head.
  ///
  /// The platform change notification will re-page eventually, but "eventually"
  /// is visible: the user taps the camera tile, comes back, and expects their
  /// photo to be there and selected.
  void prepend(PickerAsset asset) {
    final List<PickerAsset> current = state.value ?? const <PickerAsset>[];
    if (current.any((PickerAsset a) => a.id == asset.id)) {
      return;
    }
    _offset += 1;
    state = AsyncData<List<PickerAsset>>(<PickerAsset>[asset, ...current]);
  }
}
