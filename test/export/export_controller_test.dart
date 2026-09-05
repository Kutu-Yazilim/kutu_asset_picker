import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/src/config/asset_picker_config.dart';
import 'package:kutu_asset_picker/src/config/crop_aspect.dart';
import 'package:kutu_asset_picker/src/crop/crop_providers.dart';
import 'package:kutu_asset_picker/src/crop/crop_state.dart';
import 'package:kutu_asset_picker/src/export/export_controller.dart';
import 'package:kutu_asset_picker/src/export/export_progress.dart';
import 'package:kutu_asset_picker/src/providers/asset_page_provider.dart';
import 'package:kutu_asset_picker/src/providers/selection_provider.dart';
import 'package:kutu_asset_picker/src/providers/injection_providers.dart';
import 'package:kutu_asset_picker/src/source/picker_asset.dart';
import 'package:kutu_asset_picker/src/source/picker_media_type.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

import '../support/recording_media_transform.dart';
import '../support/stub_asset_source.dart';

late Directory workDir;

PickerAsset image(String id) => PickerAsset(
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
  List<PickerAsset> get selectedAssets => [for (final id in ids) image(id)];
}

File sourceFile(String id) =>
    File('${workDir.path}/$id.src')..writeAsBytesSync(List<int>.filled(32, 3));

File outputFile(String srcPath) {
  final name = srcPath.split(Platform.pathSeparator).last;
  return File('${workDir.path}/$name.out')
    ..writeAsBytesSync(List<int>.filled(64, 4));
}

void main() {
  setUp(() => workDir = Directory.systemTemp.createTempSync('export_ctrl'));
  tearDown(() => workDir.deleteSync(recursive: true));

  Future<ProviderContainer> harness({
    required List<String> ids,
    Map<String, TransformFailure> failures = const {},
    Map<String, File>? files,
    AssetPickerConfig config = const AssetPickerConfig(),
  }) async {
    final assets = [for (final id in ids) image(id)];
    final sources = files ?? {for (final id in ids) id: sourceFile(id)};
    final container = ProviderContainer(
      overrides: [
        assetPickerConfigProvider.overrideWithValue(config),
        assetSourceProvider.overrideWithValue(StubAssetSource(files: sources)),
        mediaTransformProvider.overrideWithValue(
          RecordingMediaTransform(outputFor: outputFile, failFor: failures),
        ),
        assetPageProvider.overrideWith(() => _FixedAssetPage(assets)),
        selectionProvider.overrideWith(() => _FixedSelection(ids)),
      ],
    );
    addTearDown(container.dispose);
    await container.read(assetPageProvider.future);
    return container;
  }

  test('starts idle', () async {
    final container = await harness(ids: ['a']);

    expect(container.read(exportControllerProvider), isA<ExportIdle>());
  });

  test('reports running progress and ends in ExportSucceeded', () async {
    final container = await harness(ids: ['a', 'b']);
    final seen = <ExportProgress>[];
    container.listen(exportControllerProvider, (_, next) => seen.add(next));

    final result =
        await container.read(exportControllerProvider.notifier).run();

    expect(result.assets, hasLength(2));
    expect(seen.whereType<ExportRunning>(), isNotEmpty);
    expect(seen.last, isA<ExportSucceeded>());
    expect((seen.last as ExportSucceeded).result.assets, hasLength(2));
    expect((seen.last as ExportSucceeded).failures, isEmpty);
  });

  test('honours each asset own crop state', () async {
    final container = await harness(ids: ['a', 'b']);
    container.read(cropStatesProvider.notifier).update(
          'a',
          const CropState(
            aspect: CropAspect.landscape169,
            scale: 2,
            offset: Offset.zero,
          ),
        );

    final result =
        await container.read(exportControllerProvider.notifier).run();

    expect(result.assets.first.aspectRatio, closeTo(16 / 9, 1e-12));
    // b was never touched, so it exports at the config's initial aspect.
    expect(result.assets.last.aspectRatio, closeTo(1, 1e-12));
  });

  test('one failing asset still succeeds, carrying the failure', () async {
    final sources = {'a': sourceFile('a'), 'b': sourceFile('b')};
    final container = await harness(
      ids: ['a', 'b'],
      files: sources,
      failures: {sources['b']!.path: TransformFailure.encoderFailed},
    );

    final result =
        await container.read(exportControllerProvider.notifier).run();
    final terminal = container.read(exportControllerProvider);

    expect(result.assets, hasLength(1));
    expect(terminal, isA<ExportSucceeded>());
    expect((terminal as ExportSucceeded).failures.single.assetId, 'b');
  });

  test('every asset failing is ExportFailed', () async {
    final container = await harness(ids: ['a'], files: const {});

    await container.read(exportControllerProvider.notifier).run();

    final terminal = container.read(exportControllerProvider);
    expect(terminal, isA<ExportFailed>());
    expect((terminal as ExportFailed).failures.single.assetId, 'a');
  });

  test('cancel stops the batch and reports ExportFailed', () async {
    final container = await harness(ids: ['a', 'b', 'c']);
    final notifier = container.read(exportControllerProvider.notifier);
    container.listen(exportControllerProvider, (_, next) {
      if (next is ExportRunning && next.done == 1) notifier.cancel();
    });

    await notifier.run();

    expect(container.read(exportControllerProvider), isA<ExportFailed>());
  });

  test('run never throws, so a fire-and-forget button is safe', () async {
    // Flutter rule 9 forbids `await` in UI, so the Done button calls run() and
    // walks away. An escaping exception would land in the zone as an unhandled
    // error with no UI anywhere to show it.
    //
    // The provoked fault is a source file that is not there — the id resolves
    // to no file at all, which is what an evicted iCloud asset looks like.
    // (An empty `aspects` list cannot be used to provoke it: slice 3's
    // constructor asserts `aspects.length > 0`, and a failing assert in a const
    // expression is a compile error, not a runtime one.)
    final container = await harness(ids: ['a'], files: const <String, File>{});

    await expectLater(
      container.read(exportControllerProvider.notifier).run(),
      completes,
    );
    expect(container.read(exportControllerProvider), isA<ExportFailed>());
  });
}
