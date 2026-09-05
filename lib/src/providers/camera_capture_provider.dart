import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../camera/picker_camera_delegate.dart';
import '../source/picker_asset.dart';
import 'asset_page_provider.dart';
import 'injection_providers.dart';
import 'selection_provider.dart';

part 'camera_capture_provider.g.dart';

/// Drives the OS camera delegate.
///
/// State is "a capture is in flight", so the tile can go inert rather than
/// launching two cameras on a double tap. All the `await`ing happens here and
/// none of it in the widget (Flutter rule 9).
@Riverpod(keepAlive: true)
class CameraCapture extends _$CameraCapture {
  @override
  bool build() => false;

  Future<void> capture() async {
    if (state) {
      return;
    }
    final PickerCameraDelegate? delegate =
        ref.read(pickerCameraDelegateProvider);
    if (delegate == null) {
      return;
    }

    state = true;
    try {
      final PickerAsset? asset = await delegate
          .capture(ref.read(assetPickerConfigProvider).mediaTypes);
      if (asset == null) {
        return;
      }
      // Prepend rather than wait for the platform change notification: the
      // user tapped the camera tile and expects their photo to be right there.
      ref.read(assetPageProvider.notifier).prepend(asset);
      // toggleAsset respects maxSelection, so a capture past the cap appears
      // in the grid without silently evicting an earlier pick.
      ref.read(selectionProvider.notifier).toggleAsset(asset);
    } finally {
      state = false;
    }
  }
}
