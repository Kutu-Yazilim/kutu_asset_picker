import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:photo_manager/photo_manager.dart';

import 'asset_source.dart';
import 'photo_manager_filter.dart';
import 'photo_manager_mappers.dart';
import 'photo_manager_permission.dart';
import 'picker_album.dart';
import 'picker_asset.dart';
import 'picker_media_type.dart';
import 'picker_permission.dart';

/// The only production [AssetSource].
///
/// Everything `photo_manager` in this package lives behind this class:
/// `AssetEntity` and `AssetPathEntity` never escape it (design §4.1).
final class PhotoManagerAssetSource implements AssetSource {
  PhotoManagerAssetSource() {
    _changes = StreamController<void>.broadcast(onListen: _startNotifying);
  }

  /// Album id → the platform handle that produced it. `assets()` needs the
  /// handle, and re-fetching the whole album list per page would be absurd.
  final Map<String, AssetPathEntity> _paths = <String, AssetPathEntity>{};

  late final StreamController<void> _changes;

  bool _disposed = false;
  bool _notifying = false;

  @override
  Stream<void> get changes => _changes.stream;

  /// Starts platform change notification on the first listener, not in the
  /// constructor: a source that is only ever asked for albums and thumbnails
  /// makes no channel call it does not need, and a host without the plugin
  /// (a unit test, a desktop harness) constructs one without an unhandled
  /// `MissingPluginException`. Best-effort on purpose — a failed subscription
  /// costs a manual refresh, not the picker.
  void _startNotifying() {
    if (_notifying || _disposed) {
      return;
    }
    _notifying = true;
    PhotoManager.addChangeCallback(_onPlatformChange);
    unawaited(
        PhotoManager.startChangeNotify().then((_) {}, onError: (Object _) {}));
  }

  void _onPlatformChange(MethodCall call) {
    if (!_disposed && !_changes.isClosed) {
      _changes.add(null);
    }
  }

