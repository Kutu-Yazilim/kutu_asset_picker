import 'dart:io';
import 'dart:typed_data';

import 'package:kutu_media_transform/kutu_media_transform.dart';

import '../camera/captured_media.dart';
import '../source/asset_source.dart';
import '../source/picker_album.dart';
import '../source/picker_asset.dart';
import '../source/picker_media_type.dart';
import '../source/picker_permission.dart';

/// [delegate], with the flattened file substituted for every id the
/// slow-motion pass rewrote.
///
/// A wrapper rather than a mutation of `PhotoManagerAssetSource`: the
/// substitution is picker-session state that lives exactly as long as the
/// picker route, while the gallery adapter is a stateless `photo_manager`
/// shim. Wrapping also means the crop preview and the export queue reach the
/// rewritten file through the `AssetSource` seam they already use, so neither
/// has a second lookup it can forget.
final class FlattenedAssetSource implements AssetSource {
  /// Creates a [FlattenedAssetSource].
  const FlattenedAssetSource({required this.delegate, required this.flattened});

  /// The delegate.
  final AssetSource delegate;

  /// Asset id → the rewritten file. Ids absent here fall straight through.
  final Map<String, File> flattened;

  @override
  Future<File?> file(
    String id, {
    void Function(double)? onProgress,
    TransformCancelToken? cancelToken,
  }) async {
    final rewritten = flattened[id];
    if (rewritten == null) {
      return delegate.file(
        id,
        onProgress: onProgress,
        cancelToken: cancelToken,
      );
    }
    // Already on disk. Reporting completion keeps any caller driving a bar off
    // this call from sitting at zero forever.
    onProgress?.call(1);
    return rewritten;
  }

  @override
  Future<bool> isLocallyAvailable(String id) async =>
      flattened.containsKey(id) || await delegate.isLocallyAvailable(id);

  @override
  Future<PickerPermission> requestPermission(Set<PickerMediaType> kinds) =>
      delegate.requestPermission(kinds);

  @override
  Future<List<PickerAlbum>> albums(
    Set<PickerMediaType> kinds, {
    Duration? maxVideoDuration,
  }) =>
      delegate.albums(kinds, maxVideoDuration: maxVideoDuration);

  @override
  Future<List<PickerAsset>> assets({
    required PickerAlbum album,
    required int offset,
    required int count,
  }) =>
      delegate.assets(album: album, offset: offset, count: count);

  @override
  Future<Uint8List?> thumbnail(String id, ThumbSize size, {int quality = 85}) =>
      delegate.thumbnail(id, size, quality: quality);

  @override
  Future<void> prefetch(List<String> ids, ThumbSize size, {int quality = 85}) =>
      delegate.prefetch(ids, size, quality: quality);

  @override
  Future<void> manageLimitedSelection(Set<PickerMediaType> kinds) =>
      delegate.manageLimitedSelection(kinds);

  @override
  Future<PickerAsset?> saveToLibrary(CapturedMedia capture) =>
      delegate.saveToLibrary(capture);

  @override
  Stream<void> get changes => delegate.changes;
}
