import 'package:kutu_asset_picker/src/crop/crop_providers.dart';
import 'package:kutu_asset_picker/src/export/export_cache.dart';
import 'package:kutu_asset_picker/src/export/export_failure.dart';
import 'package:kutu_asset_picker/src/export/export_progress.dart';
import 'package:kutu_asset_picker/src/export/export_queue.dart';
import 'package:kutu_asset_picker/src/providers/injection_providers.dart';
import 'package:kutu_asset_picker/src/result/asset_picker_result.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'video_export_fraction.dart';
import '../picker/slow_motion_flatten.dart';

part 'export_controller.g.dart';

/// Drives the sequential [ExportQueue] and publishes its progress.
///
/// [ExportController.run] **never throws**. The Done button calls it and walks
/// away — Flutter rule 9 forbids `await` in UI — so an escaping exception would surface as an
/// unhandled zone error with no UI anywhere to show it.
@Riverpod(keepAlive: true)
class ExportController extends _$ExportController {
  TransformCancelToken? _token;
  bool _disposed = false;

  @override
  ExportProgress build() {
    ref.onDispose(() => _disposed = true);
    return const ExportIdle();
  }

  /// Run.
  Future<AssetPickerResult> run() async {
    final assets = ref.read(selectedAssetsProvider);
    final token = _token = TransformCancelToken();
    final queue = ExportQueue(
      transform: ref.read(mediaTransformProvider),
      source: ref.read(flattenedAssetSourceProvider),
    );

    _emit(ExportRunning(done: 0, total: assets.length));
    try {
      ref.read(videoExportFractionProvider.notifier).reset();
      final picked = await queue.run(
        assets,
        ref.read(cropStatesProvider.notifier).stateOf,
        ref.read(assetPickerConfigProvider),
        onProgress: (done, total) =>
            _emit(ExportRunning(done: done, total: total)),
        cancelToken: token,
        onAssetFraction: (_, fraction) =>
            ref.read(videoExportFractionProvider.notifier).report(fraction),
      );
      final result = AssetPickerResult(assets: picked);
      // The consumer owns these files; `KutuAssetPicker.clearCache()` is the
      // collector (spec §3.4), and this is where it learns what to collect.
      ExportCache.rememberAll(picked);
      _emit(
        token.isCancelled || (picked.isEmpty && queue.failures.isNotEmpty)
            ? ExportFailed(failures: queue.failures)
            : ExportSucceeded(result: result, failures: queue.failures),
      );
      return result;
    } on Object catch (error) {
      _emit(
        ExportFailed(
          failures: [
            ...queue.failures,
            ExportFailure(
              assetId: '',
              failure: TransformFailure.unknown,
              message: '$error',
            ),
          ],
        ),
      );
      return const AssetPickerResult(assets: []);
    }
  }

  /// Cancels the batch. Assets already exported keep their files; the queue
  /// stops before the next one.
  void cancel() => _token?.cancel();

  /// Writing to `state` after the provider is gone throws. The picker route can
  /// be popped mid-export, so every emission goes through here.
  void _emit(ExportProgress next) {
    if (!_disposed) state = next;
  }
}
