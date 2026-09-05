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
  const AssetPickerText();

  String get pickerTitle;
  String get pickerNext;
  String get pickerCancel;
  String get pickerDone;

  String get pickerAlbumAll;
  String get pickerAlbumSwitch;

  String get pickerCameraTile;

  /// The tooltip on a selected strip tile's remove affordance.
  String get pickerRemove;

  String get pickerPermissionDeniedTitle;
  String get pickerPermissionDeniedBody;
  String get pickerOpenSettings;

  String get pickerLimitedBanner;
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

  String get pickerDownloadingFromCloud;
  String get pickerDownloadFailed;
  String get pickerRetry;

  String get cropTitle;
  String get cropApplyToAll;
  String get cropReorderHint;
  String get cropTrim;
  String get cropCoverFrame;

  String get exportFailed;
  String get exportCancel;

  String selectedCount(int count);
  String limitReached(int max);

  /// The named ratios only. A custom ratio has no name, so the chip prints its
  /// numbers instead — see `aspectChipLabel`.
  String aspectLabel(CropAspectLabel label);

  String durationRange(Duration start, Duration end);
  String exportProgress(int done, int total);
  String videoTooLong(Duration max);
  String fileTooLarge(int maxBytes);
}
