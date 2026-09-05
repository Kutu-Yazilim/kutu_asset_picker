import 'package:flutter/material.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';

import 'demo_configs.dart';

/// Owns every `await` and every derived string in the example.
///
/// A plain [ChangeNotifier] rather than a Riverpod notifier: the picker creates
/// its own `ProviderScope`, and the example should not imply that a host app has
/// to adopt Riverpod to use the package.
final class DemoPickController extends ChangeNotifier {
  /// The most recent result, or null before the first completed pick.
  AssetPickerResult? result;

  /// The label of the configuration that produced [result].
  String? lastLabel;

  /// The one line the home screen renders.
  String get summary {
    final AssetPickerResult? picked = result;
    if (picked == null) {
      return DemoLabels.nothingPicked;
    }
    return '$lastLabel${DemoLabels.separator}'
        '${picked.assets.length}${DemoLabels.assetsUnit}';
  }

  /// Opens the picker with [config] and records what came back.
  ///
  /// [context] is used before the first `await` and never after it, so there is
  /// no async-gap hazard — a real one here, because the repo's
  /// `use_build_context_synchronously` lint is off.
  Future<void> pick(
    BuildContext context,
    String label,
    AssetPickerConfig config,
  ) async {
    final AssetPickerResult? picked =
        await KutuAssetPicker.show(context, config: config);
    if (picked == null) {
      return;
    }
    result = picked;
    lastLabel = label;
    notifyListeners();
  }
}
