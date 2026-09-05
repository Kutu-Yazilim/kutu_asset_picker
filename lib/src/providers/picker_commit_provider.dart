import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../source/asset_availability.dart';
import '../source/asset_source.dart';
import '../source/picker_asset.dart';
import 'injection_providers.dart';
import 'selection_provider.dart';
import '../picker/slow_motion_flatten.dart';

part 'picker_commit_provider.g.dart';

/// The pre-flight's progress, per asset and in aggregate.
@immutable
final class PickerCommitState {
  const PickerCommitState({required this.running, required this.byAsset});

  const PickerCommitState.idle()
      : running = false,
        byAsset = const <String, AssetAvailability>{};

  final bool running;

  /// Asset id → where that asset is. Empty when idle.
  final Map<String, AssetAvailability> byAsset;

  /// Ids that could not be materialised.
  List<String> get failed => <String>[
        for (final MapEntry<String, AssetAvailability> entry in byAsset.entries)
          if (entry.value is AssetUnavailable) entry.key,
      ];

  bool get hasFailures =>
      byAsset.values.any((AssetAvailability a) => a is AssetUnavailable);

  /// Mean progress across the batch, 0..1. A resolved asset counts as 1
  /// whichever way it resolved, so the bar advances rather than stalling on a
  /// failure the user has already been told about.
  double get progress {
    if (byAsset.isEmpty) {
      return 0;
    }
    double total = 0;
    for (final AssetAvailability availability in byAsset.values) {
      total += switch (availability) {
        AssetReady() => 1,
        AssetUnavailable() => 1,
        AssetDownloading(:final double progress) => progress,
      };
    }
    return total / byAsset.length;
  }

  PickerCommitState copyWith({
    bool? running,
    Map<String, AssetAvailability>? byAsset,
  }) =>
      PickerCommitState(
        running: running ?? this.running,
        byAsset: byAsset ?? this.byAsset,
      );
}

/// The iCloud pre-flight that runs before the selection leaves the grid.
///
/// design §4.5: with Optimize Storage on, a thumbnail renders perfectly from a
/// local derivative while the asset itself lives only in iCloud. The grid looks
/// complete and the failure surfaces at *Next*. This moves the discovery
/// earlier, reports it per asset, and makes it cancellable.
///
/// The downloads run **concurrently on purpose**. design §7.5's
/// strictly-sequential rule governs the export queue, which is CPU-bound
/// decoding that competes for the same memory; these are network waits, and
/// "one slow asset never blocks the rest of a multi-select" is unreachable
/// serially.
@Riverpod(keepAlive: true)
class PickerCommit extends _$PickerCommit {
  TransformCancelToken? _token;
  VoidCallback? _onReady;

  @override
  PickerCommitState build() => const PickerCommitState.idle();

  /// Runs the pre-flight over the current selection and calls [onReady] once
  /// every selected asset is on the device.
  ///
  /// A callback rather than a return value because the caller is a button, and
  /// a button that `await`s breaks Flutter rule 9.
  Future<void> commit({required VoidCallback onReady}) async {
    if (state.running) {
      return;
    }
    final List<PickerAsset> selected =
        ref.read(selectionProvider.notifier).selectedAssets;
    if (selected.isEmpty) {
      return;
    }

    _onReady = onReady;
    final AssetSource source = ref.read(assetSourceProvider);
    final TransformCancelToken token = TransformCancelToken();
    _token = token;

    state = PickerCommitState(
      running: true,
      byAsset: <String, AssetAvailability>{
        for (final PickerAsset asset in selected)
          asset.id: const AssetDownloading(0),
      },
    );

    final List<bool> outcomes = await Future.wait<bool>(
      selected.map(
        (PickerAsset asset) => _materialise(source, asset, token),
      ),
    );

    _token = null;
    if (token.isCancelled) {
      return;
    }
    state = state.copyWith(running: false);
    if (outcomes.contains(false)) {
      return;
    }
    // spec §7.3 — an iOS slow-motion clip's file can play for a quarter of the
    // duration Photos showed, and flattening it is a multi-second transcode
    // that "cannot happen silently behind *Next*". It runs here, after the
    // pre-flight that materialised the files it needs and before the hand-over
    // that would otherwise pass a wrong timeline to the crop step.
    if (await ref.read(slowMotionFlattenProvider.notifier).run()) {
      onReady();
    }
  }

  /// Re-runs the pre-flight with the same hand-over callback.
  Future<void> retry() async {
    final VoidCallback? onReady = _onReady;
    if (onReady == null) {
      return;
    }
    await commit(onReady: onReady);
  }

  /// Abandons the in-flight downloads and clears the bar.
  void cancel() {
    _token?.cancel();
    _token = null;
    ref.read(slowMotionFlattenProvider.notifier).cancel();
    state = const PickerCommitState.idle();
  }

  Future<bool> _materialise(
    AssetSource source,
    PickerAsset asset,
    TransformCancelToken token,
  ) async {
    try {
      if (await source.isLocallyAvailable(asset.id)) {
        _mark(asset.id, const AssetReady());
        return true;
      }
      final File? file = await source.file(
        asset.id,
        onProgress: (double progress) =>
            _mark(asset.id, AssetDownloading(progress)),
        cancelToken: token,
      );
      if (file == null) {
        _mark(asset.id, const AssetUnavailable());
        return false;
      }
      _mark(asset.id, const AssetReady());
      return true;
    } on Object {
      // One unreadable asset in a library of thousands is normal. It is a
      // per-asset error the user can retry, never a reason to throw away the
      // rest of their selection (design §4.5).
      _mark(asset.id, const AssetUnavailable());
      return false;
    }
  }

  void _mark(String id, AssetAvailability availability) {
    // A download that completes after cancel() must not resurrect the batch.
    if (!state.running) {
      return;
    }
    state = state.copyWith(
      byAsset: <String, AssetAvailability>{...state.byAsset, id: availability},
    );
  }
}
