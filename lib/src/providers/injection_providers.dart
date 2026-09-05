import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:photo_manager/photo_manager.dart';

import '../camera/picker_camera_delegate.dart';
import '../config/asset_picker_config.dart';
import '../source/asset_source.dart';

/// Opens the OS app-settings screen.
typedef PickerSettingsOpener = Future<void> Function();

/// The picker's configuration.
///
/// Overridden at the scope hosting the picker. An unoverridden read throws,
/// deliberately: a missing override is a wiring bug and must fail loudly
/// rather than silently pick a default the host app never asked for
/// (contract §9).
final Provider<AssetPickerConfig> assetPickerConfigProvider =
    Provider<AssetPickerConfig>(
  (Ref ref) => throw StateError(
    'assetPickerConfigProvider must be overridden. Wrap the picker in a '
    'ProviderScope that overrides it, or use KutuAssetPicker.show, which does '
    'that for you.',
  ),
);

/// The gallery seam. Production overrides it with [PhotoManagerAssetSource];
/// tests override it with `FakeAssetSource`.
final Provider<AssetSource> assetSourceProvider = Provider<AssetSource>(
  (Ref ref) => throw StateError(
    'assetSourceProvider must be overridden. Wrap the picker in a '
    'ProviderScope that overrides it, or use KutuAssetPicker.show, which does '
    'that for you.',
  ),
);

/// The native media seam. This is the one with a real default: production
/// always wants the plugin (contract §9).
final Provider<MediaTransform> mediaTransformProvider =
    Provider<MediaTransform>((Ref ref) => const KutuMediaTransform());

/// How the denied state reaches the OS settings screen. Injected so a widget
/// test can assert the button without leaving the test harness.
final Provider<PickerSettingsOpener> pickerSettingsOpenerProvider =
    Provider<PickerSettingsOpener>((Ref ref) => PhotoManager.openSetting);

/// The OS camera delegate, or null when the host app supplies none.
///
/// Null is the default and the camera tile simply does not render, whatever
/// `AssetPickerConfig.enableCamera` says.
final Provider<PickerCameraDelegate?> pickerCameraDelegateProvider =
    Provider<PickerCameraDelegate?>((Ref ref) => null);
