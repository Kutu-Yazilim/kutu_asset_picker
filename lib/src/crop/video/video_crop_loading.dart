import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/asset_picker_theme_scope.dart';

/// The crop area while a video is being materialised.
///
/// Sized to fill, so the area it occupies is the area the viewport will
/// occupy — nothing jumps when the player arrives.
class VideoCropLoading extends ConsumerWidget {
  const VideoCropLoading({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Center(
        child: CircularProgressIndicator(
          color: context.pickerTheme.progressIndicator,
        ),
      );
}
