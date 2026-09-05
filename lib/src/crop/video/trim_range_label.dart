import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'video_trim_controller.dart';
import '../../theme/asset_picker_theme_scope.dart';
import '../../text/asset_picker_text_scope.dart';

/// The kept range, in words.
class TrimRangeLabel extends ConsumerWidget {
  /// Creates a [TrimRangeLabel].
  const TrimRangeLabel({super.key, required this.assetId, required this.total});

  /// The asset id.
  final String assetId;

  /// The total.
  final Duration total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.pickerTheme;
    final text = context.pickerText;
    final trim = ref.watch(videoTrimControllerProvider(assetId, total)).trim;
    return Text(
      text.durationRange(trim.start, trim.end),
      style: theme.labelStyle.copyWith(color: theme.onSurface),
    );
  }
}
