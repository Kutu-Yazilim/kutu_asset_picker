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

/// The Riverpod container the picker needs, plus the view.
///
/// A consumer embedding [AssetPickerView] inside their own Riverpod tree writes
/// the equivalent overrides themselves; this widget exists so
/// `KutuAssetPicker.show` — and the `example/` app — do not have to.
///
/// **It owns a ROOT container, deliberately not a nested `ProviderScope`.** A
/// `ProviderScope(overrides: …)` placed under a host app's own scope becomes
/// a *child* scope, and Riverpod resolves any provider the child does not
/// override at the nearest ancestor that does — the host's root — unless that
/// provider declares `dependencies`. The picker's permission provider is not
/// overridden here, so under a host with a root scope it was read from the
/// host's container, where the injection providers throw by design, and the
/// gate rendered that error as "photo access is off" without ever asking the
/// OS. Every Riverpod app has a root scope; the example app does not, which
/// is why it never reproduced. A fresh container with no parent is what the
/// package's own test harness always used, and it is what this builds.
///
/// The picker reads nothing from the host's providers, so isolation costs it
/// nothing.
class AssetPickerScope extends StatefulWidget {
  /// Creates a [AssetPickerScope].
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

  /// The config.
  final AssetPickerConfig config;

  /// The source.
  final AssetSource source;

  /// The on completed.
  final ValueChanged<AssetPickerResult> onCompleted;

  /// The on cancelled.
  final VoidCallback onCancelled;

  /// Null keeps `mediaTransformProvider`'s real default, which is the plugin.
  final MediaTransform? transform;

  /// The theme.
  final AssetPickerTheme? theme;

  /// The text.
  final AssetPickerText? text;

  @override
  State<AssetPickerScope> createState() => _AssetPickerScopeState();
}

class _AssetPickerScopeState extends State<AssetPickerScope> {
  late final ProviderContainer _container = ProviderContainer(
    overrides: [
      assetPickerConfigProvider.overrideWithValue(widget.config),
      assetSourceProvider.overrideWithValue(widget.source),
      if (widget.transform case final MediaTransform engine)
        mediaTransformProvider.overrideWithValue(engine),
    ],
  );

  @override
  void dispose() {
    _container.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UncontrolledProviderScope(
        container: _container,
        child: AssetPickerView(
          onCompleted: widget.onCompleted,
          onCancelled: widget.onCancelled,
          theme: widget.theme,
          text: widget.text,
        ),
      );
}
