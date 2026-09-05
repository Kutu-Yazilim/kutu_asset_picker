import 'dart:ui';

import 'package:kutu_media_transform/kutu_media_transform.dart';

/// The size the author actually sees, and therefore the size every
/// `crop_math` call must be given for a video.
///
/// Spec §7.4 invariant 1: iOS stores a `preferredTransform` and Android a
/// rotation-degrees tag, and `video_player` applies it for display. Computing
/// the crop against the *coded* frame is what makes portrait videos crop
/// sideways, so the coded size never leaves [VideoInfo].
Size videoDisplaySize(VideoInfo info) =>
    Size(info.displayWidth.toDouble(), info.displayHeight.toDouble());

/// Whether the rotation-corrected size from [VideoInfo] matches the size
/// `video_player` reports once initialised.
///
/// They can differ by a pixel when SAR/PAR is not 1 (spec §7.4 invariant 3).
/// More than that means the two sides disagree about rotation, which is the
/// bug this exists to make visible rather than silent.
bool videoSizesAgree(Size fromInfo, Size fromPlayer) =>
    (fromInfo.width - fromPlayer.width).abs() <= 1 &&
    (fromInfo.height - fromPlayer.height).abs() <= 1;
