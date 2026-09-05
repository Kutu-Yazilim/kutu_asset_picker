// ignore_for_file: avoid_manual_providers_as_generated_provider_dependency

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../providers/injection_providers.dart';
import '../providers/selection_provider.dart';
import '../source/asset_source.dart';
import '../source/picker_asset.dart';
import '../source/picker_media_type.dart';
import 'flattened_asset_source.dart';
import 'slow_motion_flatten_step.dart';

part 'slow_motion_flatten.g.dart';

/// How far the flatten pass has got, and what it rewrote.
@immutable
final class SlowMotionFlattenState {
  const SlowMotionFlattenState({
    required this.running,
    required this.done,
    required this.total,
    required this.fraction,
    required this.files,
  });

  const SlowMotionFlattenState.idle()
      : running = false,
        done = 0,
        total = 0,
        fraction = 0,
        files = const <String, File>{};

  final bool running;

  /// Clips finished, and clips this pass set out to flatten.
  final int done, total;

  /// How far through the clip currently transcoding, 0..1.
  final double fraction;

  /// Asset id → the rewritten file. Outlives the pass on purpose: the crop
  /// step and the export queue both read it long after the bar is gone.
  final Map<String, File> files;

  /// One bar across the whole batch. A per-clip bar that restarted at zero
  /// three times would read as three stalls.
  double get progress => total == 0 ? 0 : (done + fraction) / total;

  SlowMotionFlattenState copyWith({
    bool? running,
    int? done,
    int? total,
    double? fraction,
    Map<String, File>? files,
  }) =>
      SlowMotionFlattenState(
        running: running ?? this.running,
        done: done ?? this.done,
        total: total ?? this.total,
        fraction: fraction ?? this.fraction,
        files: files ?? this.files,
      );
}

/// Flattens every selected slow-motion clip before the selection leaves the
/// grid (spec §7.3).
///
/// Sequential, unlike the iCloud pre-flight beside it: these are encoder jobs
/// competing for the same hardware, not network waits, so overlapping them
/// buys nothing and costs memory (spec §7.5's reasoning, same hardware).
@Riverpod(keepAlive: true)
class SlowMotionFlatten extends _$SlowMotionFlatten {
  TransformCancelToken? _token;

  @override
  SlowMotionFlattenState build() => const SlowMotionFlattenState.idle();

  /// Returns true when every selected clip now has a trustworthy timeline —
  /// which is the only condition under which the caller may hand the selection
  /// over. False means cancelled, unreadable, or a failed transcode.
  Future<bool> run() async {
    if (state.running) {
      return false;
    }
    final pending = <PickerAsset>[
      for (final asset in ref.read(selectionProvider.notifier).selectedAssets)
        if (asset.type == PickerMediaType.video &&
            asset.duration != null &&
            !state.files.containsKey(asset.id))
          asset,
    ];
    if (pending.isEmpty) {
      return true;
    }

    final source = ref.read(assetSourceProvider);
    final step = SlowMotionFlattenStep(
      transform: ref.read(mediaTransformProvider),
    );
    final settings = ref.read(assetPickerConfigProvider).videoEncode;
    final token = _token = TransformCancelToken();
    state = SlowMotionFlattenState(
      running: true,
      done: 0,
      total: pending.length,
      fraction: 0,
      files: state.files,
    );

    for (final asset in pending) {
      if (token.isCancelled) {
        _finish();
        return false;
      }
      try {
        final file = await source.file(asset.id, cancelToken: token);
        if (file == null) {
          _finish();
          return false;
        }
        final flattened = await step.flatten(
          asset: asset,
          source: file,
          settings: settings,
          onProgress: _report,
          cancelToken: token,
        );
        if (flattened != null) {
          state = state.copyWith(
            files: <String, File>{...state.files, asset.id: flattened},
          );
        }
      } on Object {
        // A cancel arrives here as a cancelled TransformException, and a dead
        // encoder as any other. Either way the selection must not go forward
        // with a clip whose timeline is a quarter of what the author saw.
        _finish();
        return false;
      }
      state = state.copyWith(done: state.done + 1, fraction: 0);
    }

    _finish();
    return !token.isCancelled;
  }

  /// Abandons the transcode in flight and hides the bar. Files already
  /// rewritten stay — they are valid, and re-running would redo them.
  void cancel() {
    _token?.cancel();
    _token = null;
    state = state.copyWith(running: false, done: 0, total: 0, fraction: 0);
  }

  void _report(double fraction) {
    if (!state.running) {
      return;
    }
    state = state.copyWith(fraction: fraction.clamp(0.0, 1.0));
  }

  void _finish() {
    _token = null;
    state = state.copyWith(running: false, fraction: 0);
  }
}

/// The source every consumer of a *selected* asset's file must read.
///
/// `assetSourceProvider` is still the gallery and is still what the grid and
/// the pass itself use; this is the gallery with the flatten pass's rewrites
/// laid over it. Reading the wrong one is how a trim range chosen against a
/// 12-second timeline ends up applied to a 3-second file.
@Riverpod(keepAlive: true)
AssetSource flattenedAssetSource(Ref ref) => FlattenedAssetSource(
      delegate: ref.watch(assetSourceProvider),
      flattened: ref.watch(
        slowMotionFlattenProvider.select((state) => state.files),
      ),
    );
