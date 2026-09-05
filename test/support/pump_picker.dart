import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/testing.dart';
import 'package:kutu_asset_picker/src/text/asset_picker_text_scope.dart';

/// Builds a `PickerAsset` with sensible defaults, so a test names only what it
/// cares about.
PickerAsset testAsset(
  String id, {
  PickerMediaType type = PickerMediaType.image,
  Duration? duration,
  int width = 1000,
  int height = 1000,
  bool isLivePhoto = false,
}) =>
    PickerAsset(
      id: id,
      type: type,
      width: width,
      height: height,
      createdAt: DateTime.utc(2026, 8, 4),
      duration: duration,
      isLivePhoto: isLivePhoto,
    );

/// `count` images named `a0`, `a1`, …
List<PickerAsset> testAssets(int count, {String prefix = 'a'}) =>
    <PickerAsset>[for (int i = 0; i < count; i += 1) testAsset('$prefix$i')];

/// The copy under test. Widget tests assert against this, never a literal —
/// the same discipline `apps/mobile` gets from `l10nOf(tester)`.
const AssetPickerText en = AssetPickerTextEn();

/// A `FakeAssetSource` with one album holding [assets], already wired to the
/// album id the harness selects.
FakeAssetSource fakeSourceWith(
  List<PickerAsset> assets, {
  PickerPermission permission = PickerPermission.full,
  String albumId = 'all',
  String albumName = 'Recent',
}) =>
    FakeAssetSource(
      permission: permission,
      albumList: <PickerAlbum>[
        PickerAlbum(
          id: albumId,
          name: albumName,
          assetCount: assets.length,
          isAll: true,
        ),
      ],
      assetsByAlbum: <String, List<PickerAsset>>{albumId: assets},
    );

/// Pumps [child] inside a scope wired exactly the way the picker wires itself.
///
/// Returns the container, so a test can drive notifiers directly.
Future<ProviderContainer> pumpPicker(
  WidgetTester tester,
  Widget child, {
  required FakeAssetSource source,
  AssetPickerConfig config = const AssetPickerConfig(),
  PickerCameraDelegate? camera,
  ThemeData? theme,
  AssetPickerText text = en,
  bool wrapInScaffold = true,
  List<Override> extraOverrides = const <Override>[],
}) async {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      assetPickerConfigProvider.overrideWithValue(config),
      assetSourceProvider.overrideWithValue(source),
      pickerCameraDelegateProvider.overrideWithValue(camera),
      ...extraOverrides,
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: theme ?? ThemeData.light(),
        home: AssetPickerTextScope(
          text: text,
          child: wrapInScaffold ? Scaffold(body: child) : child,
        ),
      ),
    ),
  );
  await tester.pump();
  return container;
}
