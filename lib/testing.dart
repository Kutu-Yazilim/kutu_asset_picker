/// Test doubles for `kutu_asset_picker`.
///
/// Import this in tests only. Overriding `assetSourceProvider` with
/// [FakeAssetSource] runs the entire picker in a widget test with no device
/// and no platform channels.
library;

export 'src/source/fake_asset_source.dart'
    show FakeAlbumQuery, FakeAssetQuery, FakeAssetSource;
