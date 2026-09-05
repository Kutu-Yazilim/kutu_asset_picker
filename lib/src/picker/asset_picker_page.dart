import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/asset_picker_theme_scope.dart';
import '../theme/resolved_asset_picker_theme.dart';
import 'picker_app_bar.dart';
import 'picker_body.dart';

/// `PickerSurface.page`: a full-screen scaffold.
///
/// No controller is passed to the body, so the grid creates and owns its own —
/// there is nothing above it competing for the drag.
class AssetPickerPage extends ConsumerWidget {
  /// Creates a [AssetPickerPage].
  const AssetPickerPage({
    super.key,
    required this.onNext,
    required this.onCancel,
  });

  /// The on next.
  final VoidCallback onNext;

  /// The on cancel.
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ResolvedAssetPickerTheme theme = context.pickerTheme;

    return Scaffold(
      backgroundColor: theme.background,
      appBar: PickerAppBar(onCancel: onCancel),
      body: PickerBody(onNext: onNext),
    );
  }
}
