import 'package:flutter/painting.dart';
import 'package:kutu_asset_picker/src/config/picker_enums.dart';

/// The crop window, centred in a stage of [size].
Rect cropWindowRect(Size size, Size window) => Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: window.width,
      height: window.height,
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
