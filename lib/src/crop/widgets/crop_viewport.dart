import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_durations.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_limits.dart';
import 'package:kutu_asset_picker/src/crop/crop_math.dart';
import 'package:kutu_asset_picker/src/crop/crop_providers.dart';
import 'package:kutu_asset_picker/src/crop/crop_state.dart';
import 'package:kutu_asset_picker/src/crop/fling_duration.dart';
import 'package:kutu_asset_picker/src/providers/injection_providers.dart';

/// The framing surface: a fixed crop window with the media transformed under
/// it (spec §6.2).
///
/// **`InteractiveViewer` is deliberately not used.** Its only constraint is
/// child-versus-*viewport*: it has no concept of "the child must cover this
/// inner rectangle", which is exactly the invariant a crop window needs, and it
/// has documented stuck-pinch behaviour when used without `boundaryMargin`
/// (flutter/flutter#111186). A `GestureDetector`'s scale gestures already
/// subsume pan and pinch — one recognizer drives both — and every clamp is a
/// pure function from `crop_math.dart`, which is what makes the framing
/// testable without a device.
///
/// [child] is the media surface. A photo passes `CropAssetImage`; slice 5
/// passes the video player, and the identical `ClipRect` + `Transform` stack
/// sits over it, so both media types get one interaction model (spec §6.3).
class CropViewport extends HookConsumerWidget {
  /// Creates a [CropViewport].
  const CropViewport({
    required this.assetId,
    required this.imageSize,
    required this.window,
    required this.child,
    super.key,
  });

  /// The asset id.
  final String assetId;

  /// The media's own pixel size, already display-oriented.
  final Size imageSize;

  /// The crop window, in layout logical pixels.
  final Size window;

  /// The child.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stored =
        ref.watch(cropStatesProvider.select((states) => states[assetId])) ??
            CropState.unsized(
              ref.watch(assetPickerConfigProvider).effectiveInitialAspect,
            );

    // Stored state is in the canonical frame; gestures happen in layout pixels.
    // This widget is the only place that converts, in both directions.
    final canonicalWindow = cropWindowSize(stored.aspect, kCanonicalCropArea);
    final state = reclampForAspect(
      rescaleCropState(stored, from: canonicalWindow, to: window),
      imageSize,
      window,
      stored.aspect,
    );

    final startScale = useRef(0.0);
    final startOffset = useRef(Offset.zero);
    final startFocal = useRef(Offset.zero);
    final flingBase = useRef(state);
    final flingFrom = useRef(Offset.zero);
    final flingTo = useRef(Offset.zero);
    final controller = useAnimationController();

    // Reused by three callbacks, so Flutter rule 1 is satisfied.
    void commit(CropState next) => ref.read(cropStatesProvider.notifier).update(
          assetId,
          rescaleCropState(next, from: window, to: canonicalWindow),
        );

    useEffect(
      () {
        void onTick() {
          final base = flingBase.value;
          commit(
            base.copyWith(
              offset: clampOffset(
                Offset.lerp(flingFrom.value, flingTo.value, controller.value)!,
                base.scale,
                imageSize,
                window,
              ),
            ),
          );
        }

        controller.addListener(onTick);
        return () => controller.removeListener(onTick);
      },
      [controller, assetId, window, imageSize],
    );

    return ClipRect(
      child: SizedBox.fromSize(
        size: window,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onScaleStart: (details) {
            controller.stop();
            ref.read(cropInteractionProvider.notifier).begin();
            startScale.value = state.scale;
            startOffset.value = state.offset;
            startFocal.value = details.localFocalPoint;
          },
          onScaleUpdate: (details) {
            final minScale = scaleToCover(imageSize, window);
            final nextScale = (startScale.value * details.scale).clamp(
              minScale,
              minScale * AssetPickerLimits.maxZoomFactor,
            );
            commit(
              state.copyWith(
                scale: nextScale,
                offset: clampOffset(
                  focalAnchoredOffset(
                    startFocal: startFocal.value,
                    focal: details.localFocalPoint,
                    startOffset: startOffset.value,
                    startScale: startScale.value,
                    nextScale: nextScale,
                    window: window,
                  ),
                  nextScale,
                  imageSize,
                  window,
                ),
              ),
            );
          },
          onScaleEnd: (details) {
            ref.read(cropInteractionProvider.notifier).end();
            final velocity = details.velocity.pixelsPerSecond;
            if (velocity.distance < AssetPickerLimits.minFlingVelocity) return;
            final seconds = flingDuration(velocity.distance);
            if (seconds <= 0) return;

            // A clamped ballistic run: the simulation proposes a destination,
            // and every frame is pushed back through `clampOffset`, so the
            // image decelerates naturally and still cannot leave a gap.
            flingBase.value = state;
            flingFrom.value = state.offset;
            flingTo.value = Offset(
              FrictionSimulation(
                AssetPickerLimits.flingDrag,
                state.offset.dx,
                velocity.dx,
              ).finalX,
              FrictionSimulation(
                AssetPickerLimits.flingDrag,
                state.offset.dy,
                velocity.dy,
              ).finalX,
            );
            controller.duration = seconds.isFinite
                ? Duration(milliseconds: (seconds * 1000).round())
                : AssetPickerDurations.flingFallback;
            controller.forward(from: 0);
          },
          child: Transform(
            transform: cropMatrix(state),
            alignment: Alignment.center,
            child: OverflowBox(
              minWidth: 0,
              maxWidth: double.infinity,
              minHeight: 0,
              maxHeight: double.infinity,
              child: SizedBox(
                width: imageSize.width,
                height: imageSize.height,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
