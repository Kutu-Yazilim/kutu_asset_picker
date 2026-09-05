import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:kutu_asset_picker/src/config/asset_picker_config.dart';
import 'package:kutu_asset_picker/src/config/crop_aspect.dart';
import 'package:kutu_asset_picker/src/crop/crop_providers.dart';
import 'package:kutu_asset_picker/src/crop/focused_asset_resolver.dart';
import 'package:kutu_asset_picker/src/crop/picker_asset_size.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_asset_rail.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_asset_rail_tile.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_viewport.dart';
import 'package:kutu_asset_picker/src/providers/asset_page_provider.dart';
import 'package:kutu_asset_picker/src/providers/selection_provider.dart';
import 'package:kutu_asset_picker/src/providers/injection_providers.dart';
import 'package:kutu_asset_picker/src/source/picker_asset.dart';
import 'package:kutu_asset_picker/src/source/picker_media_type.dart';

import '../../support/stub_asset_source.dart';
import '../../support/tiny_png.dart';

const Size kWindow = Size(300, 300);

PickerAsset asset(String id, {int width = 1000, int height = 500}) =>
    PickerAsset(
      id: id,
      type: PickerMediaType.image,
      width: width,
      height: height,
      createdAt: DateTime.utc(2026, 8, 4),
    );

class _FixedAssetPage extends AssetPage {
  _FixedAssetPage(this.assets);
  final List<PickerAsset> assets;
  @override
  Future<List<PickerAsset>> build() async => assets;
}

class _RecordingSelection extends Selection {
  _RecordingSelection(this.ids);
  final List<String> ids;
  final List<(int, int)> reorders = <(int, int)>[];
  @override
  List<String> build() => ids;
  @override
  List<PickerAsset> get selectedAssets => [for (final id in ids) asset(id)];
  @override
  void reorder(int oldIndex, int newIndex) =>
      reorders.add((oldIndex, newIndex));
}

/// The rail plus a viewport for whichever asset is focused — the smallest tree
/// that can show framing surviving a switch between assets.
class _RailHarness extends ConsumerWidget {
  const _RailHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focused = resolveFocusedAsset(
      ref.watch(selectedAssetsProvider),
      ref.watch(focusedAssetProvider),
    );
    if (focused == null) return const SizedBox.shrink();
    return Column(
      children: [
        CropViewport(
          assetId: focused.id,
          imageSize: pickerAssetSize(focused),
          window: kWindow,
          child: const ColoredBox(color: Color(0xFF00FF00)),
        ),
        const CropAssetRail(),
      ],
    );
  }
}

Future<(ProviderContainer, _RecordingSelection)> pumpRail(
  WidgetTester tester, {
  required List<String> ids,
}) async {
  final selection = _RecordingSelection(ids);
  final container = ProviderContainer(
    overrides: [
      assetPickerConfigProvider.overrideWithValue(
        const AssetPickerConfig(aspects: [CropAspect.square]),
      ),
      assetSourceProvider.overrideWithValue(
        StubAssetSource(thumbnailBytes: tinyPngBytes()),
      ),
      assetPageProvider.overrideWith(
        () => _FixedAssetPage([for (final id in ids) asset(id)]),
      ),
      selectionProvider.overrideWith(() => selection),
    ],
  );
  addTearDown(container.dispose);
  await container.read(assetPageProvider.future);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: Scaffold(body: _RailHarness())),
    ),
  );
  await tester.pump();
  return (container, selection);
}

void main() {
  testWidgets('renders one tile per selected asset', (tester) async {
    await pumpRail(tester, ids: ['a', 'b', 'c']);

    expect(find.byType(CropAssetRailTile), findsNWidgets(3));
  });

  testWidgets('the rail height never changes with the media type', (
    tester,
  ) async {
    // Spec §2.7: the rail is permanent and fixed so the crop area does not
    // resize as the author tabs between assets.
    await pumpRail(tester, ids: ['a', 'b']);

    expect(tester.getSize(find.byType(CropAssetRail)).height, 76);
  });

  testWidgets('tapping a tile focuses that asset', (tester) async {
    final (container, _) = await pumpRail(tester, ids: ['a', 'b']);

    await tester.tap(find.byKey(const ValueKey('b')));
    await tester.pump();

    expect(container.read(focusedAssetProvider), 'b');
  });

  testWidgets(
    'framing survives leaving an asset and coming back',
    (tester) async {
      // The one behaviour the whole per-asset design exists for (spec §6.1).
      final (container, _) = await pumpRail(tester, ids: ['a', 'b']);

      // Frame A: drag it as far right as the clamp allows.
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(CropViewport)),
      );
      await gesture.moveBy(const Offset(4000, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      final framedA = container.read(cropStatesProvider)['a']!;
      expect(framedA.offset.dx, greaterThan(0));

      // Tab to B, do nothing, tab back to A.
      await tester.tap(find.byKey(const ValueKey('b')));
      await tester.pumpAndSettle();
      expect(container.read(focusedAssetProvider), 'b');

      await tester.tap(find.byKey(const ValueKey('a')));
      await tester.pumpAndSettle();

      final returnedA = container.read(cropStatesProvider)['a']!;
      expect(returnedA.scale, closeTo(framedA.scale, 1e-9));
      expect(returnedA.offset.dx, closeTo(framedA.offset.dx, 1e-9));
      expect(returnedA.offset.dy, closeTo(framedA.offset.dy, 1e-9));
      expect(returnedA.aspect, framedA.aspect);
    },
  );

  testWidgets('a forward drag reaches Selection.reorder in its raw convention',
      (tester) async {
    // onReorderItem reports the ADJUSTED destination (2 for "after c");
    // Selection.reorder keeps ReorderableListView's raw insertion-point
    // convention, so the rail hands it 3 and reorder normalises once.
    final (_, selection) = await pumpRail(tester, ids: ['a', 'b', 'c']);

    tester
        .widget<ReorderableListView>(find.byType(ReorderableListView))
        .onReorderItem!(0, 2);
    await tester.pump();

    expect(selection.reorders.single, (0, 3));
  });

  testWidgets('an upward reorder passes through unchanged', (tester) async {
    final (_, selection) = await pumpRail(tester, ids: ['a', 'b', 'c']);

    tester
        .widget<ReorderableListView>(find.byType(ReorderableListView))
        .onReorderItem!(2, 0);
    await tester.pump();

    expect(selection.reorders.single, (2, 0));
  });
}
