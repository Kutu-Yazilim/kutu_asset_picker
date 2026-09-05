# kutu_asset_picker example

Four buttons, one for each shape of picker a real app tends to need. It doubles as the
manual test harness for the permission states.

## Run it

```bash
cd packages/kutu_asset_picker/example
flutter run
```

The example's `AndroidManifest.xml` and `Info.plist` carry the setup block from the package
README — read them if you want a working reference rather than a snippet. The Android
manifest declares `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`,
`READ_MEDIA_VISUAL_USER_SELECTED`, `READ_EXTERNAL_STORAGE` capped at API 32, and `CAMERA`;
the plist declares `NSPhotoLibraryUsageDescription`, `NSCameraUsageDescription`,
`NSMicrophoneUsageDescription` and `PHPhotoLibraryPreventAutomaticLimitedAccessAlert`.

## The four configurations

| Button | Config | Why it is interesting |
|---|---|---|
| Post | images + video, `maxSelection: 10`, three aspects, page surfaces | the full path: multi-select, reorder, per-asset ratios, sequential export |
| Story | images + video, `maxSelection: 1`, `[CropAspect.story916]`, sheet surfaces | forced-ratio mode — a single-entry `aspects` list, no chips to show |
| Avatar | images, `maxSelection: 1`, `[CropAspect.square]`, `cropOverlayShape: circle` | the overlay is a circle while the exported rect stays square |
| Banner | images, `maxSelection: 1`, `[CropAspect.banner31]` | an extreme ratio, where the cover-scale clamp is easiest to see |

They are `const AssetPickerConfig` values in `lib/demo_configs.dart`; every `await` lives in
`lib/demo_pick_controller.dart`, never in a widget.

## What to check by hand

- **Limited access.** iOS: *Settings → Privacy & Security → Photos → this app → Limited
  Access*, then relaunch. Android 14+: pick *Select photos and videos* at the prompt. The
  grid must render the granted subset with a *Manage selection* bar, not an empty state.
- **Limited access with the wrong kind granted.** Grant only videos while asking for
  images. The grid is empty and the copy must still offer *Manage selection* — it must
  never claim the library is empty, because neither OS reports which kinds were granted.
- **Ratio change after zooming.** Zoom in at 1:1, then switch to 16:9. No gap may appear
  at any edge.
- **iCloud.** With Optimize Storage on, pick an asset that is not local. Download progress
  must show per asset, and one slow asset must not block the others.
- **Cancel mid-export.** The batch stops, and no partial file reaches the result.

## Tests

```bash
cd packages/kutu_asset_picker/example
flutter test
```

`test/example_smoke_test.dart` builds the demo app and mounts `AssetPickerView` over
`FakeAssetSource` and `FakeMediaTransform`, so it needs no device and no gallery.
