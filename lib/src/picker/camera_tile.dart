import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/picker_tuning.dart';
import '../providers/camera_capture_provider.dart';
import '../text/asset_picker_text.dart';
import '../text/asset_picker_text_scope.dart';
import '../theme/asset_picker_theme_scope.dart';
import '../theme/resolved_asset_picker_theme.dart';

/// The first cell in the grid, which delegates to the OS camera.
///
/// A fully in-package camera was rejected as a second large subsystem —
/// torch, focus, zoom, ratio preview, orientation and its own permissions —
/// on top of an already-large video scope (design §2.8). This tile only
/// renders when the host app supplied a [PickerCameraDelegate]; the grid checks
/// that before building it.
class CameraTile extends ConsumerWidget {
  /// Creates a [CameraTile].
  const CameraTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ResolvedAssetPickerTheme theme = context.pickerTheme;
    final AssetPickerText text = context.pickerText;
    final CameraCaptureStatus status = ref.watch(cameraCaptureProvider);
    final bool capturing = status == CameraCaptureStatus.capturing;
    final bool failed = status == CameraCaptureStatus.failed;

    return RepaintBoundary(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: capturing
            ? null
            : () => ref.read(cameraCaptureProvider.notifier).capture(),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(theme.cellRadius),
          child: ColoredBox(
            color: theme.surface,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  failed ? Icons.error_outline : Icons.photo_camera_outlined,
                  size: PickerChromeSizes.cameraIconSize,
                  color: failed ? theme.danger : theme.onSurfaceMuted,
                ),
                Text(
                  failed ? text.pickerCaptureFailed : text.pickerCameraTile,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.labelStyle.copyWith(
                    color: failed ? theme.danger : theme.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
