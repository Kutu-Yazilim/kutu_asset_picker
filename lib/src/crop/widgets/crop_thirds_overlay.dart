import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_durations.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_sizes.dart';
import 'package:kutu_asset_picker/src/crop/crop_providers.dart';
import 'package:kutu_asset_picker/src/theme/asset_picker_theme_scope.dart';

/// The rule-of-thirds guide.
///
/// Fades in while a gesture is in flight and out on release — it is a
/// composition aid, not decoration, and a permanently visible grid competes
/// with the photograph the author is trying to look at.
class CropThirdsOverlay extends ConsumerWidget {
  const CropThirdsOverlay({required this.window, super.key});

  final Size window;

  @override
  Widget build(BuildContext context, WidgetRef ref) => IgnorePointer(
        child: AnimatedOpacity(
          opacity: ref.watch(cropInteractionProvider) ? 1 : 0,
          duration: AssetPickerDurations.thirdsFade,
          child: CustomPaint(
            size: window,
            painter: _ThirdsPainter(color: context.pickerTheme.cropGridLine),
          ),
        ),
      );
}

class _ThirdsPainter extends CustomPainter {
  const _ThirdsPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = AssetPickerSizes.thirdsLineWidth;
    for (var step = 1; step <= 2; step += 1) {
      final x = size.width * step / 3;
      final y = size.height * step / 3;
      canvas
        ..drawLine(Offset(x, 0), Offset(x, size.height), paint)
        ..drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_ThirdsPainter oldDelegate) => oldDelegate.color != color;
}
