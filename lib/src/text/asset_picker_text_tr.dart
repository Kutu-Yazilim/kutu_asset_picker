import '../config/picker_enums.dart';
import '../picker/duration_format.dart';
import 'asset_picker_text.dart';

/// Turkish. Shipped alongside English because PatikaX is the first consumer;
/// PatikaX itself supplies a further subclass reading from its 8-locale ARB
/// pipeline, so the repo rule (all copy in ARB, read through `context.l10n`)
/// still holds on the app side (spec §8.2).
///
/// `base class`, not `final`, for the same reason [AssetPickerTextEn] is: a
/// consumer overriding one string writes `extends` plus one getter.
base class AssetPickerTextTr extends AssetPickerText {
  /// Creates a [AssetPickerTextTr].
  const AssetPickerTextTr();

  @override
  String get pickerTitle => 'Medya seç';
  @override
  String get pickerNext => 'İleri';
  @override
  String get pickerCancel => 'Vazgeç';
  @override
  String get pickerDone => 'Bitti';

  @override
  String get pickerAlbumAll => 'Son eklenenler';
  @override
  String get pickerAlbumSwitch => 'Albüm değiştir';

  @override
  String get pickerCameraTile => 'Kamera';

  /// The selected strip's per-tile remove tooltip — slice 3 Task 27 added this
  /// getter to the base class, so a delegate that omits it does not compile.
  @override
  String get pickerRemove => 'Kaldır';

  @override
  String get pickerPermissionDeniedTitle => 'Fotoğraf erişimi kapalı';
  @override
  String get pickerPermissionDeniedBody =>
      'Fotoğraf ve video seçebilmek için Ayarlar’dan fotoğraf erişimini aç.';
  @override
  String get pickerOpenSettings => 'Ayarları aç';

  @override
  String get pickerLimitedBanner => 'Yalnızca seçtiğin öğelere erişim verdin.';
  @override
  String get pickerManageSelection => 'Seçimi yönet';

  @override
  String get pickerEmptyLimited =>
      'Burada henüz bir şey yok. Bu uygulamanın görebileceği öğeleri değiştir, '
      'seçtiklerin burada görünsün.';

  @override
  String get pickerEmptyLibrary => 'Bu cihazda henüz fotoğraf veya video yok.';

  @override
  String get pickerDownloadingFromCloud => 'iCloud’dan indiriliyor';
  @override
  String get pickerDownloadFailed => 'Bu öğe indirilemedi';
  @override
  String get pickerRetry => 'Yeniden dene';

  @override
  String get cropTitle => 'Kırp';
  @override
  String get cropApplyToAll => 'Tümüne uygula';
  @override
  String get cropReorderHint => 'Sıralamak için sürükle';
  @override
  String get cropTrim => 'Kes';
  @override
  String get cropCoverFrame => 'Kapak';
  @override
  String get cropPlay => 'Oynat';
  @override
  String get cropPause => 'Duraklat';
  @override
  String get cropKeptRange => 'Tutulan aralık';

  @override
  String get exportFailed => 'Dışa aktarma başarısız';
  @override
  String get exportCancel => 'Vazgeç';

  @override
  String selectedCount(int count) => '$count seçildi';

  @override
  String limitReached(int max) => 'En fazla $max öğe seçebilirsin';

  @override
  String aspectLabel(CropAspectLabel label) => switch (label) {
        CropAspectLabel.square => '1:1',
        CropAspectLabel.portrait => '4:5',
        CropAspectLabel.landscape => '16:9',
        CropAspectLabel.story => '9:16',
        CropAspectLabel.banner => '3:1',
        CropAspectLabel.custom => 'Özel',
      };

  @override
  String durationRange(Duration start, Duration end) =>
      '${formatPickerDuration(start)} – ${formatPickerDuration(end)}';

  @override
  String exportProgress(int done, int total) => '$total içinden $done';

  @override
  String videoTooLong(Duration max) =>
      'Videolar en fazla ${max.inSeconds} saniye olabilir';

  @override
  String fileTooLarge(int maxBytes) =>
      'Dosyalar en fazla ${maxBytes ~/ (1024 * 1024)} MB olabilir';
}
