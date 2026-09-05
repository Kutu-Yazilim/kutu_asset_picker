import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/picker/album_dropdown_button.dart';
import 'package:kutu_asset_picker/src/picker/album_list_sheet.dart';
import 'package:kutu_asset_picker/src/picker/picker_app_bar.dart';
import 'package:kutu_asset_picker/testing.dart';

import '../support/pump_picker.dart';

FakeAssetSource _twoAlbums() => FakeAssetSource(
      albumList: const <PickerAlbum>[
        PickerAlbum(id: 'all', name: 'Recent', assetCount: 12, isAll: true),
        PickerAlbum(id: 'cam', name: 'Camera', assetCount: 4, isAll: false),
      ],
      assetsByAlbum: <String, List<PickerAsset>>{
        'all': testAssets(12),
        'cam': testAssets(4, prefix: 'c'),
      },
    );

void main() {
  testWidgets('the dropdown shows the fallback label before albums load',
      (WidgetTester tester) async {
    final FakeAssetSource source = _twoAlbums()
      ..queryDelay = const Duration(milliseconds: 50);
    addTearDown(source.dispose);

    await pumpPicker(tester, const AlbumDropdownButton(), source: source);

    expect(find.text(en.pickerAlbumAll), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('the dropdown shows the current album name',
      (WidgetTester tester) async {
    final FakeAssetSource source = _twoAlbums();
    addTearDown(source.dispose);

    final ProviderContainer container =
        await pumpPicker(tester, const AlbumDropdownButton(), source: source);
    await container.read(assetPickerAlbumsProvider.future);
    await tester.pumpAndSettle();

    expect(find.text('Recent'), findsOneWidget);
  });

  testWidgets('tapping it opens the album list', (WidgetTester tester) async {
    final FakeAssetSource source = _twoAlbums();
    addTearDown(source.dispose);

    final ProviderContainer container =
        await pumpPicker(tester, const AlbumDropdownButton(), source: source);
    await container.read(assetPickerAlbumsProvider.future);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AlbumDropdownButton));
    await tester.pumpAndSettle();

    expect(find.byType(AlbumListSheet), findsOneWidget);
    expect(find.text('Camera'), findsOneWidget);
  });

  testWidgets('choosing an album switches the current one and closes the sheet',
      (WidgetTester tester) async {
    final FakeAssetSource source = _twoAlbums();
    addTearDown(source.dispose);

    final ProviderContainer container =
        await pumpPicker(tester, const AlbumDropdownButton(), source: source);
    await container.read(assetPickerAlbumsProvider.future);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AlbumDropdownButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Camera'));
    await tester.pumpAndSettle();

    expect(container.read(currentAlbumProvider)!.id, 'cam');
    expect(find.byType(AlbumListSheet), findsNothing);
  });

  testWidgets('each album row shows its asset count',
      (WidgetTester tester) async {
    final FakeAssetSource source = _twoAlbums();
    addTearDown(source.dispose);

    final ProviderContainer container =
        await pumpPicker(tester, const AlbumDropdownButton(), source: source);
    await container.read(assetPickerAlbumsProvider.future);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AlbumDropdownButton));
    await tester.pumpAndSettle();

    expect(find.text('12'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
  });

  testWidgets('the app bar carries the dropdown and a cancel affordance',
      (WidgetTester tester) async {
    final FakeAssetSource source = _twoAlbums();
    addTearDown(source.dispose);

    await pumpPicker(
      tester,
      const Scaffold(appBar: PickerAppBar(), body: SizedBox.shrink()),
      source: source,
      wrapInScaffold: false,
    );

    expect(find.byType(AlbumDropdownButton), findsOneWidget);
    expect(find.byTooltip(en.pickerCancel), findsOneWidget);
  });
}
