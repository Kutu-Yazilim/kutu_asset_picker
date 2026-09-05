import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/src/config/asset_picker_config.dart';
import 'package:kutu_asset_picker/src/config/crop_aspect.dart';
import 'package:kutu_asset_picker/src/crop/crop_providers.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_apply_to_all_button.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_aspect_chip.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_aspect_chip_row.dart';
import 'package:kutu_asset_picker/src/providers/asset_page_provider.dart';
import 'package:kutu_asset_picker/src/providers/selection_provider.dart';
import 'package:kutu_asset_picker/src/providers/injection_providers.dart';
import 'package:kutu_asset_picker/src/source/picker_asset.dart';
import 'package:kutu_asset_picker/src/source/picker_media_type.dart';
import 'package:kutu_asset_picker/src/text/asset_picker_text_en.dart';

PickerAsset asset(String id) => PickerAsset(
      id: id,
      type: PickerMediaType.image,
      width: 1000,
      height: 1000,
      createdAt: DateTime.utc(2026, 8, 4),
    );

class _FixedAssetPage extends AssetPage {
  _FixedAssetPage(this.assets);
  final List<PickerAsset> assets;
  @override
  Future<List<PickerAsset>> build() async => assets;
}

/// Slice 3's ordered selection, pinned to a fixed order.
///
/// It overrides `selectedAssets` as well as `build`: the real notifier resolves
/// that getter through the registry `toggleAsset` fills, and this double never
/// sees a tap. `selectedAssetsProvider` reads it, so leaving it unoverridden
/// would hand every widget under test an empty selection.
class _FixedSelection extends Selection {
  _FixedSelection(this.ids);
  final List<String> ids;
  @override
  List<String> build() => ids;
  @override
  List<PickerAsset> get selectedAssets => [for (final id in ids) asset(id)];
}

Future<ProviderContainer> pumpRow(
  WidgetTester tester, {
  required List<String> ids,
  AssetPickerConfig config = const AssetPickerConfig(),
}) async {
  final container = ProviderContainer(
    overrides: [
      assetPickerConfigProvider.overrideWithValue(config),
      assetPageProvider.overrideWith(
        () => _FixedAssetPage([for (final id in ids) asset(id)]),
      ),
      selectionProvider.overrideWith(() => _FixedSelection(ids)),
    ],
  );
  addTearDown(container.dispose);
  await container.read(assetPageProvider.future);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
          home: Scaffold(body: CropAspectChipRow(assetId: ids.first))),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  const text = AssetPickerTextEn();

  testWidgets('renders one chip per configured ratio', (tester) async {
    await pumpRow(
      tester,
      ids: ['a'],
      config: const AssetPickerConfig(
        aspects: [
          CropAspect.square,
          CropAspect.portrait45,
          CropAspect.story916
        ],
      ),
    );

    expect(find.byType(CropAspectChip), findsNWidgets(3));
    expect(find.text('1:1'), findsOneWidget);
    expect(find.text('4:5'), findsOneWidget);
    expect(find.text('9:16'), findsOneWidget);
  });

  testWidgets('a single-entry list is the forced-ratio mode', (tester) async {
    await pumpRow(
      tester,
      ids: ['a'],
      config: const AssetPickerConfig(aspects: [CropAspect.banner31]),
    );

    expect(find.byType(CropAspectChip), findsOneWidget);
    expect(find.text('3:1'), findsOneWidget);
  });

  testWidgets('tapping a chip changes only that asset ratio', (tester) async {
    final container = await pumpRow(tester, ids: ['a', 'b']);
    final states = container.read(cropStatesProvider.notifier);

    await tester.tap(find.text('16:9'));
    await tester.pump();

    expect(states.stateOf('a').aspect, CropAspect.landscape169);
    expect(states.stateOf('b').aspect, CropAspect.square);
  });

  testWidgets('the selected chip is the one the asset is on', (tester) async {
    final container = await pumpRow(tester, ids: ['a']);

    await tester.tap(find.text('4:5'));
    await tester.pump();

    final chips =
        tester.widgetList<CropAspectChip>(find.byType(CropAspectChip));
    expect(
      chips.where((chip) => chip.isSelected).map((chip) => chip.aspect),
      [CropAspect.portrait45],
    );
    expect(
        container.read(cropStatesProvider)['a']!.aspect, CropAspect.portrait45);
  });

  group('Apply to all', () {
    testWidgets('is hidden with only one asset selected', (tester) async {
      // With nothing to apply it to, the affordance is noise.
      await pumpRow(tester, ids: ['a']);

      expect(find.byType(CropApplyToAllButton), findsNothing);
    });

    testWidgets('is hidden when the batch shares one ratio anyway', (
      tester,
    ) async {
      await pumpRow(
        tester,
        ids: ['a', 'b'],
        config: const AssetPickerConfig(allowPerAssetAspect: false),
      );

      expect(find.byType(CropApplyToAllButton), findsNothing);
    });

    testWidgets('shows with more than one asset and per-asset ratios', (
      tester,
    ) async {
      await pumpRow(tester, ids: ['a', 'b']);

      expect(find.byType(CropApplyToAllButton), findsOneWidget);
      expect(find.text(text.cropApplyToAll), findsOneWidget);
    });

    testWidgets('copies the ASPECT to every asset and nothing else', (
      tester,
    ) async {
      final container = await pumpRow(tester, ids: ['a', 'b']);
      final states = container.read(cropStatesProvider.notifier);

      await tester.tap(find.text('16:9'));
      await tester.pump();
      await tester.tap(find.text(text.cropApplyToAll));
      await tester.pump();

      expect(states.stateOf('a').aspect, CropAspect.landscape169);
      expect(states.stateOf('b').aspect, CropAspect.landscape169);
      // b keeps its own framing — pan and zoom are meaningless on a different
      // image and are never copied (spec §2.4).
      expect(states.stateOf('b').offset, Offset.zero);
    });
  });
}
