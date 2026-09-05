import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kutu_asset_picker/src/config/asset_picker_config.dart';
import 'package:kutu_asset_picker/src/picker/asset_picker_view.dart';
import 'package:kutu_asset_picker/src/providers/injection_providers.dart';
import 'package:kutu_asset_picker/src/result/asset_picker_result.dart';
import 'package:kutu_asset_picker/src/source/asset_source.dart';
import 'package:kutu_asset_picker/src/text/asset_picker_text.dart';
import 'package:kutu_asset_picker/src/theme/asset_picker_theme.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

/// The `ProviderScope` the picker needs, plus the view.
///
/// A consumer embedding [AssetPickerView] inside their own Riverpod tree writes
/// the equivalent overrides themselves; this widget exists so
/// `KutuAssetPicker.show` — and the `example/` app — do not have to.
class AssetPickerScope extends StatelessWidget {
  const AssetPickerScope({
    required this.config,
    required this.source,
    required this.onCompleted,
    required this.onCancelled,
    this.transform,
    this.theme,
    this.text,
    super.key,
  });

  final AssetPickerConfig config;
  final AssetSource source;
  final ValueChanged<AssetPickerResult> onCompleted;
  final VoidCallback onCancelled;

  /// Null keeps `mediaTransformProvider`'s real default, which is the plugin.
  final MediaTransform? transform;

  final AssetPickerTheme? theme;
  final AssetPickerText? text;

  @override
  Widget build(BuildContext context) {
    final engine = transform;
    return ProviderScope(
      overrides: [
        assetPickerConfigProvider.overrideWithValue(config),
        assetSourceProvider.overrideWithValue(source),
        if (engine != null) mediaTransformProvider.overrideWithValue(engine),
      ],
      child: AssetPickerView(
        onCompleted: onCompleted,
        onCancelled: onCancelled,
        theme: theme,
        text: text,
      ),
    );
  }
}
