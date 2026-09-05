import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../providers/injection_providers.dart';
import 'video_bar_visibility.dart';

part 'scrubber_mode.g.dart';

/// What the scrubber's handles mean right now.
///
/// The cover picker is a second *mode* on the same filmstrip rather than a
/// second strip: identical frames, identical geometry, identical seek path
/// (spec §6.3).
enum ScrubberMode { trim, cover }

// keepAlive (contract §9): the mode the author chose must not reset when
// the bar fades out and back during a drag.
@Riverpod(keepAlive: true)
class ScrubberModeController extends _$ScrubberModeController {
  @override
  ScrubberMode build() =>
      initialScrubberMode(ref.watch(assetPickerConfigProvider));

  void select(ScrubberMode mode) => state = mode;
}
