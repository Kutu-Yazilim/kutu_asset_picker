import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/src/config/asset_picker_config.dart';
import 'package:kutu_asset_picker/src/config/crop_aspect.dart';
import 'package:kutu_asset_picker/src/crop/crop_providers.dart';
import 'package:kutu_asset_picker/src/crop/widgets/asset_crop_step.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_asset_rail.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_aspect_chip_row.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_dimming_mask.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_stage.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_viewport.dart';
import 'package:kutu_asset_picker/src/export/export_controller.dart';
import 'package:kutu_asset_picker/src/export/export_progress.dart';
import 'package:kutu_asset_picker/src/providers/asset_page_provider.dart';
import 'package:kutu_asset_picker/src/providers/selection_provider.dart';
import 'package:kutu_asset_picker/src/providers/injection_providers.dart';
import 'package:kutu_asset_picker/src/source/picker_asset.dart';
import 'package:kutu_asset_picker/src/source/picker_media_type.dart';
import 'package:kutu_asset_picker/src/text/asset_picker_text_en.dart';

import '../../support/recording_media_transform.dart';
import '../../support/stub_asset_source.dart';
import '../../support/tiny_png.dart';
import 'package:kutu_asset_picker/src/crop/widgets/crop_step_host.dart';
import 'package:kutu_asset_picker/src/config/picker_enums.dart';
import 'package:kutu_asset_picker/src/config/picker_tuning.dart';

late Directory workDir;

PickerAsset asset(String id) => PickerAsset(
      id: id,
      type: PickerMediaType.image,
      width: 1000,
      height: 500,
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

File sourceFile(String id) =>
    File('${workDir.path}/$id.src')..writeAsBytesSync(List<int>.filled(16, 1));

File outputFile(String srcPath) {
  final name = srcPath.split(Platform.pathSeparator).last;
  return File('${workDir.path}/$name.out')
    ..writeAsBytesSync(List<int>.filled(32, 2));
}

Future<ProviderContainer> pumpStep(
  WidgetTester tester, {
  required List<String> ids,
  VoidCallback? onBack,
  AssetPickerConfig config = const AssetPickerConfig(
    aspects: [CropAspect.square, CropAspect.landscape169],
  ),
  bool host = false,
}) async {
  final container = ProviderContainer(
    overrides: [
      assetPickerConfigProvider.overrideWithValue(config),
      assetSourceProvider.overrideWithValue(
        StubAssetSource(
          thumbnailBytes: tinyPngBytes(),
          files: {for (final id in ids) id: sourceFile(id)},
        ),
      ),
      mediaTransformProvider.overrideWithValue(
        RecordingMediaTransform(outputFor: outputFile),
      ),
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
        home: host
            ? CropStepHost(onBack: onBack ?? () {})
            : AssetCropStep(onBack: onBack ?? () {}),
      ),
    ),
  );
  await tester.pump();
  return container;
}

