import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:kutu_asset_picker/src/config/crop_aspect.dart';
import 'package:kutu_asset_picker/src/crop/crop_state.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

/// The reference frame every [CropState] is expressed in.
///
/// `scale` and `offset` are logical pixels — but *whose* logical pixels? If
/// they were the device's, the same framing would mean different things on a
/// phone and a tablet, would break on rotation, and the export path would have
/// to be told the layout size to reconstruct a [CropRect]. Storing against a
/// fixed square area removes all three problems: the crop rect a state produces
/// is identical everywhere, and `CropViewport` is the only code that ever
/// converts, through [rescaleCropState].
///
/// Square on purpose, so no aspect ratio in the menu is privileged over
/// another. 1000 is large enough that double precision is irrelevant.
const Size kCanonicalCropArea = Size(1000, 1000);

/// Smallest scale at which [image] fully covers [window] — rule 1 of spec §6.2.
///
/// Returns 1 for any degenerate input. A 0, NaN or infinite scale would
/// propagate into every division downstream and surface as an invisible image
/// rather than as an error.
double scaleToCover(Size image, Size window) {
  if (!(image.width > 0) || !(image.height > 0)) return 1;
  final scale =
      math.max(window.width / image.width, window.height / image.height);
  return scale.isFinite && scale > 0 ? scale : 1;
}

/// Clamps [offset] so no image edge ever enters [window] — rule 2 of spec §6.2.
///
/// The image is drawn at `image * scale`, centred on the window centre and then
/// translated by [offset]. It covers the window exactly while
/// `|offset| <= (scaled - window) / 2` on each axis. When the image is smaller
/// than the window on an axis there is no legal pan at all, and centring is the
/// only offset that does not open a gap — so the slack floors at zero rather
/// than going negative.
Offset clampOffset(Offset offset, double scale, Size image, Size window) {
  final slackX = math.max(0.0, (image.width * scale - window.width) / 2);
  final slackY = math.max(0.0, (image.height * scale - window.height) / 2);
  return Offset(
    offset.dx.clamp(-slackX, slackX),
    offset.dy.clamp(-slackY, slackY),
  );
}

/// The crop window for [aspect] inside [available], letterboxed to fit.
Size cropWindowSize(CropAspect aspect, Size available) {
  if (!(available.width > 0) || !(available.height > 0)) return Size.zero;
  final byWidth = Size(available.width, available.width / aspect.ratio);
  return byWidth.height <= available.height
      ? byWidth
      : Size(available.height * aspect.ratio, available.height);
}

/// The visible region as the canonical normalized rect: 0..1, origin top-left,
/// y-down (contract §1). Platform conversions happen only at the plugin edge.
///
/// Clamps into 0..1 defensively. A caller that has already run
/// [reclampForAspect] never needs the clamp; one that has not gets a legal rect
/// instead of a plugin-side crash.
CropRect toCropRect(CropState state, Size image, Size window) {
  final scaledWidth = image.width * state.scale;
  final scaledHeight = image.height * state.scale;
  if (!(scaledWidth > 0) || !(scaledHeight > 0)) return const CropRect.full();

  final x = (scaledWidth - window.width) / 2 - state.offset.dx;
  final y = (scaledHeight - window.height) / 2 - state.offset.dy;

  return CropRect(
    left: (x / scaledWidth).clamp(0.0, 1.0),
    top: (y / scaledHeight).clamp(0.0, 1.0),
    right: ((x + window.width) / scaledWidth).clamp(0.0, 1.0),
    bottom: ((y + window.height) / scaledHeight).clamp(0.0, 1.0),
  );
}

/// Rule 3 of spec §6.2, in its load-bearing order: recompute `minScale` for the
/// NEW window, raise `scale` to it if needed, and only THEN re-clamp the
/// translation.
///
/// That ordering is the whole reason switching 1:1 → 16:9 after zooming in can
/// never reveal a gap. Clamping first would clamp against a scale that is about
/// to change.
///
/// [window] must be the window for [next] — i.e. `cropWindowSize(next, …)`.
/// Passing the outgoing window silently produces a state that is legal for a
/// shape nobody is showing.
///
/// Also the normalizer for a fresh [CropState.unsized]: its scale of 0 is below
/// every cover scale, so it is raised to exactly `scaleToCover` and its zero
/// offset is already centred.
CropState reclampForAspect(
  CropState state,
  Size image,
  Size window,
  CropAspect next,
) {
  final scale = math.max(state.scale, scaleToCover(image, window));
  return state.copyWith(
    aspect: next,
    scale: scale,
    offset: clampOffset(state.offset, scale, image, window),
  );
}

/// The offset that keeps the image point under [startFocal] under [focal] while
/// the scale goes from [startScale] to [nextScale].
///
/// Without this a pinch zooms about the window centre, so the detail the author
/// is pinching towards slides away from their fingers.
///
/// A [startScale] of 0 (an unsized state that somehow reached a gesture)
/// degrades to a pure pan rather than dividing by zero.
Offset focalAnchoredOffset({
  required Offset startFocal,
  required Offset focal,
  required Offset startOffset,
  required double startScale,
  required double nextScale,
  required Size window,
}) {
  final centre = Offset(window.width / 2, window.height / 2);
  if (!(startScale > 0)) return startOffset + (focal - startFocal);
  final imageVector = startFocal - centre - startOffset;
  return focal - centre - imageVector * (nextScale / startScale);
}

/// Rebases [state] from a crop window of [from] to one of [to].
///
/// Both windows must have the same aspect ratio, which is guaranteed because
/// both are `cropWindowSize(state.aspect, …)`. [toCropRect] is invariant under
/// a uniform scaling of window, scale and offset together, so the framing comes
/// through exactly — that invariance is what lets the export path work in
/// [kCanonicalCropArea] while the viewport works in layout pixels.
CropState rescaleCropState(
  CropState state, {
  required Size from,
  required Size to,
}) {
  if (!(from.width > 0) || !(to.width > 0)) return state;
  final factor = to.width / from.width;
  return state.copyWith(
    scale: state.scale * factor,
    offset: state.offset * factor,
  );
}

/// The paint-time matrix for [state]: `p' = scale * p + offset`.
///
/// Built with [Matrix4.setEntry] rather than `translate`/`scale` so it does not
/// ride any of vector_math's deprecation churn, and derived here and nowhere
/// else — the state stays value-comparable (contract §6).
Matrix4 cropMatrix(CropState state) => Matrix4.identity()
  ..setEntry(0, 0, state.scale)
  ..setEntry(1, 1, state.scale)
  ..setEntry(0, 3, state.offset.dx)
  ..setEntry(1, 3, state.offset.dy);
