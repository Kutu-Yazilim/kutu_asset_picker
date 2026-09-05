## 0.1.0

First release.

- `KutuAssetPicker.show` for the convenience path and `AssetPickerView` for
  embedding inside an existing route; the convenience helper is a wrapper over
  the widget, not the other way round, so the package never owns your
  `Navigator`.
- Paged gallery grid over `photo_manager`, behind the injectable `AssetSource`
  seam. Thumbnails go through `PickerAssetImageProvider`, whose value equality
  is the deduplication mechanism, so scroll-aware decode deferral works.
- Full, limited and denied permission states are all designed. Limited access
  renders the same grid over the granted subset with a persistent
  *Manage selection* bar, and the empty state never claims the library is empty.
- Crop step with pan and pinch-zoom against a fixed window, per-asset aspect
  ratios, an *Apply to all* affordance, and crop state preserved across asset
  switching.
- Video is cropped, trimmed and given a cover frame on device, through
  `kutu_media_transform`.
- `AssetPickerConfig` for behaviour, `AssetPickerTheme` (a `ThemeExtension`,
  every field nullable, falling back to `ColorScheme`) for looks, and
  `AssetPickerText` for copy, with English and Turkish shipped.
- Exports run strictly one at a time, are cancellable as a batch, and report
  progress per asset; one failed asset does not fail the batch.
- `package:kutu_asset_picker/testing.dart` exports `FakeAssetSource`.
