import 'dart:io';
import 'dart:typed_data';

import 'package:kutu_asset_picker/src/source/asset_source.dart';
import 'package:kutu_asset_picker/src/source/picker_album.dart';
import 'package:kutu_asset_picker/src/source/picker_asset.dart';
import 'package:kutu_asset_picker/src/source/picker_media_type.dart';
import 'package:kutu_asset_picker/src/source/picker_permission.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

/// A hand-written `AssetSource` for this slice's tests.
///
/// Deliberately local rather than slice 3's shared `FakeAssetSource`: these
/// tests assert on which file came back and in what order, and instrumenting a
/// shared fake for one slice's assertions is how a shared fake grows into a
/// second implementation nobody maintains.
class StubAssetSource implements AssetSource {
  StubAssetSource({
    this.files = const {},
    this.thumbnailBytes,
    this.locallyAvailable = true,
  });

  /// Asset id → the file `file()` hands back. A missing id yields null, which
  /// is the iCloud-not-downloaded case.
  final Map<String, File> files;

  final Uint8List? thumbnailBytes;
  final bool locallyAvailable;

  /// Every id `file()` was called with, in order.
  final List<String> fileCalls = <String>[];

  @override
  Future<File?> file(
    String id, {
    void Function(double)? onProgress,
    TransformCancelToken? cancelToken,
  }) async {
    fileCalls.add(id);
    return files[id];
  }

  @override
  Future<Uint8List?> thumbnail(
    String id,
    ThumbSize size, {
    int quality = 85,
  }) async =>
      thumbnailBytes;

  @override
  Future<void> prefetch(
    List<String> ids,
    ThumbSize size, {
    int quality = 85,
  }) async {}

  @override
  Future<bool> isLocallyAvailable(String id) async => locallyAvailable;

  @override
  Stream<void> get changes => const Stream<void>.empty();

  @override
  Future<List<PickerAlbum>> albums(
    Set<PickerMediaType> kinds, {
    Duration? maxVideoDuration,
  }) async =>
      const [];

  @override
  Future<List<PickerAsset>> assets({
    required PickerAlbum album,
    required int offset,
    required int count,
  }) async =>
      const [];

  @override
  Future<void> manageLimitedSelection(Set<PickerMediaType> kinds) async {}

  @override
  Future<PickerPermission> requestPermission(
    Set<PickerMediaType> kinds,
  ) async =>
      PickerPermission.full;
}