  /// Stops change notification and closes the stream.
  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    if (_notifying) {
      PhotoManager.removeChangeCallback(_onPlatformChange);
      await PhotoManager.stopChangeNotify()
          .then((_) {}, onError: (Object _) {});
    }
    await _changes.close();
  }

  @override
  Future<PickerPermission> requestPermission(Set<PickerMediaType> kinds) async {
    final PermissionState state = await PhotoManager.requestPermissionExtend(
      requestOption: PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: requestTypeFor(kinds),
          // ACCESS_MEDIA_LOCATION is a separate, scarier prompt and this
          // picker has no use for GPS EXIF.
          mediaLocation: false,
        ),
      ),
    );
    return pickerPermissionFrom(state);
  }

  @override
  Future<List<PickerAlbum>> albums(
    Set<PickerMediaType> kinds, {
    Duration? maxVideoDuration,
  }) async {
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: requestTypeFor(kinds),
      filterOption: buildPickerFilter(maxVideoDuration: maxVideoDuration),
    );

    // Counts are a platform round trip each; issue them together.
    final List<int> counts = await Future.wait<int>(
      paths.map((AssetPathEntity p) => p.assetCountAsync),
    );

    _paths
      ..clear()
      ..addEntries(paths.map(
        (AssetPathEntity p) => MapEntry<String, AssetPathEntity>(p.id, p),
      ));

    return <PickerAlbum>[
      for (int i = 0; i < paths.length; i += 1)
        pickerAlbumFrom(paths[i], counts[i]),
    ];
  }

  @override
  Future<List<PickerAsset>> assets({
    required PickerAlbum album,
    required int offset,
    required int count,
  }) async {
    // getAssetListRange asserts `end > start`.
    if (count <= 0) {
      return const <PickerAsset>[];
    }

    final AssetPathEntity? path = _paths[album.id];
    if (path == null) {
      throw StateError(
        'Album ${album.id} was never listed by this AssetSource. Call '
        'albums() before assets(); a PickerAlbum is not a platform handle.',
      );
    }

    final List<AssetEntity> entities =
        await path.getAssetListRange(start: offset, end: offset + count);

    return <PickerAsset>[
      for (final AssetEntity e in entities)
        if (pickerAssetFrom(e) case final PickerAsset asset) asset,
    ];
  }

  @override
  Future<Uint8List?> thumbnail(
    String id,
    ThumbSize size, {
    int quality = 85,
  }) async {
    final AssetEntity? entity = await AssetEntity.fromId(id);
    if (entity == null) {
      return null;
    }
    // Quality is passed explicitly on every call: this overload defaults to
    // 100 while ThumbnailOption defaults to 95, so inheriting is a coin flip
    // (design §4.4).
    return entity.thumbnailDataWithSize(
      ThumbnailSize(size.width, size.height),
      quality: quality,
    );
  }

  @override
  Future<File?> file(
    String id, {
    void Function(double)? onProgress,
    TransformCancelToken? cancelToken,
  }) async {
    final AssetEntity? entity = await AssetEntity.fromId(id);
    if (entity == null) {
      return null;
    }

    // PMProgressHandler's constructor asserts iOS/macOS. Constructing one on
    // Android throws in debug and is pointless in any case — Android assets
    // are always local.
    PMProgressHandler? handler;
    StreamSubscription<PMProgressState>? progressSub;
    if (onProgress != null && (Platform.isIOS || Platform.isMacOS)) {
      handler = PMProgressHandler();
      progressSub = handler.stream.listen(
        (PMProgressState state) => onProgress(state.progress),
      );
    }

    // PMCancelToken is honoured on iOS/macOS only; the caller's
    // TransformCancelToken is the cross-platform signal and the caller races
    // it (see PickerCommit).
    final PMCancelToken? platformToken =
        (Platform.isIOS || Platform.isMacOS) ? PMCancelToken() : null;
    if (cancelToken != null && platformToken != null) {
      unawaited(
        Future<void>.microtask(() async {
          while (!cancelToken.isCancelled) {
            await Future<void>.delayed(_cancelPollInterval);
          }
          await platformToken.cancelRequest();
        }),
      );
    }

    try {
      // isOrigin: false returns the compressed representation, which is what
      // the crop step consumes. `originFile` on HEIC fails outright on Android
      // 10 (design §7.5).
      return await entity.loadFile(
        isOrigin: false,
        progressHandler: handler,
        cancelToken: platformToken,
      );
    } finally {
      await progressSub?.cancel();
    }
  }

  @override
  Future<bool> isLocallyAvailable(String id) async {
    final AssetEntity? entity = await AssetEntity.fromId(id);
    if (entity == null) {
      return false;
    }
    return entity.isLocallyAvailable();
  }

  @override
  Future<void> manageLimitedSelection(Set<PickerMediaType> kinds) async {
    // iOS ignores the type argument and on iOS 14 completes immediately;
    // Android 14+ does filter by type (design §4.2). Callers must re-query
    // albums and restart paging after this returns either way.
    await PhotoManager.presentLimited(type: requestTypeFor(kinds));
  }

  @override
  Future<void> prefetch(
    List<String> ids,
    ThumbSize size, {
    int quality = 85,
  }) async {
    if (ids.isEmpty) {
      return;
    }
    try {
      final List<AssetEntity> entities = <AssetEntity>[];
      for (final String id in ids) {
        final AssetEntity? entity = await AssetEntity.fromId(id);
        if (entity != null) {
          entities.add(entity);
        }
      }
      if (entities.isEmpty) {
        return;
      }
      await PhotoCachingManager().requestCacheAssets(
        assets: entities,
        option: ThumbnailOption(
          size: ThumbnailSize(size.width, size.height),
          quality: quality,
        ),
      );
    } on Object {
      // Swallowed on purpose. PhotoCachingManager is Experimental in
      // photo_manager's own README (design §4.4); a cache warm that fails
      // costs a few milliseconds of decode later and nothing else.
    }
  }
}

/// How often the cross-platform cancel token is polled while an iCloud
/// download is in flight. `TransformCancelToken` exposes no callback, so a
/// poll is the only bridge to `PMCancelToken`.
const Duration _cancelPollInterval = Duration(milliseconds: 200);
