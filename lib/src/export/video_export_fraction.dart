import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'video_export_fraction.g.dart';

/// How far through the video currently exporting.
///
/// Separate from `ExportProgress`, which counts assets: a photo export is
/// milliseconds and a done/total counter describes it fine, while a video
/// export is seconds to minutes and needs a bar that actually moves.
@Riverpod(keepAlive: true)
class VideoExportFraction extends _$VideoExportFraction {
  @override
  double build() => 0;

  void report(double fraction) => state = fraction.clamp(0.0, 1.0);

  void reset() => state = 0;
}
