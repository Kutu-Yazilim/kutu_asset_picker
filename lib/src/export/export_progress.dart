import 'package:kutu_asset_picker/src/export/export_failure.dart';
import 'package:kutu_asset_picker/src/result/asset_picker_result.dart';
import 'package:flutter/foundation.dart';

/// The export state machine.
///
/// `ExportSucceeded` exists so the view can react through `ref.listen` — the
/// pattern `apps/mobile` uses everywhere — instead of a button awaiting a
/// Future, which Flutter rule 9 forbids. It carries [ExportSucceeded.failures]
/// because a batch can finish with both results and errors.
@immutable
sealed class ExportProgress {
  const ExportProgress();
}

/// Export idle.
final class ExportIdle extends ExportProgress {
  /// Creates a [ExportIdle].
  const ExportIdle();
}

/// Export running.
final class ExportRunning extends ExportProgress {
  /// Creates a [ExportRunning].
  const ExportRunning({required this.done, required this.total});

  /// The done.
  final int done;

  /// The total.
  final int total;
}

/// At least one asset exported. [failures] lists the ones that did not.
final class ExportSucceeded extends ExportProgress {
  /// Creates a [ExportSucceeded].
  const ExportSucceeded({required this.result, required this.failures});

  /// The result.
  final AssetPickerResult result;

  /// The failures.
  final List<ExportFailure> failures;
}

/// Nothing exported: every asset failed, or the batch was cancelled.
final class ExportFailed extends ExportProgress {
  /// Creates a [ExportFailed].
  const ExportFailed({required this.failures});

  /// The failures.
  final List<ExportFailure> failures;
}
