import 'dart:async';

import 'package:kutu_asset_picker/src/export/export_controller.dart';
import 'package:kutu_asset_picker/src/providers/injection_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'picker_step_controller.g.dart';

/// Which screen the picker is showing. Two steps, because a live crop pane
/// above the grid would make the picker hold live crop state for every selected
/// asset and force the cropper to be built into two different hosts (spec
/// §2.6).
enum AssetPickerStep { grid, crop }

@Riverpod(keepAlive: true)
class PickerStepController extends _$PickerStepController {
  @override
  AssetPickerStep build() => AssetPickerStep.grid;

  /// Advance from the grid.
  ///
  /// With `enableCrop: false` there is no crop step at all: the export runs
  /// immediately on full-frame rects, and the source still travels through the
  /// transform seam so what comes back is a renderable JPEG rather than the
  /// original HEIC — Flutter cannot render HEIC and `originFile` on HEIC fails
  /// outright on Android 10 (spec §7.5).
  void next() {
    if (ref.read(assetPickerConfigProvider).enableCrop) {
      state = AssetPickerStep.crop;
      return;
    }
    unawaited(ref.read(exportControllerProvider.notifier).run());
  }

  void back() => state = AssetPickerStep.grid;
}
