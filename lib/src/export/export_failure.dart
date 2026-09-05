import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:flutter/foundation.dart';

/// One asset's export error.
///
/// A per-asset failure surfaces per asset and does **not** fail the batch
/// (spec §7.5). One iCloud video that will not download must not cost the
/// author the nine photos that exported fine.
@immutable
final class ExportFailure {
  const ExportFailure({
    required this.assetId,
    required this.failure,
    required this.message,
  });

  final String assetId;
  final TransformFailure failure;
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExportFailure &&
          other.assetId == assetId &&
          other.failure == failure &&
          other.message == message;

  @override
  int get hashCode => Object.hash(assetId, failure, message);

  @override
  String toString() => 'ExportFailure($assetId, $failure, $message)';
}
