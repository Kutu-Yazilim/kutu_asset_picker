import 'package:kutu_media_transform/kutu_media_transform.dart';

/// The pixel size of the file the export is about to write.
///
/// This composes the two canonical primitives from `kutu_media_transform` in
/// exactly the order the native exporters run them (spec §7.4 invariant 4):
///
/// 1. [decodeTargetSize] caps the **source's** long edge, because both
///    platforms apply [maxLongEdge] *at decode* — `ImageDecoder.setTargetSize`
///    and `kCGImageSourceThumbnailMaxPixelSize` — so a full-resolution bitmap
///    is never allocated.
/// 2. [CropRect.roundedToEvenPixels] takes the crop out of that already-
///    downscaled image, and guarantees even extents.
///
/// There is exactly **one** rounding rule in this feature, it lives in
/// `kutu_media_transform`, and it is pinned across Dart, Kotlin and Swift by a
/// nine-row golden table. This function must never re-derive it — if preview
/// and export round differently a persistent 1 px drift appears, which on a
/// 1:1 crop is very visible.
({int width, int height}) exportedPixelSize({
  required CropRect crop,
  required int sourceWidth,
  required int sourceHeight,
  int? maxLongEdge,
}) {
  final (int decodedWidth, int decodedHeight) =
      decodeTargetSize(sourceWidth, sourceHeight, maxLongEdge);
  final PixelRect rect = crop.roundedToEvenPixels(decodedWidth, decodedHeight);
  return (width: rect.width, height: rect.height);
}
