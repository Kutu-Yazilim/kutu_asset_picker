import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/picker/camera_tile.dart';

import '../support/pump_picker.dart';

/// Returns whatever it is told to, and records what it was asked for.
final class _RecordingCamera implements PickerCameraDelegate {
  _RecordingCamera(this.result);

  final CapturedMedia? result;
  final List<Set<PickerMediaType>> calls = <Set<PickerMediaType>>[];

  @override
  Future<CapturedMedia?> capture(Set<PickerMediaType> kinds) async {
    calls.add(kinds);
    return result;
  }
}

CapturedMedia _shot() =>
    CapturedMedia(file: File('/tmp/shot.jpg'), kind: PickerMediaType.image);

void main() {
  testWidgets('the tile is labelled through the text delegate',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(1));
    addTearDown(source.dispose);

    await pumpPicker(
      tester,
      const SizedBox(height: 80, width: 80, child: CameraTile()),
      source: source,
      camera: _RecordingCamera(null),
    );

    expect(find.text(en.pickerCameraTile), findsOneWidget);
  });

  testWidgets('tapping asks the delegate for the configured media kinds',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(1));
    addTearDown(source.dispose);
    final _RecordingCamera camera = _RecordingCamera(null);

    await pumpPicker(
      tester,
      const SizedBox(height: 80, width: 80, child: CameraTile()),
      source: source,
      camera: camera,
      config: const AssetPickerConfig(
        mediaTypes: <PickerMediaType>{PickerMediaType.image},
      ),
    );

    await tester.tap(find.byType(CameraTile));
    await tester.pumpAndSettle();

    expect(camera.calls.single, <PickerMediaType>{PickerMediaType.image});
  });

  testWidgets('a capture lands at the head of the grid and is selected',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(2));
    addTearDown(source.dispose);
    // The delegate only hands back a file; the library asset the grid shows
    // is whatever the fake source's saveToLibrary is configured to return.
    source.saveResult = testAsset('fresh');

    final ProviderContainer container = await pumpPicker(
      tester,
      const SizedBox(height: 80, width: 80, child: CameraTile()),
      source: source,
      camera: _RecordingCamera(_shot()),
    );

    // Page the album first, so there is a list to prepend to.
    container.read(currentAlbumProvider.notifier).select(
          const PickerAlbum(
              id: 'all', name: 'Recent', assetCount: 2, isAll: true),
        );
    await container.read(assetPageProvider.future);

    await tester.tap(find.byType(CameraTile));
    await tester.pumpAndSettle();

    expect(container.read(assetPageProvider).requireValue.first.id, 'fresh');
    expect(container.read(selectionProvider), <String>['fresh']);
  });

  testWidgets('a cancelled capture changes nothing',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(2));
    addTearDown(source.dispose);

    final ProviderContainer container = await pumpPicker(
      tester,
      const SizedBox(height: 80, width: 80, child: CameraTile()),
      source: source,
      camera: _RecordingCamera(null),
    );

    await tester.tap(find.byType(CameraTile));
    await tester.pumpAndSettle();

    expect(container.read(selectionProvider), isEmpty);
  });

  testWidgets('a capture past the cap is not force-selected',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(2));
    addTearDown(source.dispose);

    final ProviderContainer container = await pumpPicker(
      tester,
      const SizedBox(height: 80, width: 80, child: CameraTile()),
      source: source,
      camera: _RecordingCamera(_shot()),
      config: const AssetPickerConfig(maxSelection: 1),
    );
    container.read(selectionProvider.notifier).toggleAsset(testAsset('a0'));

    await tester.tap(find.byType(CameraTile));
    await tester.pumpAndSettle();

    // It still appears in the grid — it is a real asset now — but the cap is
    // the cap.
    expect(container.read(selectionProvider), <String>['a0']);
  });
}
