## 0.2.0

**Breaking.** The camera cell works. It never could before: `KutuAssetPicker.show`
and `AssetPickerScope` accepted no delegate, and 0.1.1's root-container fix closed
the only other route a host had.

- `KutuAssetPicker.show` and `AssetPickerScope` take a `camera:` delegate.
- `PickerCameraDelegate.capture` now returns `CapturedMedia?` (a file plus its
  kind) instead of `PickerAsset?`. A host no longer saves to the photo library
  and therefore needs no `photo_manager` dependency of its own.
- `AssetSource` gains `saveToLibrary`, which is where that write now happens.
  **Anyone implementing `AssetSource` must add it.**
- New `AssetPickerText.pickerCaptureFailed`. A denied camera permission or a
  refused library write is now visible in the cell rather than silent.

## 0.1.1

- **Fixed: the picker showed "photo access is off" and never asked the OS
  when the host app already had a root `ProviderScope`** — which every
  Riverpod app does. `AssetPickerScope` nested a `ProviderScope(overrides:)`
  under the host's, making it a child scope; providers the picker does not
  override, such as its permission provider, then resolved at the host's
  root, where the injection providers throw by design, and the gate rendered
  that error as a denial. The scope now owns a root container of its own.
  The example app has no root scope, which is why it never reproduced.
- Documented that a consumer embedding `AssetPickerView` directly must give
  it a root container (`UncontrolledProviderScope` over a fresh
  `ProviderContainer`) or override the injection providers at their own root,
  not a nested `ProviderScope(overrides:)`.

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
- Crop step with pan and pinch-zoom against a fixed window, the rest of the
  media showing dimmed beyond it and draggable from there, per-asset aspect
  ratios, an *Apply to all* affordance, and crop state preserved across asset
  switching.
- Video is cropped, trimmed and given a cover frame on device, through
  `kutu_media_transform`. The trim and cover controls sit in a band under the
  crop window, reserved for the whole session so the window never resizes
  between a photo and a video. The kept range can be dragged as a whole, and
  played, looping, with a playhead on the filmstrip to drag a trim handle
  towards; in cover mode pausing picks the frame.
- `AssetPickerConfig` for behaviour, `AssetPickerTheme` (a `ThemeExtension`,
  every field nullable, falling back to `ColorScheme`) for looks, and
  `AssetPickerText` for copy, with English and Turkish shipped.
- Exports run strictly one at a time, are cancellable as a batch, and report
  progress per asset; one failed asset does not fail the batch.
- `package:kutu_asset_picker/testing.dart` exports `FakeAssetSource`.
