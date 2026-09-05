import 'package:flutter/material.dart';

import 'demo_configs.dart';
import 'demo_launch_button.dart';
import 'demo_pick_controller.dart';
import 'example_app.dart';

/// The example's only screen: one button per configuration, and a summary of
/// the last result.
class ExampleHome extends StatelessWidget {
  /// Creates the screen.
  const ExampleHome({required this.controller, super.key});

  /// Key on the summary text, for the smoke test.
  static const Key summaryKey = Key('example_home.summary');

  /// Padding around the body.
  static const double bodyPadding = 16;

  /// Gap between two buttons.
  static const double buttonGap = 12;

  /// The controller that owns every async step.
  final DemoPickController controller;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text(ExampleSeed.title)),
        body: Padding(
          padding: const EdgeInsets.all(bodyPadding),
          child: ListenableBuilder(
            listenable: controller,
            builder: (BuildContext context, Widget? child) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                DemoLaunchButton(
                  label: DemoLabels.post,
                  config: DemoConfigs.post,
                  controller: controller,
                ),
                const SizedBox(height: buttonGap),
                DemoLaunchButton(
                  label: DemoLabels.story,
                  config: DemoConfigs.story,
                  controller: controller,
                ),
                const SizedBox(height: buttonGap),
                DemoLaunchButton(
                  label: DemoLabels.avatar,
                  config: DemoConfigs.avatar,
                  controller: controller,
                ),
                const SizedBox(height: buttonGap),
                DemoLaunchButton(
                  label: DemoLabels.banner,
                  config: DemoConfigs.banner,
                  controller: controller,
                ),
                const SizedBox(height: bodyPadding),
                Text(controller.summary, key: summaryKey),
              ],
            ),
          ),
        ),
      );
}
