// ignore_for_file: avoid_manual_providers_as_generated_provider_dependency

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../crop/video/video_rejection.dart';
import '../providers/injection_providers.dart';
import '../providers/selection_provider.dart';
import '../source/picker_asset.dart';
import 'video_selection_guard.dart';

part 'selection_attempt.g.dart';

/// The guarded front door to selection.
///
/// Every cell tap goes through here rather than straight to `Selection`, so a
/// refusal happens where the author is looking — in the grid, on tap — instead
/// of surfacing minutes later at upload (spec §10).
///
/// State is the last rejection, or null.
// keepAlive (contract §9): a banner that vanished because its notifier was
// collected between the tap and the next frame would be a flaky banner.
@Riverpod(keepAlive: true)
class SelectionAttempt extends _$SelectionAttempt {
  @override
  VideoRejection? build() => null;

  /// Toggle.
  void toggle(PickerAsset asset) {
    // Deselecting is never guarded: an asset already in the selection must
    // always be removable, whatever the config says about it now.
    if (ref.read(selectionProvider).contains(asset.id)) {
      state = null;
      // toggleAsset, not toggle(id): the registry behind selectedAssets is what
      // lets a Camera pick survive a switch to Screenshots (slice 3, Task 14).
      ref.read(selectionProvider.notifier).toggleAsset(asset);
      return;
    }
    final rejection =
        videoSelectionRejection(asset, ref.read(assetPickerConfigProvider));
    state = rejection;
    if (rejection != null) return;
    // toggleAsset, not toggle(id): the registry behind selectedAssets is what
    // lets a Camera pick survive a switch to Screenshots (slice 3, Task 14).
    ref.read(selectionProvider.notifier).toggleAsset(asset);
  }

  /// Dismiss.
  void dismiss() => state = null;
}
