import 'package:flutter/foundation.dart';

/// Where one selected asset is, right now, relative to the device.
///
/// Sealed so the progress bar's `switch` is exhaustive and a fourth state
/// cannot be silently rendered as "fine".
@immutable
sealed class AssetAvailability {
  const AssetAvailability();
}

/// The file exists on the device. Nothing to fetch.
///
/// Always the answer on Android, where `isLocallyAvailable` is definitionally
/// true; the interesting cases are iOS and macOS with Optimize Storage on.
@immutable
final class AssetReady extends AssetAvailability {
  /// Creates a [AssetReady].
  const AssetReady();

  @override
  bool operator ==(Object other) => other is AssetReady;

  @override
  int get hashCode => (AssetReady).hashCode;

  @override
  String toString() => 'AssetReady()';
}

/// The file lives in iCloud and is being fetched. [progress] is 0..1.
@immutable
final class AssetDownloading extends AssetAvailability {
  /// Creates a [AssetDownloading].
  const AssetDownloading(this.progress);

  /// The progress.
  final double progress;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetDownloading && other.progress == progress;

  @override
  int get hashCode => Object.hash(AssetDownloading, progress);

  @override
  String toString() => 'AssetDownloading($progress)';
}

/// The download failed, returned nothing, or was cancelled.
///
/// One of these is a per-asset error the user can retry — never a reason to
/// discard the rest of the batch (design §4.5).
@immutable
final class AssetUnavailable extends AssetAvailability {
  /// Creates a [AssetUnavailable].
  const AssetUnavailable();

  @override
  bool operator ==(Object other) => other is AssetUnavailable;

  @override
  int get hashCode => (AssetUnavailable).hashCode;

  @override
  String toString() => 'AssetUnavailable()';
}
