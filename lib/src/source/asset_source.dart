import 'dart:io';
import 'dart:typed_data';

import 'package:kutu_media_transform/kutu_media_transform.dart';

import '../camera/captured_media.dart';
import 'picker_album.dart';
import 'picker_asset.dart';
import 'picker_media_type.dart';
import 'picker_permission.dart';

/// The seam over the device gallery.
///
/// `PhotoManager` is entirely static, its backing `plugin` field lives under
/// `lib/src/` (importing it trips `implementation_imports`) and
/// `PhotoManager.plugin` is getter-only — it is not injectable. Without this
/// wrapper there is no test story below the widget layer (design §4.1).
///
/// There are four implementers: [PhotoManagerAssetSource] is the only one
/// that touches the platform; `FlattenedAssetSource` is a production
/// decorator used by the crop step; `FakeAssetSource` in
/// `package:kutu_asset_picker/testing.dart` and a stub under `test/support/`
/// are the two test doubles. This is the same narrow-interface discipline
/// the PatikaX backend applies in `deps.go`.
abstract interface class AssetSource {
  /// Requests library access for [kinds] and reports the resulting state.
  Future<PickerPermission> requestPermission(Set<PickerMediaType> kinds);

  /// Lists albums, filtering videos longer than [maxVideoDuration] at query
  /// time.
  Future<List<PickerAlbum>> albums(
    Set<PickerMediaType> kinds, {
    Duration? maxVideoDuration,
  });

  /// One page of [album], newest first.
  Future<List<PickerAsset>> assets({
    required PickerAlbum album,
    required int offset,
    required int count,
  });

  /// Thumbnail bytes for [id]. [quality] is pinned by the caller on purpose —
  /// the platform defaults differ between overloads (design §4.4).
  Future<Uint8List?> thumbnail(String id, ThumbSize size, {int quality = 85});

  /// Asks the platform to warm its thumbnail cache for [ids].
  ///
  /// Best-effort by contract. `photo_manager` documents
  /// `PhotoCachingManager` as *Experimental* (design §4.4), so an
  /// implementation must swallow its own failures and callers must guard
  /// anyway — a warm-ahead is an optimisation and may never break paging.
  Future<void> prefetch(List<String> ids, ThumbSize size, {int quality = 85});

  /// The asset's file, downloading from iCloud if necessary.
  ///
  /// [onProgress] reports 0..1 for that download; [cancelToken] abandons it.
  Future<File?> file(
    String id, {
    void Function(double)? onProgress,
    TransformCancelToken? cancelToken,
  });

  /// Whether the full asset exists on the device right now.
  ///
  /// Always true on Android. On iOS/macOS with Optimize Storage a thumbnail
  /// can render perfectly while the asset itself lives only in iCloud, which
  /// is why this is a pre-flight rather than a surprise at export (design §4.5).
  Future<bool> isLocallyAvailable(String id);

  /// Presents the OS "manage limited selection" UI.
  ///
  /// When it returns, album lists and counts are stale.
  Future<void> manageLimitedSelection(Set<PickerMediaType> kinds);

  /// Saves a camera capture into the device library and returns it as a
  /// library asset.
  ///
  /// The picker addresses every asset by platform id ([PickerAsset.id]) —
  /// thumbnails resolve through it and so does export — so a capture has to
  /// become a library asset before the grid can show it. That is why the
  /// camera delegate hands back a file and this does the write: it keeps
  /// `photo_manager` inside the one layer allowed to touch it (design §4.1).
  ///
  /// Returns null when the platform saved something the picker never
  /// surfaces. Throws when the platform refused the write; the caller
  /// surfaces that rather than swallowing it.
  Future<PickerAsset?> saveToLibrary(CapturedMedia capture);

  /// Fires when the library changes — a new capture, a changed limited
  /// selection, a deletion.
  Stream<void> get changes;
}
