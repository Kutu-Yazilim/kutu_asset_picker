import 'package:flutter/material.dart';

import 'demo_pick_controller.dart';
import 'example_home.dart';

/// The example application.
class ExampleApp extends StatefulWidget {
  /// Creates the example application.
  const ExampleApp({super.key});

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final DemoPickController _controller = DemoPickController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: ExampleSeed.title,
        // The pub.dev screenshots are captured from this app; a DEBUG ribbon
        // across the corner of every one of them is noise, not information.
        debugShowCheckedModeBanner: false,
        theme:
            ThemeData(colorSchemeSeed: ExampleSeed.color, useMaterial3: true),
        darkTheme: ThemeData(
          colorSchemeSeed: ExampleSeed.color,
          brightness: Brightness.dark,
          useMaterial3: true,
        ),
        home: ExampleHome(controller: _controller),
      );
}

/// The one colour and the one title the example picks, kept out of the widgets
/// (Flutter rules 3 and 8).
abstract final class ExampleSeed {
  /// Seed colour for the example's `ColorScheme`.
  static const Color color = Color(0xFF3355FF);

  /// `MaterialApp.title` and the app bar's copy.
  static const String title = 'kutu_asset_picker';
}
