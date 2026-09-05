import 'package:kutu_asset_picker/kutu_asset_picker.dart';

/// The four shapes of picker a real app tends to need.
///
/// They are constants outside the widget tree on purpose: configuration is not
/// UI state, and a `const` config is what lets the demo prove that
/// `AssetPickerConfig` is genuinely const-constructible.
abstract final class DemoConfigs {
  /// The full path — multi-select, reorder, per-asset ratios, sequential export.
  static const AssetPickerConfig post = AssetPickerConfig(
    mediaTypes: <PickerMediaType>{PickerMediaType.image, PickerMediaType.video},
    maxSelection: 10,
    aspects: <CropAspect>[
      CropAspect.square,
      CropAspect.portrait45,
      CropAspect.landscape169,
    ],
  );

  /// Forced 9:16 on a sheet. A single-entry `aspects` list *is* the
  /// forced-ratio mode — there is no second flag.
  static const AssetPickerConfig story = AssetPickerConfig(
    mediaTypes: <PickerMediaType>{PickerMediaType.image, PickerMediaType.video},
    maxSelection: 1,
    aspects: <CropAspect>[CropAspect.story916],
    pickerSurface: PickerSurface.sheet,
    cropSurface: PickerSurface.sheet,
  );

  /// A circular overlay over a square export rect.
  static const AssetPickerConfig avatar = AssetPickerConfig(
    mediaTypes: <PickerMediaType>{PickerMediaType.image},
    maxSelection: 1,
    aspects: <CropAspect>[CropAspect.square],
    cropOverlayShape: CropOverlayShape.circle,
    pickerSurface: PickerSurface.sheet,
    cropSurface: PickerSurface.sheet,
  );

  /// 3:1, where the cover-scale clamp is easiest to see.
  static const AssetPickerConfig banner = AssetPickerConfig(
    mediaTypes: <PickerMediaType>{PickerMediaType.image},
    maxSelection: 1,
    aspects: <CropAspect>[CropAspect.banner31],
  );
}

/// Every string the example renders (Flutter rule 3).
abstract final class DemoLabels {
  /// Button for [DemoConfigs.post].
  static const String post = 'Post';

  /// Button for [DemoConfigs.story].
  static const String story = 'Story';

  /// Button for [DemoConfigs.avatar].
  static const String avatar = 'Avatar';

  /// Button for [DemoConfigs.banner].
  static const String banner = 'Banner';

  /// Summary line before the first completed pick.
  static const String nothingPicked = 'Nothing picked yet.';

  /// Summary suffix after a pick: "Post — 3 asset(s)".
  static const String separator = ' — ';

  /// Summary unit.
  static const String assetsUnit = ' asset(s)';
}
