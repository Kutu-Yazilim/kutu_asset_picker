import 'asset_picker_text.dart';

/// English strings — the package default.
base class AssetPickerTextEn extends AssetPickerText {
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
}
