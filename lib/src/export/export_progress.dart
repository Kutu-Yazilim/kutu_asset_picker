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

final class ExportIdle extends ExportProgress {
  const ExportIdle();
}

final class ExportRunning extends ExportProgress {
  const ExportRunning({required this.done, required this.total});

  final int done;
  final int total;
}

/// At least one asset exported. [failures] lists the ones that did not.
final class ExportSucceeded extends ExportProgress {
  const ExportSucceeded({required this.result, required this.failures});

  final AssetPickerResult result;
  final List<ExportFailure> failures;
}

/// Nothing exported: every asset failed, or the batch was cancelled.
final class ExportFailed extends ExportProgress {
  const ExportFailed({required this.failures});

  final List<ExportFailure> failures;
}
