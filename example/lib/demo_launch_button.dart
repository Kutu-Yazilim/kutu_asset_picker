import 'package:flutter/material.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';

import 'demo_pick_controller.dart';

/// One configuration, one button.
class DemoLaunchButton extends StatelessWidget {
  /// Creates the button.
  const DemoLaunchButton({
    required this.label,
    required this.config,
    required this.controller,
    super.key,
  });

  /// The button's copy, and the label recorded in the summary line.
  final String label;

  /// The configuration this button opens the picker with.
  final AssetPickerConfig config;

  /// The controller that owns the `await`.
  final DemoPickController controller;

  @override
  Widget build(BuildContext context) => FilledButton(
        onPressed: () => controller.pick(context, label, config),
        child: Text(label),
      );
}
