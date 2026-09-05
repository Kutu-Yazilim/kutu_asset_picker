import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;
import 'package:kutu_asset_picker/kutu_asset_picker.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'kutu_asset_picker example',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3355FF)),
        ),
        darkTheme: ThemeData.dark(),
        home: const ExampleHome(),
      );
}

class ExampleHome extends StatelessWidget {
  const ExampleHome({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('kutu_asset_picker')),
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(builder: (_) => const ExamplePicker()),
            ),
            child: const Text('Open the picker'),
          ),
        ),
      );
}

/// The host owns the scope, exactly as contract §9 requires.
class ExamplePicker extends StatelessWidget {
  const ExamplePicker({super.key});

  @override
  Widget build(BuildContext context) => ProviderScope(
        overrides: <Override>[
          assetPickerConfigProvider.overrideWithValue(
            const AssetPickerConfig(maxSelection: 5),
          ),
          assetSourceProvider.overrideWithValue(PhotoManagerAssetSource()),
        ],
        child: AssetPickerView(
          onCompleted: (List<PickerAsset> assets) =>
              Navigator.of(context).pop(),
          onCancelled: () => Navigator.of(context).pop(),
        ),
      );
}
