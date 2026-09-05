import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../source/picker_permission.dart';
import 'injection_providers.dart';

part 'permission_provider.g.dart';

/// The library-access state the whole picker branches on.
///
/// Requested once per scope and cached; [PermissionActions] is what
/// invalidates it.
@Riverpod(keepAlive: true)
Future<PickerPermission> assetPickerPermission(Ref ref) {
  final config = ref.watch(assetPickerConfigProvider);
  return ref.watch(assetSourceProvider).requestPermission(config.mediaTypes);
}

/// The side effects that can change [assetPickerPermissionProvider].
///
/// Separate from the provider itself because the contract declares that one as
/// a function, and because keeping `await` out of widgets (Flutter rule 9)
/// needs somewhere for these to live.
@Riverpod(keepAlive: true)
class PermissionActions extends _$PermissionActions {
  @override
  void build() {}

  /// Sends the user to the OS settings screen and re-checks on return.
  ///
  /// Returning from Settings is the only moment a denied user can become a
  /// granted one without restarting the app, so the re-check must be a fresh
  /// request rather than a replay of the cached answer.
  Future<void> openSettings() async {
    await ref.read(pickerSettingsOpenerProvider)();
    recheck();
  }

  /// Re-requests permission. Also the resume hook: the user may have changed
  /// the grant in Settings and come back.
  void recheck() => ref.invalidate(assetPickerPermissionProvider);
}
