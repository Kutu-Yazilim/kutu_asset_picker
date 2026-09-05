import '../../config/asset_picker_config.dart';
import 'scrubber_mode.dart';

/// Whether the floating bar has anything to show at all.
bool showsFloatingVideoBar(AssetPickerConfig config) =>
    config.enableTrim || config.enableCoverFrame;

/// The trim/cover toggle only earns its space when both modes exist.
bool showsScrubberModeToggle(AssetPickerConfig config) =>
    config.enableTrim && config.enableCoverFrame;

ScrubberMode initialScrubberMode(AssetPickerConfig config) =>
    config.enableTrim ? ScrubberMode.trim : ScrubberMode.cover;