void main() {
  const text = AssetPickerTextEn();

  setUp(() => workDir = Directory.systemTemp.createTempSync('crop_step'));
  tearDown(() => workDir.deleteSync(recursive: true));

  testWidgets('assembles app bar, stage, chips and rail', (tester) async {
    await pumpStep(tester, ids: ['a', 'b']);

    expect(find.text(text.cropTitle), findsOneWidget);
    expect(find.byType(CropStage), findsOneWidget);
    expect(find.byType(CropViewport), findsOneWidget);
    expect(find.byType(CropDimmingMask), findsOneWidget);
    expect(find.byType(CropAspectChipRow), findsOneWidget);
    expect(find.byType(CropAssetRail), findsOneWidget);
  });

  testWidgets('the stage window matches the focused asset ratio', (
    tester,
  ) async {
    final container = await pumpStep(tester, ids: ['a']);

    final square =
        tester.widget<CropViewport>(find.byType(CropViewport)).window;
    expect(square.width, closeTo(square.height, 1e-6));

    container.read(cropStatesProvider.notifier).setAspect(
          'a',
          CropAspect.landscape169,
        );
    await tester.pump();

    final wide = tester.widget<CropViewport>(find.byType(CropViewport)).window;
    expect(wide.width / wide.height, closeTo(16 / 9, 1e-6));
  });

  testWidgets('Cancel calls back out without exporting', (tester) async {
    var backs = 0;
    final container = await pumpStep(tester, ids: ['a'], onBack: () => backs++);

    await tester.tap(find.text(text.pickerCancel));
    await tester.pump();

    expect(backs, 1);
    expect(container.read(exportControllerProvider), isA<ExportIdle>());
  });

  testWidgets('Done runs the export and reports progress in the label', (
    tester,
  ) async {
    final container = await pumpStep(tester, ids: ['a', 'b']);

    await tester.tap(find.text(text.pickerDone));
    await tester.pump();

    // Mid-flight the label becomes the counter and the button is disabled, so a
    // second tap cannot start a second batch.
    expect(container.read(exportControllerProvider), isA<ExportRunning>());

    // The queue alternates the transform's fake-clock yield ticks with real
    // file I/O (`out.length()`), so it needs both clocks turned, a few times.
    for (var round = 0;
        round < 8 && container.read(exportControllerProvider) is ExportRunning;
        round += 1) {
      await tester.pumpAndSettle();
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 20)),
      );
    }
    await tester.pumpAndSettle();

    final terminal = container.read(exportControllerProvider);
    expect(terminal, isA<ExportSucceeded>());
    expect((terminal as ExportSucceeded).result.assets, hasLength(2));
  });

  testWidgets('an empty selection renders nothing rather than throwing', (
    tester,
  ) async {
    await pumpStep(tester, ids: const []);

    expect(find.byType(CropViewport), findsNothing);
    expect(tester.takeException(), isNull);
  });

  group('CropStepHost honours config.cropSurface', () {
    testWidgets('page gives the crop step a full-screen scaffold', (
      tester,
    ) async {
      await pumpStep(
        tester,
        ids: ['a'],
        host: true,
        config: const AssetPickerConfig(
          aspects: [CropAspect.square],
          cropSurface: PickerSurface.page,
        ),
      );

      expect(find.byType(AssetCropStep), findsOneWidget);
      expect(find.byType(FractionallySizedBox), findsNothing);
      final Size size = tester.getSize(find.byType(AssetCropStep).first);
      expect(
          size.height,
          closeTo(
              tester.view.physicalSize.height / tester.view.devicePixelRatio,
              1));
    });

    testWidgets('sheet shapes it as a bottom panel, not full bleed', (
      tester,
    ) async {
      // The dead-config bug this pins: a consumer asking for
      // `pickerSurface: sheet, cropSurface: page` — or the reverse — used to
      // get whichever one pickerSurface named, for both steps (spec §2.6).
      await pumpStep(
        tester,
        ids: ['a'],
        host: true,
        config: const AssetPickerConfig(
          aspects: [CropAspect.square],
          cropSurface: PickerSurface.sheet,
        ),
      );

      expect(find.byType(AssetCropStep), findsOneWidget);
      expect(find.byType(FractionallySizedBox), findsOneWidget);
      final Size size = tester.getSize(find.byType(AssetCropStep).first);
      final double screen =
          tester.view.physicalSize.height / tester.view.devicePixelRatio;
      expect(size.height, lessThan(screen));
      expect(
        size.height,
        closeTo(screen * PickerChromeSizes.sheetInitialExtent, 1),
      );
    });

    testWidgets('cropSurface is read independently of pickerSurface', (
      tester,
    ) async {
      await pumpStep(
        tester,
        ids: ['a'],
        host: true,
        config: const AssetPickerConfig(
          aspects: [CropAspect.square],
          pickerSurface: PickerSurface.sheet,
          cropSurface: PickerSurface.page,
        ),
      );

      // pickerSurface says sheet; the crop step must still be a page.
      expect(find.byType(FractionallySizedBox), findsNothing);
    });
  });
}
