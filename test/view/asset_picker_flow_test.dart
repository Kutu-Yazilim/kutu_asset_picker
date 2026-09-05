import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/src/config/asset_picker_config.dart';
import 'package:kutu_asset_picker/src/config/crop_aspect.dart';
import 'package:kutu_asset_picker/src/config/picker_enums.dart';
import 'package:kutu_asset_picker/src/crop/widgets/asset_crop_step.dart';
import 'package:kutu_asset_picker/src/export/export_cache.dart';
import 'package:kutu_asset_picker/src/export/export_controller.dart';
import 'package:kutu_asset_picker/src/export/export_progress.dart';
import 'package:kutu_asset_picker/src/picker/asset_picker_view.dart';
import 'package:kutu_asset_picker/src/providers/asset_page_provider.dart';
import 'package:kutu_asset_picker/src/providers/injection_providers.dart';
import 'package:kutu_asset_picker/src/providers/selection_provider.dart';
import 'package:kutu_asset_picker/src/result/asset_picker_result.dart';
import 'package:kutu_asset_picker/src/source/picker_asset.dart';
import 'package:kutu_asset_picker/src/source/picker_media_type.dart';
import 'package:kutu_asset_picker/src/text/asset_picker_text_tr.dart';
import 'package:kutu_asset_picker/src/view/asset_picker_scope.dart';
import 'package:kutu_asset_picker/src/view/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/view/picker_step_controller.dart';

import '../support/recording_media_transform.dart';
import '../support/stub_asset_source.dart';
import '../support/tiny_png.dart';
import 'package:kutu_asset_picker/src/theme/asset_picker_theme.dart';

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

