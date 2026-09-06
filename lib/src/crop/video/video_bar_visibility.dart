import '../../config/asset_picker_config.dart';
import '../../source/picker_asset.dart';
import '../../source/picker_media_type.dart';
import 'scrubber_mode.dart';

/// Whether the video control bar has anything to show at all.
bool showsVideoBar(AssetPickerConfig config) =>
    config.enableTrim || config.enableCoverFrame;

/// Whether the crop step reserves a band under the crop window for the bar.
///
/// Decided from the whole [selection], not from the focused asset: the band is
/// the same for every asset in the session — empty under a photo — so the crop
/// window does not change size as the author tabs between a photo and a video
/// (spec §2.7). A photo-only session gives the window that height back.
bool reservesVideoBarBand(
  AssetPickerConfig config,
  List<PickerAsset> selection,
) =>
    showsVideoBar(config) &&
    selection.any((asset) => asset.type == PickerMediaType.video);

/// The trim/cover toggle only earns its space when both modes exist.
bool showsScrubberModeToggle(AssetPickerConfig config) =>
    config.enableTrim && config.enableCoverFrame;

/// Initial scrubber mode.
ScrubberMode initialScrubberMode(AssetPickerConfig config) =>
    config.enableTrim ? ScrubberMode.trim : ScrubberMode.cover;
