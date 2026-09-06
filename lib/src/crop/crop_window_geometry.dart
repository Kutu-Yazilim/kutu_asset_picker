import 'package:flutter/rendering.dart';
import 'package:kutu_asset_picker/src/config/picker_enums.dart';

/// The crop window, centred in a stage of [size].
Rect cropWindowRect(Size size, Size window) => Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: window.width,
      height: window.height,
    );

/// The stage a viewport lays out in: everything it was given, falling back to
/// the window itself on an axis that has no bound.
///
/// The viewport is stage-sized rather than window-sized so the media shows
/// through the dimming mask beyond the window, and so a drag that starts on
/// that dimmed footage still pans. Both need the whole stage under one gesture
/// surface and one clip.
Size cropStageSize(BoxConstraints constraints, Size window) => Size(
      constraints.hasBoundedWidth ? constraints.maxWidth : window.width,
      constraints.hasBoundedHeight ? constraints.maxHeight : window.height,
    );

/// The hole the dimming mask cuts out of the stage.
///
/// The circle variant is the avatar case. Note that the **exported** rect is
/// still the square that bounds the circle — a JPEG has no alpha to spare, and
/// every consumer of an avatar already clips it round.
Path cropWindowPath(Rect rect, CropOverlayShape shape) => switch (shape) {
      CropOverlayShape.rectangle => Path()..addRect(rect),
      CropOverlayShape.circle => Path()..addOval(rect),
    };
