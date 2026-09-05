import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

import 'asset_source.dart';
import 'picker_asset.dart';
import 'picker_asset_key.dart';

/// Loads one asset thumbnail through the [AssetSource] seam.
///
/// **Never fetch a thumbnail with a `FutureBuilder` over
/// `thumbnailDataWithSize` inside `build`.** That is the single biggest
/// available performance mistake in this package (design §4.4): it re-fires the
/// platform channel call and re-decodes on every rebuild, and it bypasses
/// `ScrollAwareImageProvider` — which the `Image` widget wraps around *any*
/// provider for free, deferring decodes while a fling is in progress
/// (flutter#48536).
///
/// So this provider exists to be handed to a plain [Image] widget, and
/// `AssetThumbnail` is the only place that does it.
@immutable
final class PickerAssetImageProvider extends ImageProvider<PickerAssetKey> {
  /// Creates a [PickerAssetImageProvider].
  const PickerAssetImageProvider(
    this.asset, {
    required this.source,
    required this.size,
    this.quality = 85,
  });

  /// The asset.
  final PickerAsset asset;

  /// The source.
  final AssetSource source;

  /// One flat, clamped size for the whole grid. Per-cell DPR scaling
  /// multiplies cache keys, which is the thing to avoid (design §4.4).
  final ThumbSize size;

  /// The quality.
  final int quality;

  @override
  Future<PickerAssetKey> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture<PickerAssetKey>(
        PickerAssetKey(assetId: asset.id, size: size, quality: quality),
      );

  @override
  ImageStreamCompleter loadImage(
    PickerAssetKey key,
    ImageDecoderCallback decode,
  ) =>
      MultiFrameImageStreamCompleter(
        codec: _loadBytes(key, decode),
        scale: 1,
        debugLabel: 'PickerAssetImageProvider(${key.assetId})',
        informationCollector: () => <DiagnosticsNode>[
          DiagnosticsProperty<PickerAssetKey>('Thumbnail key', key),
        ],
      );

  Future<ui.Codec> _loadBytes(
    PickerAssetKey key,
    ImageDecoderCallback decode,
  ) async {
    try {
      final Uint8List? bytes =
          await source.thumbnail(key.assetId, key.size, quality: key.quality);
      if (bytes == null || bytes.isEmpty) {
        throw StateError('No thumbnail bytes for asset ${key.assetId}.');
      }
      final ui.ImmutableBuffer buffer =
          await ui.ImmutableBuffer.fromUint8List(bytes);
      return await decode(buffer);
    } catch (_) {
      // Evict on the next microtask, not synchronously: the cache is still
      // registering this key while `loadImage` runs, and leaving a failed key
      // behind means the tile can never recover on a later rebuild.
      scheduleMicrotask(
        () => PaintingBinding.instance.imageCache.evict(key),
      );
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PickerAssetImageProvider &&
          other.asset.id == asset.id &&
          other.size.width == size.width &&
          other.size.height == size.height &&
          other.quality == quality;

  @override
  int get hashCode => Object.hash(asset.id, size.width, size.height, quality);
}
