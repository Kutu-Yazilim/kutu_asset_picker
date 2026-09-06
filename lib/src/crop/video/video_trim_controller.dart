// The picker's three injection points (contract §9) are hand-written providers
// on purpose — an unoverridden read must throw — so a generated notifier
// depending on them is expected here, not a smell.
// ignore_for_file: avoid_manual_providers_as_generated_provider_dependency

import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../providers/injection_providers.dart';
import '../crop_providers.dart';
import 'trim_math.dart';
import 'video_seek_providers.dart';

part 'video_trim_controller.g.dart';

/// The kept range and the poster instant, for one video.
typedef VideoTrimState = ({DurationRange trim, Duration coverAt});

/// Owns the trim handles and the cover cursor for one asset.
///
/// The authoritative store is still `CropStates` (spec §6.1) — every change is
/// written through, so tabbing to another asset and back finds the trim exactly
/// where it was left. This notifier is the working copy plus the clamp rules
/// plus the seek that shows the author what the handle is pointing at.
// keepAlive (contract §9): the trim the author set must survive a rebuild
// of the only widget watching it — the bar fades out mid-drag on purpose.
@Riverpod(keepAlive: true)
class VideoTrimController extends _$VideoTrimController {
  @override
  VideoTrimState build(String assetId, Duration total) {
    final stored = ref.read(cropStatesProvider.notifier).stateOf(assetId);
    final trim = stored.trim ??
        initialTrim(
            total, ref.watch(assetPickerConfigProvider).maxVideoDuration);
    return (
      trim: trim,
      coverAt: clampCoverAt(stored.coverAt ?? trim.start, trim)
    );
  }

  /// Move the in point by [deltaFraction] of the whole clip.
  void nudgeStart(double deltaFraction) {
    final next = trimWithStart(
      state.trim,
      state.trim.start + _delta(deltaFraction),
      total,
      _maxDuration,
    );
    _commit(next, clampCoverAt(state.coverAt, next));
    _seek(next.start);
  }

  /// Move the out point by [deltaFraction] of the whole clip.
  void nudgeEnd(double deltaFraction) {
    final next = trimWithEnd(
      state.trim,
      state.trim.end + _delta(deltaFraction),
      total,
      _maxDuration,
    );
    _commit(next, clampCoverAt(state.coverAt, next));
    _seek(next.end);
  }

  /// Carry the whole kept range by [deltaFraction] of the clip.
  ///
  /// One drag of the zone instead of one per handle, for the author who kept
  /// 0:10–0:20 and now wants 0:30–0:40. The cover frame is a spot inside that
  /// zone, so it travels by the same amount and lands where it was relative
  /// to the new range; the picture follows the in point being placed.
  void nudgeRange(double deltaFraction) {
    final next = trimShifted(state.trim, _delta(deltaFraction), total);
    final carried = next.start - state.trim.start;
    _commit(next, clampCoverAt(state.coverAt + carried, next));
    _seek(next.start);
  }

  /// Move the cover cursor by [deltaFraction] of the whole clip.
  void nudgeCover(double deltaFraction) =>
      setCover(state.coverAt + _delta(deltaFraction));

  /// Set cover.
  void setCover(Duration at) {
    final next = clampCoverAt(at, state.trim);
    _commit(state.trim, next);
    _seek(next);
  }

  /// The finger came off a handle: land on the exact frame now instead of
  /// waiting out the coalescer's floor.
  void endDrag() => ref.read(videoSeekCoalescerProvider(assetId)).flush();

  Duration? get _maxDuration =>
      ref.read(assetPickerConfigProvider).maxVideoDuration;

  Duration _delta(double fraction) =>
      Duration(microseconds: (total.inMicroseconds * fraction).round());

  void _seek(Duration position) =>
      ref.read(videoSeekCoalescerProvider(assetId)).request(position);

  void _commit(DurationRange trim, Duration coverAt) {
    state = (trim: trim, coverAt: coverAt);
    final states = ref.read(cropStatesProvider.notifier);
    states.update(
      assetId,
      states.stateOf(assetId).copyWith(trim: trim, coverAt: coverAt),
    );
  }
}
