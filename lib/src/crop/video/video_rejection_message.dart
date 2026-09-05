import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'video_rejection.dart';
import '../../theme/asset_picker_theme_scope.dart';
import '../../text/asset_picker_text_scope.dart';

/// One rejection, in the author's language.
///
/// The rejection owns its own copy lookup, so nothing here branches on the
/// subtype — adding a third rejection reason never touches this widget.
class VideoRejectionMessage extends ConsumerWidget {
  /// Creates a [VideoRejectionMessage].
  const VideoRejectionMessage({super.key, required this.rejection});

  /// The rejection.
  final VideoRejection rejection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = context.pickerTheme;
    return Text(
      rejection.message(
        context.pickerText,
      ),
      textAlign: TextAlign.center,
      style: theme.labelStyle.copyWith(color: theme.danger),
    );
  }
}
