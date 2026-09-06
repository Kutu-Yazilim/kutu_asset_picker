import '../config/picker_enums.dart';

/// Every string the picker renders.
///
/// A concrete base class with per-locale subclasses, rather than
/// package-scoped `gen-l10n` (design §8.2): gen-l10n throws at runtime if the
/// consumer forgets to register the delegate, makes single-string overrides
/// awkward, requires forking the package to add a locale, and would need its
/// generated output committed because a consuming app's build does not run
/// `gen-l10n` for its dependencies.
///
/// The base is **English**, deliberately. `wechat_assets_picker`'s base
/// delegate is Chinese and silently wins whenever no `Locale` is in the widget
/// tree; English is the neutral default for a published package.
///
/// Slice 4 adds the crop and export members —`cropTitle`, `cropApplyToAll`,
/// `cropReorderHint`, `cropTrim`, `cropCoverFrame`, `exportFailed`,
/// `exportCancel`, `aspectLabel`, `durationRange`, `exportProgress` — plus
/// `AssetPickerTextTr` and `assetPickerTextFromLocale`.
abstract base class AssetPickerText {
  /// Creates a [AssetPickerText].
  const AssetPickerText();

  /// The picker title.
  String get pickerTitle;

  /// The picker next.
  String get pickerNext;

  /// The picker cancel.
  String get pickerCancel;

  /// The picker done.
  String get pickerDone;

  /// The picker album all.
  String get pickerAlbumAll;

  /// The picker album switch.
  String get pickerAlbumSwitch;

  /// The picker camera tile.
  String get pickerCameraTile;

  /// The tooltip on a selected strip tile's remove affordance.
  String get pickerRemove;

  /// The picker permission denied title.
  String get pickerPermissionDeniedTitle;

  /// The picker permission denied body.
  String get pickerPermissionDeniedBody;

  /// The picker open settings.
  String get pickerOpenSettings;

  /// The picker limited banner.
  String get pickerLimitedBanner;

  /// The picker manage selection.
  String get pickerManageSelection;

  /// The empty state under limited access.
  ///
  /// This must never say "no photos found". Neither OS reports which media
  /// kinds are in a limited selection, so images-requested/videos-granted
  /// yields `limited` plus zero results, which is indistinguishable from an
  /// empty library (design §4.2). It offers *Manage selection* instead.
  String get pickerEmptyLimited;

  /// The empty state under full access, where the library really is empty.
  String get pickerEmptyLibrary;

  /// The picker downloading from cloud.
  String get pickerDownloadingFromCloud;

  /// The picker download failed.
  String get pickerDownloadFailed;

  /// The picker retry.
  String get pickerRetry;

  /// The crop title.
  String get cropTitle;

  /// The crop apply to all.
  String get cropApplyToAll;

  /// The crop reorder hint.
  String get cropReorderHint;

  /// The crop trim.
  String get cropTrim;

  /// The crop cover frame.
  String get cropCoverFrame;

  /// Play the video preview.
  String get cropPlay;

  /// Pause the video preview.
  String get cropPause;

  /// The export failed.
  String get exportFailed;

  /// The export cancel.
  String get exportCancel;

  /// Selected count.
  String selectedCount(int count);

  /// Limit reached.
  String limitReached(int max);

  /// The named ratios only. A custom ratio has no name, so the chip prints its
  /// numbers instead — see `aspectChipLabel`.
  String aspectLabel(CropAspectLabel label);

  /// Duration range.
  String durationRange(Duration start, Duration end);

  /// Export progress.
  String exportProgress(int done, int total);

  /// Video too long.
  String videoTooLong(Duration max);

  /// File too large.
  String fileTooLarge(int maxBytes);
}
