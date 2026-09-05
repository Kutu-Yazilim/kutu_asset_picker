import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'video_export_fraction.dart';
import '../theme/asset_picker_theme_scope.dart';

/// The within-asset progress of a running video export.
class VideoExportProgressBar extends ConsumerWidget {
  const VideoExportProgressBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => LinearProgressIndicator(
        value: ref.watch(videoExportFractionProvider),
        color: context.pickerTheme.progressIndicator,
      );
}
