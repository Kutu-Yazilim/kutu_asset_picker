import '../config/picker_enums.dart';
import '../picker/duration_format.dart';
import 'asset_picker_text.dart';

/// English strings — the package default.
base class AssetPickerTextEn extends AssetPickerText {
  /// Creates a [AssetPickerTextEn].
  const AssetPickerTextEn();

  @override
  String get pickerTitle => 'Select media';
  @override
  String get pickerNext => 'Next';
  @override
  String get pickerCancel => 'Cancel';
  @override
  String get pickerDone => 'Done';

  @override
  String get pickerAlbumAll => 'Recent';
  @override
  String get pickerAlbumSwitch => 'Switch album';

  @override
  String get pickerCameraTile => 'Camera';

  @override
  String get pickerRemove => 'Remove';

  @override
  String get pickerPermissionDeniedTitle => 'Photo access is off';
  @override
  String get pickerPermissionDeniedBody =>
      'Turn on photo access in Settings to choose photos and videos.';
  @override
  String get pickerOpenSettings => 'Open settings';

  @override
  String get pickerLimitedBanner => 'You granted access to some items only.';
  @override
  String get pickerManageSelection => 'Manage selection';

  @override
  String get pickerEmptyLimited =>
      'Nothing here yet. Change which items this app can see, and the ones you '
      'have selected will appear.';

  @override
  String get pickerEmptyLibrary => 'No photos or videos on this device yet.';

  @override
  String get pickerDownloadingFromCloud => 'Downloading from iCloud';
  @override
  String get pickerDownloadFailed => 'Could not download this item';
  @override
  String get pickerRetry => 'Retry';

  @override
  String selectedCount(int count) => '$count selected';

  @override
  String limitReached(int max) =>
      'You can select up to $max ${max == 1 ? 'item' : 'items'}';

  @override
  String videoTooLong(Duration max) =>
      'Videos must be ${max.inSeconds} seconds or shorter';

  @override
  String fileTooLarge(int maxBytes) =>
      'Files must be ${maxBytes ~/ (1024 * 1024)} MB or smaller';

  @override
  String get cropTitle => 'Crop';
  @override
  String get cropApplyToAll => 'Apply to all';
  @override
  String get cropReorderHint => 'Drag to reorder';
  @override
  String get cropTrim => 'Trim';
  @override
  String get cropCoverFrame => 'Cover';
  @override
  String get cropPlay => 'Play';
  @override
  String get cropPause => 'Pause';
  @override
  String get cropKeptRange => 'Kept range';

  @override
  String get exportFailed => 'Export failed';
  @override
  String get exportCancel => 'Cancel';

  @override
  String aspectLabel(CropAspectLabel label) => switch (label) {
        CropAspectLabel.square => '1:1',
        CropAspectLabel.portrait => '4:5',
        CropAspectLabel.landscape => '16:9',
        CropAspectLabel.story => '9:16',
        CropAspectLabel.banner => '3:1',
        CropAspectLabel.custom => 'Custom',
      };

  @override
  String durationRange(Duration start, Duration end) =>
      '${formatPickerDuration(start)} – ${formatPickerDuration(end)}';

  @override
  String exportProgress(int done, int total) => '$done of $total';
}
