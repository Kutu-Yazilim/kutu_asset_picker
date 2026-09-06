import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/src/config/asset_picker_config.dart';
import 'package:kutu_asset_picker/src/config/crop_aspect.dart';
import 'package:kutu_asset_picker/src/config/picker_enums.dart';
import 'package:kutu_asset_picker/src/crop/crop_providers.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_aspect_chip_row.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_dimming_mask.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_thirds_overlay.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_viewport.dart';
import 'package:kutu_asset_picker/src/providers/asset_page_provider.dart';
import 'package:kutu_asset_picker/src/providers/selection_provider.dart';
import 'package:kutu_asset_picker/src/providers/injection_providers.dart';
import 'package:kutu_asset_picker/src/source/picker_asset.dart';
import 'package:kutu_asset_picker/src/source/picker_media_type.dart';

const Size kStage = Size(320, 320);
const Size kWindow = Size(240, 135);
const Key viewportGoldenKey = Key('crop viewport golden');

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

ThemeData themeFor(Brightness brightness) => ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2E7D32),
        brightness: brightness,
      ),
    );

/// A neutral backdrop, so the mask's alpha is visible in the golden instead of
/// dissolving into whatever the theme's background happens to be.
Widget stage(Brightness brightness, Widget child) => MaterialApp(
      theme: themeFor(brightness),
      debugShowCheckedModeBanner: false,
      home: Center(
        child: SizedBox.fromSize(
          size: kStage,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Positioned.fill(
                child: ColoredBox(color: Color(0xFF7F7F7F)),
              ),
              child,
            ],
          ),
        ),
      ),
    );

void main() {
  for (final brightness in Brightness.values) {
    final suffix = brightness.name;

    testWidgets('crop overlay, rectangle — $suffix', (tester) async {
      await tester.pumpWidget(
        stage(
          brightness,
          const Positioned.fill(
            child: CropDimmingMask(
              window: kWindow,
              shape: CropOverlayShape.rectangle,
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(CropDimmingMask),
        matchesGoldenFile('crop_overlay_rect_$suffix.png'),
      );
    });

    testWidgets('crop overlay, circle — $suffix', (tester) async {
      await tester.pumpWidget(
        stage(
          brightness,
          const Positioned.fill(
            child: CropDimmingMask(
              window: Size(200, 200),
              shape: CropOverlayShape.circle,
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(CropDimmingMask),
        matchesGoldenFile('crop_overlay_circle_$suffix.png'),
      );
    });

    testWidgets('thirds grid, visible — $suffix', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(cropInteractionProvider.notifier).begin();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: stage(
            brightness,
            const CropThirdsOverlay(window: kWindow),
          ),
        ),
      );
      // The fade is an AnimatedOpacity, so settle before capturing or the
      // golden records a half-transparent grid that differs run to run.
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(CropThirdsOverlay),
        matchesGoldenFile('crop_thirds_$suffix.png'),
      );
    });

    testWidgets('media shows through the mask beyond the window — $suffix', (
      tester,
    ) async {
      // A 1000×500 image covering a 240×135 window is drawn 270×135, so 15px
      // of it shows on either side of the window. Those strips must be the
      // image, darkened — not the stage backdrop. Above and below the window
      // there is no image, and the backdrop shows dimmed there instead.
      final container = ProviderContainer(
        overrides: [
          assetPickerConfigProvider.overrideWithValue(
            const AssetPickerConfig(aspects: [CropAspect.landscape169]),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: stage(
            brightness,
            RepaintBoundary(
              key: viewportGoldenKey,
              child: Stack(
                alignment: Alignment.center,
                children: const [
                  CropViewport(
                    assetId: 'a',
                    imageSize: Size(1000, 500),
                    window: kWindow,
                    child: ColoredBox(color: Color(0xFF00C853)),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CropDimmingMask(
                        window: kWindow,
                        shape: CropOverlayShape.rectangle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await expectLater(
        find.byKey(viewportGoldenKey),
        matchesGoldenFile('crop_viewport_dimmed_$suffix.png'),
      );
    });

    testWidgets('ratio chips — $suffix', (tester) async {
      final container = ProviderContainer(
        overrides: [
          assetPickerConfigProvider.overrideWithValue(
            const AssetPickerConfig(
              aspects: [
                CropAspect.square,
                CropAspect.portrait45,
                CropAspect.landscape169,
              ],
            ),
          ),
          assetPageProvider.overrideWith(
            () => _FixedAssetPage([asset('a'), asset('b')]),
          ),
          selectionProvider.overrideWith(() => _FixedSelection(['a', 'b'])),
        ],
      );
      addTearDown(container.dispose);
      await container.read(assetPageProvider.future);
      container
          .read(cropStatesProvider.notifier)
          .setAspect('a', CropAspect.portrait45);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: themeFor(brightness),
            debugShowCheckedModeBanner: false,
            home: const Scaffold(
              body: Center(child: CropAspectChipRow(assetId: 'a')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(CropAspectChipRow),
        matchesGoldenFile('crop_chips_$suffix.png'),
      );
    });
  }
}