ProviderContainer container({
  required List<String> ids,
  AssetPickerConfig config = const AssetPickerConfig(
    aspects: [CropAspect.square],
  ),
}) =>
    ProviderContainer(
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

void main() {
  setUp(() {
    workDir = Directory.systemTemp.createTempSync('picker_view');
    ExportCache.reset();
  });
  tearDown(() {
    if (workDir.existsSync()) workDir.deleteSync(recursive: true);
    ExportCache.reset();
  });

  group('PickerStepController', () {
    test('starts on the grid and advances to crop', () async {
      final scope = container(ids: ['a']);
      addTearDown(scope.dispose);
      await scope.read(assetPageProvider.future);

      expect(scope.read(pickerStepControllerProvider), AssetPickerStep.grid);

      scope.read(pickerStepControllerProvider.notifier).next();

      expect(scope.read(pickerStepControllerProvider), AssetPickerStep.crop);
    });

    test('enableCrop false skips the step and exports immediately', () async {
      // The source still goes through the transform seam, so what comes back is
      // a renderable JPEG rather than an HEIC nothing can draw (spec §7.5).
      final scope = container(
        ids: ['a'],
        config: const AssetPickerConfig(
          enableCrop: false,
          aspects: [CropAspect.square],
        ),
      );
      addTearDown(scope.dispose);
      await scope.read(assetPageProvider.future);
      final done = Completer<void>();
      scope.listen(exportControllerProvider, (_, next) {
        if (next is ExportSucceeded && !done.isCompleted) done.complete();
      });

      scope.read(pickerStepControllerProvider.notifier).next();
      await done.future;

      expect(scope.read(pickerStepControllerProvider), AssetPickerStep.grid);
      final terminal = scope.read(exportControllerProvider) as ExportSucceeded;
      expect(terminal.result.assets.single.mimeType, 'image/jpeg');
    });

    test('back returns to the grid', () async {
      final scope = container(ids: ['a']);
      addTearDown(scope.dispose);
      await scope.read(assetPageProvider.future);

      scope.read(pickerStepControllerProvider.notifier).next();
      scope.read(pickerStepControllerProvider.notifier).back();

      expect(scope.read(pickerStepControllerProvider), AssetPickerStep.grid);
    });
  });

  group('AssetPickerView', () {
    testWidgets('shows the crop step once the step advances', (tester) async {
      final scope = container(ids: ['a']);
      addTearDown(scope.dispose);
      await scope.read(assetPageProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: scope,
          child: MaterialApp(home: AssetPickerView(onCompleted: (_) {})),
        ),
      );
      await tester.pump();
      expect(find.byType(AssetCropStep), findsNothing);

      scope.read(pickerStepControllerProvider.notifier).next();
      await tester.pump();

      expect(find.byType(AssetCropStep), findsOneWidget);
    });

    testWidgets('delivers the result through onCompleted', (tester) async {
      final scope = container(ids: ['a']);
      addTearDown(scope.dispose);
      await scope.read(assetPageProvider.future);
      AssetPickerResult? delivered;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: scope,
          child: MaterialApp(
            home: AssetPickerView(onCompleted: (result) => delivered = result),
          ),
        ),
      );
      scope.read(pickerStepControllerProvider.notifier).next();
      await tester.pump();

      // The queue does real file I/O, which never settles under FakeAsync.
      await tester.runAsync(scope.read(exportControllerProvider.notifier).run);
      await tester.pump();

      expect(delivered?.assets, hasLength(1));
    });

    testWidgets('an explicit text delegate wins over the ambient locale', (
      tester,
    ) async {
      final scope = container(ids: ['a']);
      addTearDown(scope.dispose);
      await scope.read(assetPageProvider.future);
      scope.read(pickerStepControllerProvider.notifier).next();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: scope,
          child: MaterialApp(
            locale: const Locale('en'),
            home: AssetPickerView(
              onCompleted: (_) {},
              text: const AssetPickerTextTr(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(const AssetPickerTextTr().cropTitle), findsOneWidget);
    });

    testWidgets('AN EXPLICIT text DELEGATE ALSO REACHES THE GRID STEP', (
      tester,
    ) async {
      // The regression this pins: the crop widgets read `context.pickerText`
      // while slice 3's chrome read a Riverpod provider, so `text:` restyled
      // the crop step and left the whole grid screen in English — silently,
      // with every crop test green.
      final scope = container(ids: ['a']);
      addTearDown(scope.dispose);
      await scope.read(assetPageProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: scope,
          child: MaterialApp(
            locale: const Locale('en'),
            home: AssetPickerView(
              onCompleted: (_) {},
              text: const AssetPickerTextTr(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // PickerAppBar's cancel affordance is a tooltip, so this asserts the
      // delegate reached a slice 3 widget rather than a slice 4 one.
      expect(
        find.byTooltip(const AssetPickerTextTr().pickerCancel),
        findsOneWidget,
      );
    });

    testWidgets('AN EXPLICIT theme ALSO REACHES THE GRID STEP', (
      tester,
    ) async {
      const Color scarlet = Color(0xFFB00020);
      final scope = container(ids: ['a']);
      addTearDown(scope.dispose);
      await scope.read(assetPageProvider.future);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: scope,
          child: MaterialApp(
            home: AssetPickerView(
              onCompleted: (_) {},
              theme: const AssetPickerTheme(background: scarlet),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Scaffold page = tester.widget<Scaffold>(
        find.byType(Scaffold).first,
      );
      expect(page.backgroundColor, scarlet);
    });
  });

  group('KutuAssetPicker.show', () {
    testWidgets('pushes a page surface and resolves with the popped result', (
      tester,
    ) async {
      // The embeddable widget is the real implementation and this is a thin
      // wrapper. Owning Navigator.push and making the selection the route
      // result is the most cited structural complaint about
      // wechat_assets_picker (spec §3.3) — so the wrapper is opt-in.
      Future<AssetPickerResult?>? pending;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => pending = KutuAssetPicker.show(
                context,
                config: const AssetPickerConfig(
                  aspects: [CropAspect.square],
                ),
                source: StubAssetSource(thumbnailBytes: tinyPngBytes()),
                transform: RecordingMediaTransform(outputFor: outputFile),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(AssetPickerScope), findsOneWidget);

      const popped = AssetPickerResult(assets: []);
      Navigator.of(tester.element(find.byType(AssetPickerScope))).pop(popped);
      await tester.pumpAndSettle();

      expect(await pending, same(popped));
    });

    testWidgets('a sheet surface presents a modal bottom sheet', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => KutuAssetPicker.show(
                context,
                config: const AssetPickerConfig(
                  pickerSurface: PickerSurface.sheet,
                  aspects: [CropAspect.square],
                ),
                source: StubAssetSource(thumbnailBytes: tinyPngBytes()),
                transform: RecordingMediaTransform(outputFor: outputFile),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(AssetPickerScope), findsOneWidget);
    });
  });

  group('KutuAssetPicker.clearCache', () {
    test('deletes what a finished batch left behind', () async {
      // Spec §3.4: the package writes exports into a namespaced temp directory
      // and the consumer owns those files, but iOS caches asset files into the
      // app container and nothing else ever collects them.
      final scope = container(ids: ['a', 'b']);
      addTearDown(scope.dispose);
      await scope.read(assetPageProvider.future);

      final result = await scope.read(exportControllerProvider.notifier).run();
      expect(result.assets, hasLength(2));
      for (final picked in result.assets) {
        expect(picked.file.existsSync(), isTrue);
      }

      await KutuAssetPicker.clearCache();

      for (final picked in result.assets) {
        expect(picked.file.existsSync(), isFalse);
      }
    });

    test('is safe to call when nothing has been exported', () async {
      await expectLater(KutuAssetPicker.clearCache(), completes);
    });
  });
}
