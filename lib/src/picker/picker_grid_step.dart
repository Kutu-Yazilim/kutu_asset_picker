import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/picker_enums.dart';
import '../providers/injection_providers.dart';
import 'asset_picker_page.dart';
import 'asset_picker_sheet.dart';

/// The whole grid screen: app bar, permission gate, grid, selected strip and
/// footer, in whichever surface `config.pickerSurface` names.
///
/// `pickerSurface` and `cropSurface` are configured independently (design
/// §2.6), so an avatar picker can be a lightweight sheet while a post composer
/// is a full page — and only this widget has to know which.
///
/// **The constructor is a cross-slice contract.** Slice 4 imports this file and
/// builds `PickerGridStep(onNext: …, onCancel: …)` as the grid branch of its
/// two-step view; the parameter names, order and optionality must not change.
class PickerGridStep extends ConsumerWidget {
  /// Creates a [PickerGridStep].
  const PickerGridStep({
    required this.onNext,
    required this.onCancel,
    super.key,
  });

  /// The on next.
  final VoidCallback onNext;

  /// The on cancel.
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      switch (ref.watch(assetPickerConfigProvider).pickerSurface) {
        PickerSurface.page =>
          AssetPickerPage(onNext: onNext, onCancel: onCancel),
        PickerSurface.sheet =>
          AssetPickerSheet(onNext: onNext, onCancel: onCancel),
      };
}
