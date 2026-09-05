# kutu_asset_picker

A themeable, embeddable asset picker for Flutter. It renders your library in a
grid you control, supports ordered multi-select, and treats Android partial
access and iOS limited access as designed states rather than failure modes.

The package contains no native code. Native media work lives in
[`kutu_media_transform`](https://pub.dev/packages/kutu_media_transform).

## Platform setup

Neither platform can be configured from inside a package, so this block has to
be copied into your app. iOS `Info.plist` files do not merge from packages —
there is no plist-merge step in the Flutter iOS toolchain — and while Android
manifests do merge, `photo_manager` only declares `READ_EXTERNAL_STORAGE` with
`maxSdkVersion=32`, which is inert on Android 13 and later.

### Android — `android/app/src/main/AndroidManifest.xml`

```xml
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_VISUAL_USER_SELECTED" />
<uses-permission
    android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32" />
```

`READ_MEDIA_VISUAL_USER_SELECTED` is what makes Android 14+ partial access
work. Without it a user who grants "select photos" lands in a state the picker
cannot read.

### iOS — `ios/Runner/Info.plist`

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Choose photos and videos from your library to share.</string>
<key>NSCameraUsageDescription</key>
<string>Take a photo or video to share.</string>
```

Declare each key exactly once. Duplicate keys inside one plist dict are invalid
and the later copy silently wins.

## Quick start

```dart
final AssetPickerResult? result = await KutuAssetPicker.show(
  context,
  config: const AssetPickerConfig(
    mediaTypes: {PickerMediaType.image, PickerMediaType.video},
    maxSelection: 10,
    gridColumns: 3,
  ),
);
final List<PickedAsset> assets = result?.assets ?? const <PickedAsset>[];
```

`KutuAssetPicker.show` pushes the configured surface and owns its
`ProviderScope`. To embed the picker in your own route instead — a `go_router`
sub-route, say — mount `AssetPickerView` and wrap it in a `ProviderScope` that
overrides `assetPickerConfigProvider` and `assetSourceProvider` yourself.

`AssetPickerView` ships in this release. `KutuAssetPicker.show`, the crop step
and the `AssetPickerResult` / `PickedAsset` types arrive with the crop release;
until then the embeddable widget hands you the selected `PickerAsset`s directly
through its `onCompleted` callback.

## Theming

`AssetPickerTheme` is a `ThemeExtension` with every field nullable, resolved
widget argument → your app's `ThemeData.extensions` → `ColorScheme`/`TextTheme`.
Configure nothing and the picker still looks native.

## Testing

`package:kutu_asset_picker/testing.dart` exports `FakeAssetSource`. Override
`assetSourceProvider` with it and the whole picker runs in a widget test with
no device and no platform channels.
