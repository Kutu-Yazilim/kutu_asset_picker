# kutu_asset_picker

A themeable gallery picker for Flutter with a **device-side crop step for photos and
video**: per-asset aspect ratios, trim, cover frames, and a limited-access state that was
designed rather than tolerated.

One design on both platforms. No native modal, no `Activity` push, no `ThemeData`-only
theming, and no ownership of your `Navigator`.

## Install

```yaml
dependencies:
  kutu_asset_picker: ^0.2.0
```

The transform engine is a separate package and comes in transitively; depend on it
directly only if you want to call
[kutu_media_transform](https://pub.dev/packages/kutu_media_transform) yourself.

Then do the [platform setup](#platform-setup). It is not optional and packaging cannot do
it for you.

## Quick start

```dart
import 'package:kutu_asset_picker/kutu_asset_picker.dart';

Future<void> addPhotos(BuildContext context) async {
  final AssetPickerResult? result = await KutuAssetPicker.show(
    context,
    config: const AssetPickerConfig(
      mediaTypes: <PickerMediaType>{PickerMediaType.image, PickerMediaType.video},
      maxSelection: 10,
      aspects: <CropAspect>[
        CropAspect.square,
        CropAspect.portrait45,
        CropAspect.landscape169,
      ],
    ),
  );
  if (result == null) {
    return; // cancelled
  }
  for (final PickedAsset asset in result.assets) {
    // asset.file is the exported file: cropped, trimmed, re-encoded.
  }
}
```

An avatar picker is the same call with different configuration:

```dart
const AssetPickerConfig avatar = AssetPickerConfig(
  mediaTypes: <PickerMediaType>{PickerMediaType.image},
  minSelection: 1,
  maxSelection: 1,
  aspects: <CropAspect>[CropAspect.square],
  cropOverlayShape: CropOverlayShape.circle,
  pickerSurface: PickerSurface.sheet,
  cropSurface: PickerSurface.sheet,
);
```

A single-entry `aspects` list *is* the forced-ratio mode. There is no second flag.

## Embedding it in your own route

`KutuAssetPicker.show` is a thin wrapper over the embeddable widget, not the other way
round — so a `go_router` sub-route or a state-driven flow gets the real thing, not a
degraded version. Mount `AssetPickerView` yourself and supply the scoped providers:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';

const AssetPickerConfig composerConfig = AssetPickerConfig(
  mediaTypes: <PickerMediaType>{PickerMediaType.image, PickerMediaType.video},
  maxSelection: 4,
);

class ComposerRoute extends StatelessWidget {
  const ComposerRoute({super.key});

  // One source for the whole route. Constructing a fresh
  // PhotoManagerAssetSource() inside build() would hand the scope a different
  // override value on every rebuild, which throws the grid and the selection
  // away each time an ancestor rebuilds.
  static final AssetSource composerSource = PhotoManagerAssetSource();

  @override
  Widget build(BuildContext context) => ProviderScope(
        overrides: <Override>[
          assetPickerConfigProvider.overrideWithValue(composerConfig),
          assetSourceProvider.overrideWithValue(composerSource),
        ],
        child: AssetPickerView(
          onCompleted: (AssetPickerResult result) =>
              Navigator.of(context).pop(result),
          onCancelled: () => Navigator.of(context).pop(),
        ),
      );
}
```

Writing that `ProviderScope` yourself means writing `flutter_riverpod` types yourself, so
declare `flutter_riverpod` in your own `pubspec.yaml`. It arrives transitively either way,
but importing a package you have not declared is what `depend_on_referenced_packages`
exists to catch.

`onCompleted` is **required**, and it is the only way a result leaves the widget. There is
no `Future` to await here by design: the widget owns no route, so it has nothing to pop
and nothing to complete — you decide what finishing means, whether that is
`Navigator.pop`, `context.pop`, or writing the result into your own state. (The
convenience path is the one with the `Future`: `KutuAssetPicker.show` pushes a route and
resolves with the same result.) `onCancelled` is optional, and omitting it makes the
picker's own cancel affordance a no-op — supply it unless something else in your route
handles dismissal.

`assetPickerConfigProvider` and `assetSourceProvider` throw when read without an
override. That is deliberate: a missing override is a wiring bug and should fail loudly
instead of silently picking a default. `mediaTransformProvider` does have a production
default, and you override it only in tests.

If your app has no Riverpod tree of its own, `AssetPickerScope` is the same widget with
the wiring folded in: it creates the `ProviderScope` and writes those overrides for you,
taking `config` and `source` as plain arguments alongside `onCompleted` and `onCancelled`
— both required there, unlike on `AssetPickerView` — plus the optional `transform`,
`theme` and `text`.

## AssetPickerConfig

| field | type | default | what it does |
|---|---|---|---|
| `mediaTypes` | `Set<PickerMediaType>` | `{image, video}` | which kinds the grid queries and shows |
| `minSelection` | `int` | `1` | *Next* enables at this count |
| `maxSelection` | `int` | `10` | `1` is single-pick mode; further taps are disabled at the cap |
| `aspects` | `List<CropAspect>` | `[square, portrait45, landscape169]` | the ratio menu; a single-entry list is the forced-ratio mode |
| `initialAspect` | `CropAspect?` | `null` | which chip starts selected; `null` means `aspects.first` |
| `allowPerAssetAspect` | `bool` | `true` | `false` collapses the batch to one shared aspect |
| `cropOverlayShape` | `CropOverlayShape` | `rectangle` | `circle` for avatars — the export rect stays square |
| `gridColumns` | `int` | `3` | cells per row |
| `cellAspectRatio` | `double` | `1.0` | non-square cells are supported |
| `gridSpacing` | `double` | `2.0` | logical pixels between cells |
| `pickerSurface` | `PickerSurface` | `page` | `sheet` or `page` |
| `cropSurface` | `PickerSurface` | `page` | configured independently of `pickerSurface` |
| `enableCamera` | `bool` | `true` | camera tile as the first cell, delegating to the OS camera |
| `enableCrop` | `bool` | `true` | `false` skips the crop step; sources are still transcoded, never returned raw |
| `enableTrim` | `bool` | `true` | the video trim rail |
| `enableCoverFrame` | `bool` | `true` | the cover-frame picker |
| `maxVideoDuration` | `Duration?` | `null` | both a query-time filter and the trim clamp |
| `maxSourceMegapixels` | `int?` | `null` | honoured **at decode**, so it caps peak memory too |
| `keepOriginals` | `bool` | `false` | populates `PickedAsset.originalFile` |
| `imageEncode` | `ImageEncodeSettings` | `ImageEncodeSettings()` | JPEG quality, long-edge cap, output format |
| `videoEncode` | `VideoEncodeSettings` | `VideoEncodeSettings()` | codec, resolution cap, bitrate, HDR mode, audio |
| `thumbSize` | `ThumbSize` | `ThumbSize.square(200)` | one flat grid thumbnail size — per-cell scaling multiplies cache keys and is the thing to avoid |

`effectiveInitialAspect` resolves `initialAspect ?? aspects.first`.

`CropAspect` ships five named constants — `square` (1:1), `portrait45` (4:5),
`landscape169` (16:9), `story916` (9:16), `banner31` (3:1) — plus
`CropAspect(x: …, y: …, label: CropAspectLabel.custom)` for anything else.

## Camera

The grid's first cell can hand off to the OS camera — but this package ships **no
capture plugin**. Reaching a real camera needs a platform plugin, and picking one is a
host decision, not this package's. `image_picker` is a common choice — add it to your
own `pubspec.yaml`, not this package's — and implement the seam yourself:

```dart
import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';

class ImagePickerCameraDelegate implements PickerCameraDelegate {
  const ImagePickerCameraDelegate();

  @override
  Future<CapturedMedia?> capture(Set<PickerMediaType> kinds) async {
    final ImagePicker picker = ImagePicker();
    // image_picker cannot offer photo and video from one camera call — a host
    // that allows both kinds decides which to launch before calling here.
    final bool video =
        kinds.length == 1 && kinds.single == PickerMediaType.video;
    final XFile? shot = video
        ? await picker.pickVideo(source: ImageSource.camera)
        : await picker.pickImage(source: ImageSource.camera);
    if (shot == null) {
      return null; // the user backed out
    }
    return CapturedMedia(
      file: File(shot.path),
      kind: video ? PickerMediaType.video : PickerMediaType.image,
    );
  }
}
```

Pass it to either entry point:

```dart
await KutuAssetPicker.show(
  context,
  config: config,
  camera: const ImagePickerCameraDelegate(),
);
```

`enableCamera` already defaults to `true`, so a non-null `camera` is all the tile
needs to appear; set `enableCamera: false` to keep a delegate wired but hide it.

**Return the raw file and stop — do not save it yourself.** The picker addresses
every asset by a platform id (`PickerAsset.id`): thumbnails and export both resolve
through it, and a bare temp file the camera just wrote has no such id to give them.
`AssetSource.saveToLibrary` is what turns your `CapturedMedia` into a library asset,
immediately after your delegate returns — so captures are saved into the device
library not as a policy choice but because that is the only way one can join the
grid at all. That is also why this package's own `photo_manager` dependency, not
yours, is what touches the library: a delegate needs none.

A denied camera permission or a refused library write both render
`AssetPickerText.pickerCaptureFailed` on the tile — silent before 0.2.0, visible now.

Two permission surfaces, not one. Your delegate's plugin needs whatever it needs to
launch the camera (`CAMERA` / `NSCameraUsageDescription`, already in
[Platform setup](#platform-setup) behind `enableCamera`). Saving the result needs the
library's **write** access separately — new on Android, nothing new on iOS; see that
same section for the exact keys.

## The crop step

One screen for every selected asset, with a permanent rail of thumbnails along the
bottom to tab between them. Each asset keeps its own framing and its own ratio; *Apply
to all* copies the ratio, never the pan and zoom, because a crop centred on a face in
one photo lands on a shoulder in the next.

**Framing.** The window is fixed and the media moves under it: drag to pan, pinch to
zoom, fling to coast. The image can never leave a gap — zoom-out stops at the scale
that still covers the window, and pans clamp at the edges. The rest of the photo shows
darkened beyond the window, and a drag that starts on that darkened part still pans. A
rule-of-thirds grid fades in while you hold and out when you let go.

**Video.** A control bar sits under the window — under, not over, so it never covers
the footage being framed — and the window is the same size whether a photo or a video
is focused. The bar holds:

- **Trim.** Two handles on a filmstrip of the whole clip. Drag a handle to move one
  end, or grab the framed zone between them to carry the whole range with its length
  intact. Dragging seeks the muted preview, so you see the frame under your finger.
- **Play.** The play chip plays the kept range, looping at the out point. In trim mode
  a playhead rides the filmstrip and stays where playback stopped, as the mark to drag
  a handle towards; pausing lands the picture on that exact frame.
- **Cover.** A second mode on the same filmstrip: one cursor picks the poster frame,
  constrained to the kept range. While the clip plays the cursor follows the playhead,
  and pausing — with the chip or by grabbing the cursor — picks that frame.

`enableTrim: false` and `enableCoverFrame: false` remove their controls; with both off
the bar is gone and the video is cropped whole. `maxVideoDuration` caps the kept range
and slides the window rather than letting it exceed the cap.

Everything above is on-device preview only. Nothing is written until *Done*, when the
export queue runs the framing, trim and cover through `kutu_media_transform`, one
asset at a time.

## The result, and who owns the files

```dart
sealed class PickedAsset {
  String get id;            // the source asset id
  File get file;            // the EXPORTED file: cropped, trimmed, re-encoded
  String get mimeType;
  int get sizeBytes;
  int get width;
  int get height;
  double get aspectRatio;   // the ratio the author chose
  File? get originalFile;   // null unless keepOriginals
}
```

`PickedAsset` is sealed, so a `switch` over `PickedImage` and `PickedVideo` is exhaustive.
`PickedVideo` adds `duration` (after trim), `trimmed` (the kept range, relative to the
source) and `coverFrame`.

`coverFrame` is **never null**, even with `enableCoverFrame: false` — in that case it is
the first frame of the trimmed range, cropped to the same rectangle. You always have a
poster to render and never have to branch on whether the author happened to pick one.

**You own the exported files.** They are written into a namespaced temporary directory,
and nothing collects them for you — on iOS the platform also caches asset data into the
app container. Call `KutuAssetPicker.clearCache()` when you are done with a batch, or on
a schedule.

## Theming

`AssetPickerTheme` is a `ThemeExtension` with every field nullable, resolved
widget argument → your app's `ThemeExtension` → `ColorScheme` / `TextTheme`.

```dart
MaterialApp(
  theme: ThemeData(
    colorScheme: colorScheme,
    extensions: <ThemeExtension<dynamic>>[
      AssetPickerTheme(
        background: palette.surfaceDeep,
        selectionBadgeFill: palette.accent,
        cropMask: palette.scrim,
        cellRadius: 8,
      ),
    ],
  ),
);
```

Configure nothing and you still get something that looks native rather than a wall of
black — that fallback chain is the point. And because it is a `ThemeExtension`, a
light/dark switch cross-fades through `lerp` instead of hard-cutting.

## Text and localisation

A concrete base class with per-locale subclasses, not a generated delegate you can forget
to register:

```dart
final AssetPickerText text = assetPickerTextFromLocale(Locale('tr'));
```

English and Turkish ship in the box, and unknown locales fall back to **English**.
Overriding one string is `extends` plus one getter:

```dart
final class MyPickerText extends AssetPickerTextEn {
  const MyPickerText();

  @override
  String get pickerTitle => 'Choose your evidence';
}
```

Apps with their own localisation pipeline subclass `AssetPickerText` and read from it. The
package ships no ARB files and has no runtime-crash mode if you forget something.

## Platform setup

Neither platform can be configured from inside a package, for different reasons, so both
blocks below are yours to paste.

### Android

Manifests *do* merge — but `photo_manager` only declares `READ_EXTERNAL_STORAGE` with
`android:maxSdkVersion="32"`, which is inert on Android 13 and later. The modern
permissions are yours to add.

Inside the existing `<manifest>` element of `android/app/src/main/AndroidManifest.xml`,
above `<application>`:

```xml
<!-- Android 13+ (API 33): granular media access. -->
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />

<!-- Android 14+ (API 34): the user may grant a subset instead of the library. -->
<uses-permission android:name="android.permission.READ_MEDIA_VISUAL_USER_SELECTED" />

<!-- Android 12 and below. -->
<uses-permission
    android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />

<!-- Android 9 (API 28) and below, and only reachable through the camera cell's
     library save: pre-scoped-storage MediaStore inserts need this. -->
<uses-permission
    android:name="android.permission.WRITE_EXTERNAL_STORAGE"
    android:maxSdkVersion="28" />

<!-- Only when AssetPickerConfig.enableCamera is true. -->
<uses-permission android:name="android.permission.CAMERA" />
```

Also required: `minSdkVersion` 24 or higher (Flutter's current default).

Requesting broad `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO` carries Play Store review risk.
Read the next section before you ship.

`WRITE_EXTERNAL_STORAGE` above only matters pre-scoped-storage: Android 10 (API 29) and
later grants an app write access to the MediaStore item it just created without it, which
is what the camera cell's library save relies on from there on.

### iOS

`Info.plist` does **not** merge from packages. There is no plist-merge step in the Flutter
iOS toolchain and a podspec cannot inject keys, so a missing key is an App Store
rejection (ITMS-90683) rather than a build error. Add to
`ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to your photos and videos so you can add them to your posts.</string>

<!-- Only when AssetPickerConfig.enableCamera is true. -->
<key>NSCameraUsageDescription</key>
<string>This app uses the camera so you can capture a photo or video without leaving it.</string>

<!-- Only when the camera can record video. -->
<key>NSMicrophoneUsageDescription</key>
<string>This app records audio with your video clips.</string>

<!-- Recommended: suppress iOS's own "select more photos?" alert so the picker's
     own Manage selection bar is the single way to change a limited selection. -->
<key>PHPhotoLibraryPreventAutomaticLimitedAccessAlert</key>
<true/>
```

Check that each key appears **once**. Duplicate keys in one plist dictionary are invalid,
the later one silently wins, and the earlier string is dead — an easy thing to end up with
after copying setup blocks from two packages.

Also required: deployment target 13.0 or higher.

`NSPhotoLibraryAddUsageDescription` is *not* needed. This package requests `readWrite`
access — `photo_manager`'s default, and this package never asks for the narrower
`addOnly` level — so the camera cell's library save runs under the same
`NSPhotoLibraryUsageDescription` grant above rather than a second one.

## Limited access is a designed state, not a fallback

iOS `limited` and Android 14's `READ_MEDIA_VISUAL_USER_SELECTED` render **the same grid**
over the granted subset, with a permanent *Manage selection* bar that reopens the system
selector. Albums are re-queried and paging restarts when it returns, because the counts
are stale by then.

Two rules make this work, and both are easy to get wrong:

- The gate branches on "has access" — authorised **or** limited — never on "is
  authorised". Branching on the latter is exactly what shows limited users an empty grid.
- **Neither OS reports which media kinds are in a limited selection.** Ask for images,
  have the user grant only videos, and you get `limited` plus zero results —
  indistinguishable from an empty library. So the empty state never says "no photos
  found"; it offers *Manage selection*.

If you decide the Play Store risk of broad access is not worth it, ship with only
`READ_MEDIA_VISUAL_USER_SELECTED`: the limited path is a first-class state here, not a
degraded one.

## What this package does not do

- Rotate, straighten or flip. The crop window is fixed and the image moves under it,
  clamped so the window is always covered — one axis-aligned source rect, always.
- Free-form crop with draggable handles. The point of the ratio menu is that the author
  picks a *known* shape the rest of your app can rely on.
- Filters, adjustments, stickers, drawing or text overlays.
- Web, Windows and Linux — `photo_manager` supports none of them.
- Audio assets, Live Photos as a distinct type, or multi-clip editing.
- Builder-slot or delegate-subclass customisation. Configuration and theming only, until a
  second real consumer proves a slot is needed.

## Testing without a device

```dart
import 'package:kutu_asset_picker/testing.dart';
```

`FakeAssetSource` implements `AssetSource`, and `FakeMediaTransform` from
[kutu_media_transform](https://pub.dev/packages/kutu_media_transform) implements the
export seam. Override `assetSourceProvider` and `mediaTransformProvider` in a
`ProviderContainer` and the whole picker is unit-testable — paging, selection, permission
branching, crop-state preservation and export sequencing.

## Licence

MIT. See [LICENSE](LICENSE).
