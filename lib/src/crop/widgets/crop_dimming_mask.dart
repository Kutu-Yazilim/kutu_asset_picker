import 'package:flutter/material.dart';
import 'package:kutu_asset_picker/src/config/picker_enums.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_sizes.dart';
import 'package:kutu_asset_picker/src/crop/crop_window_geometry.dart';
import 'package:kutu_asset_picker/src/theme/asset_picker_theme_scope.dart';

/// Dims everything outside the crop window and outlines the window itself.
///
/// One widget covers both [CropOverlayShape] values because they are the same
/// painter with a different hole; a second near-identical widget would be two
/// places for the mask colour and the border width to drift apart.
///
/// Mount inside a `Positioned.fill` — the painter needs the stage's full size
/// to know what to dim.
class CropDimmingMask extends StatelessWidget {
  const CropDimmingMask({
    required this.window,
    required this.shape,
    super.key,
  });

  final Size window;
  final CropOverlayShape shape;

  @override
  Widget build(BuildContext context) => CustomPaint(
        painter: _CropMaskPainter(
          window: window,
          shape: shape,
          mask: context.pickerTheme.cropMask,
          border: context.pickerTheme.cropWindowBorder,
        ),
      );
}

class _CropMaskPainter extends CustomPainter {
  const _CropMaskPainter({
    required this.window,
    required this.shape,
    required this.mask,
    required this.border,
  });

  final Size window;
  final CropOverlayShape shape;
  final Color mask;
  final Color border;

  @override
  void paint(Canvas canvas, Size size) {
    final hole = cropWindowPath(cropWindowRect(size, window), shape);
    canvas
      ..drawPath(
        Path.combine(
          PathOperation.difference,
          Path()..addRect(Offset.zero & size),
          hole,
        ),
        Paint()..color = mask,
      )
      ..drawPath(
        hole,
        Paint()
          ..color = border
          ..style = PaintingStyle.stroke
          ..strokeWidth = AssetPickerSizes.windowBorderWidth,
      );
  }

  @override
  bool shouldRepaint(_CropMaskPainter oldDelegate) =>
      oldDelegate.window != window ||
      oldDelegate.shape != shape ||
      oldDelegate.mask != mask ||
      oldDelegate.border != border;
}
