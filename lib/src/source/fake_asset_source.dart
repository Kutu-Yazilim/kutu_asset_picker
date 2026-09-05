import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:kutu_media_transform/kutu_media_transform.dart';

import 'asset_source.dart';
import 'picker_album.dart';
import 'picker_asset.dart';
import 'picker_media_type.dart';
import 'picker_permission.dart';

/// One recorded `albums()` call.
final class FakeAlbumQuery {
  const FakeAlbumQuery(this.kinds, this.maxVideoDuration);

  final Set<PickerMediaType> kinds;
  final Duration? maxVideoDuration;
}

/// One recorded `assets()` call.
final class FakeAssetQuery {
  const FakeAssetQuery(this.albumId, this.offset, this.count);

  final String albumId;
  final int offset;
  final int count;
}

/// A hand-written [AssetSource] for tests. There is no mocking library in this
/// repo, by design.
///
/// Every field is public and mutable so a test can reshape the library between
/// calls — which is exactly what the limited-access flow needs.
/// One recorded `prefetch()` call.
final class FakePrefetchQuery {
  const FakePrefetchQuery(this.ids, this.size, this.quality);

  final List<String> ids;
  final ThumbSize size;
  final int quality;
}

final class FakeAssetSource implements AssetSource {
  FakeAssetSource({
    this.permission = PickerPermission.full,
    List<PickerAlbum> albumList = const <PickerAlbum>[],
    Map<String, List<PickerAsset>> assetsByAlbum =
        const <String, List<PickerAsset>>{},
  })  : albumList = List<PickerAlbum>.of(albumList),
        assetsByAlbum = <String, List<PickerAsset>>{
          for (final MapEntry<String, List<PickerAsset>> e
              in assetsByAlbum.entries)
            e.key: List<PickerAsset>.of(e.value),
        };

  /// What [requestPermission] returns.
  PickerPermission permission;

  /// What [albums] returns.
  List<PickerAlbum> albumList;

  /// Album id → its assets, newest first.
  Map<String, List<PickerAsset>> assetsByAlbum;

  /// What [thumbnail] returns. A non-empty placeholder by default so callers
  /// that only care about "some bytes arrived" need no setup.
  Uint8List thumbnailBytes = Uint8List.fromList(<int>[1, 2, 3, 4]);

  /// Ids for which [isLocallyAvailable] reports false.
  final Set<String> locallyUnavailable = <String>{};

  /// Ids whose [file] future the test completes by hand, via [completeFile].
  final Set<String> pendingFiles = <String>{};

  /// Ids whose [file] call throws.
  final Set<String> failingFiles = <String>{};

  /// Ids whose [file] returns this exact file. Checked before the synthetic
  /// `/fake/$id` fallback, so a test that needs real bytes on disk — a length,
  /// a probe, an export — writes a temp file and registers it here.
  final Map<String, File> filesById = <String, File>{};

  /// Ids whose [file] resolves to null: present in the library, not obtainable.
  /// The iCloud case of spec §4.5, which the `/fake/$id` fallback cannot express.
  final Set<String> missingFiles = <String>{};

  /// Artificial latency for [albums] and [assets].
  Duration? queryDelay;

  final List<Set<PickerMediaType>> permissionRequests =
      <Set<PickerMediaType>>[];
  final List<FakeAlbumQuery> albumQueries = <FakeAlbumQuery>[];
  final List<FakeAssetQuery> assetQueries = <FakeAssetQuery>[];
  int manageLimitedSelectionCalls = 0;

  final Map<String, Completer<File?>> _pending = <String, Completer<File?>>{};
  final Map<String, void Function(double)> _progressSinks =
      <String, void Function(double)>{};
  final StreamController<void> _changes = StreamController<void>.broadcast();

  @override
  Stream<void> get changes => _changes.stream;

  /// Emits a library-changed event.
  void emitChange() => _changes.add(null);

  /// Feeds a progress value to a held-open [file] call.
  void emitFileProgress(String id, double progress) =>
      _progressSinks[id]?.call(progress);

  /// Completes a held-open [file] call.
  void completeFile(String id, File? file) {
    _pending.remove(id)?.complete(file);
    _progressSinks.remove(id);
  }

  /// Closes the change stream. Call from `addTearDown`.
  Future<void> dispose() => _changes.close();

  Future<void> _maybeDelay() async {
    final Duration? delay = queryDelay;
    if (delay != null) {
      await Future<void>.delayed(delay);
    }
  }

  @override
  Future<PickerPermission> requestPermission(Set<PickerMediaType> kinds) async {
    permissionRequests.add(kinds);
    return permission;
  }

  @override
  Future<List<PickerAlbum>> albums(
    Set<PickerMediaType> kinds, {
    Duration? maxVideoDuration,
  }) async {
    albumQueries.add(FakeAlbumQuery(kinds, maxVideoDuration));
    await _maybeDelay();
    return List<PickerAlbum>.of(albumList);
  }

  @override
  Future<List<PickerAsset>> assets({
    required PickerAlbum album,
    required int offset,
    required int count,
  }) async {
    assetQueries.add(FakeAssetQuery(album.id, offset, count));
    await _maybeDelay();
    final List<PickerAsset> all =
        assetsByAlbum[album.id] ?? const <PickerAsset>[];
    if (offset >= all.length || count <= 0) {
      return const <PickerAsset>[];
    }
    final int end = (offset + count).clamp(0, all.length);
    return all.sublist(offset, end);
  }

  @override
  Future<Uint8List?> thumbnail(
    String id,
    ThumbSize size, {
    int quality = 85,
  }) async =>
      thumbnailBytes;

  @override
  Future<File?> file(
    String id, {
    void Function(double)? onProgress,
    TransformCancelToken? cancelToken,
  }) {
    if (failingFiles.contains(id)) {
      return Future<File?>.error(
        const TransformException(
          TransformFailure.sourceUnreadable,
          'FakeAssetSource was told to fail this asset.',
        ),
      );
    }
    if (missingFiles.contains(id)) {
      onProgress?.call(1);
      return Future<File?>.value();
    }
    final File? registered = filesById[id];
    if (registered != null) {
      onProgress?.call(1);
      return Future<File?>.value(registered);
    }
    if (pendingFiles.contains(id)) {
      final Completer<File?> completer = Completer<File?>();
      _pending[id] = completer;
      if (onProgress != null) {
        _progressSinks[id] = onProgress;
      }
      return completer.future;
    }
    onProgress?.call(1);
    return Future<File?>.value(File('/fake/$id'));
  }

  @override
  Future<bool> isLocallyAvailable(String id) async =>
      !locallyUnavailable.contains(id);

  @override
  Future<void> manageLimitedSelection(Set<PickerMediaType> kinds) async {
    manageLimitedSelectionCalls += 1;
  }

  /// Makes [prefetch] throw, so callers can be proved to guard.
  bool prefetchThrows = false;

  final List<FakePrefetchQuery> prefetchQueries = <FakePrefetchQuery>[];

  @override
  Future<void> prefetch(
    List<String> ids,
    ThumbSize size, {
    int quality = 85,
  }) async {
    prefetchQueries.add(FakePrefetchQuery(List<String>.of(ids), size, quality));
    if (prefetchThrows) {
      throw StateError(
          'PhotoCachingManager is experimental and just proved it.');
    }
  }
}
