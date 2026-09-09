import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../camera/captured_media.dart';
import '../camera/picker_camera_delegate.dart';
import '../source/picker_asset.dart';
import 'asset_page_provider.dart';
import 'injection_providers.dart';
import 'selection_provider.dart';

part 'camera_capture_provider.g.dart';

/// What the camera cell is doing.
enum CameraCaptureStatus {
  /// Nothing in flight.
  idle,

  /// A capture is running, so the tile is inert.
  capturing,

  /// The last attempt failed. The tile says so, and the next tap retries.
  failed,
}

/// Drives the OS camera delegate.
///
/// All the `await`ing happens here and none of it in the widget (Flutter
/// rule 9). The tile goes inert while a capture is in flight rather than
/// launching two cameras on a double tap.
@Riverpod(keepAlive: true)
class CameraCapture extends _$CameraCapture {
  @override
  CameraCaptureStatus build() => CameraCaptureStatus.idle;

  /// Capture.
  Future<void> capture() async {
    if (state == CameraCaptureStatus.capturing) {
      return;
    }
    final PickerCameraDelegate? delegate =
        ref.read(pickerCameraDelegateProvider);
    if (delegate == null) {
      return;
    }

    state = CameraCaptureStatus.capturing;
    try {
      final CapturedMedia? capture = await delegate
          .capture(ref.read(assetPickerConfigProvider).mediaTypes);
      if (capture == null) {
        // Backed out. Not a failure, so the tile shows nothing.
        state = CameraCaptureStatus.idle;
        return;
      }

      final PickerAsset? saved =
          await ref.read(assetSourceProvider).saveToLibrary(capture);
      if (saved == null) {
        state = CameraCaptureStatus.failed;
        return;
      }

      // Prepend rather than wait for the platform change notification: the
      // user tapped the camera tile and expects their photo to be right there.
      ref.read(assetPageProvider.notifier).prepend(saved);
      // toggleAsset respects maxSelection, so a capture past the cap appears
      // in the grid without silently evicting an earlier pick.
      ref.read(selectionProvider.notifier).toggleAsset(saved);
      state = CameraCaptureStatus.idle;
    } on Object {
      // Broad on purpose. The delegate reaches a plugin (a denied camera
      // permission arrives as a PlatformException) and the save reaches the
      // platform. Neither may escape as an unhandled rejection, and both mean
      // the same thing to the user.
      state = CameraCaptureStatus.failed;
    }
  }
}
