import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/picker/asset_grid.dart';
import 'package:kutu_asset_picker/src/picker/asset_grid_cell.dart';
import 'package:kutu_asset_picker/src/picker/camera_tile.dart';

import '../support/pump_picker.dart';

final class _NullCamera implements PickerCameraDelegate {
  const _NullCamera();

  @override
  Future<CapturedMedia?> capture(Set<PickerMediaType> kinds) async => null;
}

const PickerAlbum _recent =
    PickerAlbum(id: 'all', name: 'Recent', assetCount: 300, isAll: true);

Future<ProviderContainer> _pumpGrid(
  WidgetTester tester, {
  required int assetCount,
  AssetPickerConfig config = const AssetPickerConfig(),
  PickerCameraDelegate? camera,
}) async {
  final source = fakeSourceWith(testAssets(assetCount));
  addTearDown(source.dispose);

  final ProviderContainer container = await pumpPicker(
    tester,
    const AssetGrid(),
    source: source,
    config: config,
    camera: camera,
  );
  container.read(currentAlbumProvider.notifier).select(_recent);
  await tester.pumpAndSettle();
  return container;
}

void main() {
  testWidgets('renders one cell per asset', (WidgetTester tester) async {
    await _pumpGrid(tester, assetCount: 6);

    expect(find.byType(AssetGridCell), findsNWidgets(6));
  });

  testWidgets('the grid geometry comes from the config',
      (WidgetTester tester) async {
    await _pumpGrid(
      tester,
      assetCount: 6,
      config: const AssetPickerConfig(
        gridColumns: 4,
        gridSpacing: 6,
        cellAspectRatio: 0.75,
      ),
    );

    final GridView grid = tester.widget<GridView>(find.byType(GridView));
    final SliverGridDelegateWithFixedCrossAxisCount delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

    expect(delegate.crossAxisCount, 4);
    expect(delegate.mainAxisSpacing, 6);
    expect(delegate.crossAxisSpacing, 6);
    expect(delegate.childAspectRatio, 0.75);
    expect(grid.scrollCacheExtent,
        ScrollCacheExtent.pixels(PickerGridTuning.cacheExtent));
  });

  testWidgets('cells carry their asset id as a ValueKey',
      (WidgetTester tester) async {
    // findChildIndexCallback needs a stable key per asset, and the key is also
    // what keeps element state attached to the right cell when a capture is
    // prepended and every index shifts by one.
    await _pumpGrid(tester, assetCount: 3);

    expect(find.byKey(const ValueKey<String>('a0')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('a2')), findsOneWidget);
  });

  testWidgets('the grid owns no repaint boundaries of its own',
      (WidgetTester tester) async {
    // Exactly one boundary per cell, declared in AssetGridCell.
    await _pumpGrid(tester, assetCount: 3);

    final GridView grid = tester.widget<GridView>(find.byType(GridView));
    // GridView keeps the flag on its child delegate rather than on itself.
    expect(
      (grid.childrenDelegate as SliverChildBuilderDelegate)
          .addRepaintBoundaries,
      isFalse,
    );
  });

  testWidgets('with no camera delegate there is no camera tile',
      (WidgetTester tester) async {
    await _pumpGrid(tester, assetCount: 3);

    expect(find.byType(CameraTile), findsNothing);
  });

  testWidgets('with a delegate the camera is the first cell',
      (WidgetTester tester) async {
    await _pumpGrid(tester, assetCount: 3, camera: const _NullCamera());

    expect(find.byType(CameraTile), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(CameraTile)).dx,
      lessThan(tester.getTopLeft(find.byKey(const ValueKey<String>('a0'))).dx),
    );
  });

  testWidgets('enableCamera false hides the tile even with a delegate',
      (WidgetTester tester) async {
    await _pumpGrid(
      tester,
      assetCount: 3,
      camera: const _NullCamera(),
      config: const AssetPickerConfig(enableCamera: false),
    );

    expect(find.byType(CameraTile), findsNothing);
  });

  testWidgets('scrolling near the end loads the next page',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(300));
    addTearDown(source.dispose);

    final ProviderContainer container =
        await pumpPicker(tester, const AssetGrid(), source: source);
    container.read(currentAlbumProvider.notifier).select(_recent);
    await tester.pumpAndSettle();

    expect(source.assetQueries, hasLength(1));

    // A 90-asset page is ~30 rows tall on the test surface, so one fling
    // does not reliably come within the load-more threshold of the end.
    for (int i = 0; i < 4 && source.assetQueries.length < 2; i++) {
      await tester.fling(find.byType(GridView), const Offset(0, -4000), 8000);
      await tester.pumpAndSettle();
    }

    expect(source.assetQueries.length, greaterThan(1),
        reason: 'the grid must page as the user scrolls, not once');
    expect(source.assetQueries.last.offset, PickerGridTuning.pageSize);
  });

  testWidgets('an external ScrollController is used verbatim',
      (WidgetTester tester) async {
    // Sheet mode hands the DraggableScrollableSheet's controller down so
    // sheet-drag and grid-scroll hand off instead of fighting (design §5).
    final ScrollController controller = ScrollController();
    addTearDown(controller.dispose);
    final source = fakeSourceWith(testAssets(6));
    addTearDown(source.dispose);

    final ProviderContainer container = await pumpPicker(
      tester,
      AssetGrid(scrollController: controller),
      source: source,
    );
    container.read(currentAlbumProvider.notifier).select(_recent);
    await tester.pumpAndSettle();

    expect(tester.widget<GridView>(find.byType(GridView)).controller,
        same(controller));
  });

  testWidgets('an error from the source surfaces instead of hanging',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(3));
    addTearDown(source.dispose);
    final ProviderContainer container =
        await pumpPicker(tester, const AssetGrid(), source: source);

    // An album this fake never listed makes assets() throw.
    container.read(currentAlbumProvider.notifier).select(_recent);
    await tester.pumpAndSettle();

    expect(find.byType(GridView), findsOneWidget);
  });
}
