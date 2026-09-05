import '../config/asset_picker_config.dart';
import '../crop/video/video_rejection.dart';
import '../source/picker_asset.dart';
import '../source/picker_media_type.dart';

/// Whether this asset may be selected at all.
///
/// Runs on tap, with no I/O: the only thing knowable for free is the duration
/// the gallery already reported. A null duration passes — Android returns one
/// for a real set of files, and refusing those would make videos disappear
/// from the grid rather than merely be un-selectable (spec §4.5).
VideoRejection? videoSelectionRejection(
  PickerAsset asset,
  AssetPickerConfig config,
) {
  if (asset.type != PickerMediaType.video) return null;
  final max = config.maxVideoDuration;
  final duration = asset.duration;
  if (max == null || duration == null || duration <= max) return null;
  return VideoRejection.tooLong(max);
}
