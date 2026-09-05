import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/src/config/asset_picker_config.dart';
import 'package:kutu_asset_picker/src/config/crop_aspect.dart';
import 'package:kutu_asset_picker/src/crop/crop_math.dart';
import 'package:kutu_asset_picker/src/crop/crop_providers.dart';
import 'package:kutu_asset_picker/src/crop/crop_state.dart';
import 'package:kutu_asset_picker/src/providers/asset_page_provider.dart';
import 'package:kutu_asset_picker/src/providers/selection_provider.dart';
import 'package:kutu_asset_picker/src/providers/injection_providers.dart';
import 'package:kutu_asset_picker/src/source/picker_asset.dart';
import 'package:kutu_asset_picker/src/source/picker_media_type.dart';

PickerAsset asset(String id, {int width = 1000, int height = 1000}) =>
    PickerAsset(
      id: id,
      type: PickerMediaType.image,
      width: width,
      height: height,
      createdAt: DateTime.utc(2026, 8, 4),
    );

/// Slice 3's paged list, pinned to a fixed page so the crop providers can be
/// exercised without a gallery.
class _FixedAssetPage extends AssetPage {
  _FixedAssetPage(this.assets);

  final List<PickerAsset> assets;

  @override
  Future<List<PickerAsset>> build() async => assets;
}

/// The real `Selection` from slice 3, driven the way a grid cell drives it.
///
/// `selectionProvider` is deliberately **not** overridden: `Selection` is the
/// single registry of what the author picked, and `selectedAssetsProvider` is a
/// projection of it. Substituting a fake here would test the projection against
/// a registry that does not exist in production.
ProviderContainer harness({
  required List<PickerAsset> page,
  required List<String> selected,
  AssetPickerConfig config = const AssetPickerConfig(),
  List<PickerAsset> known = const <PickerAsset>[],
}) {
  final container = ProviderContainer(
    overrides: [
      assetPickerConfigProvider.overrideWithValue(config),
      assetPageProvider.overrideWith(() => _FixedAssetPage(page)),
    ],
  );
  final selection = container.read(selectionProvider.notifier);
  for (final id in selected) {
    for (final asset in [...page, ...known]) {
      if (asset.id == id) {
        selection.toggleAsset(asset);
        break;
      }
    }
  }
  return container;
}

void main() {
  group('selectedAssetsProvider', () {
    test('projects Selection.selectedAssets, in selection order', () async {
      final container = harness(
        page: [asset('a'), asset('b'), asset('c')],
        selected: ['c', 'a'],
      );
      addTearDown(container.dispose);
      await container.read(assetPageProvider.future);

      expect(
        container.read(selectedAssetsProvider).map((a) => a.id).toList(),
        ['c', 'a'],
      );
    });

    test('an asset the current page no longer holds survives', () async {
      // AssetPage only holds the *current* album. A user who selects from
      // Camera, switches to Screenshots and presses Next must still get their
      // Camera asset — which works because `Selection` captured the asset at
      // tap time rather than looking it up in the page later.
      final container = harness(
        page: const <PickerAsset>[],
        known: [asset('camera-1', width: 4000, height: 3000)],
        selected: ['camera-1'],
      );
      addTearDown(container.dispose);
      await container.read(assetPageProvider.future);

      final selected = container.read(selectedAssetsProvider);
      expect(selected.map((a) => a.id), ['camera-1']);
      expect(selected.single.width, 4000);
    });

    test('rebuilds when the selection order changes', () async {
      final container = harness(
        page: [asset('a'), asset('b')],
        selected: ['a', 'b'],
      );
      addTearDown(container.dispose);
      await container.read(assetPageProvider.future);
      expect(
          container.read(selectedAssetsProvider).map((a) => a.id), ['a', 'b']);

      container.read(selectionProvider.notifier).reorder(1, 0);

      // Watching `selectionProvider.notifier` alone would not do this: the
      // notifier is a stable object, so only the id list changing is
      // observable.
      expect(
          container.read(selectedAssetsProvider).map((a) => a.id), ['b', 'a']);
    });
  });

  group('CropStates', () {
    test('an untouched asset reports the config initial aspect, unsized',
        () async {
      final container = harness(
        page: [asset('a')],
        selected: ['a'],
        config: const AssetPickerConfig(
          aspects: [CropAspect.story916, CropAspect.square],
        ),
      );
      addTearDown(container.dispose);
      await container.read(assetPageProvider.future);

      final state = container.read(cropStatesProvider.notifier).stateOf('a');

      expect(state.aspect, CropAspect.story916);
      expect(state.isUnsized, isTrue);
    });

    test('framing one asset does not disturb another', () async {
      final container = harness(
        page: [asset('a'), asset('b')],
        selected: ['a', 'b'],
      );
      addTearDown(container.dispose);
      await container.read(assetPageProvider.future);
      final states = container.read(cropStatesProvider.notifier);

      states.update(
        'a',
        const CropState(
          aspect: CropAspect.square,
          scale: 2,
          offset: Offset(120, -30),
        ),
      );

      expect(states.stateOf('a').scale, 2);
      expect(states.stateOf('a').offset, const Offset(120, -30));
      expect(states.stateOf('b').isUnsized, isTrue);
    });

    test('setAspect runs rule 3 against the NEW window', () async {
      final container = harness(page: [asset('a')], selected: ['a']);
      addTearDown(container.dispose);
      await container.read(assetPageProvider.future);
      final states = container.read(cropStatesProvider.notifier);

      // A 1000x1000 source at cover scale in the canonical 1:1 window.
      states.update(
        'a',
        const CropState(
          aspect: CropAspect.square,
          scale: 1,
          offset: Offset.zero,
        ),
      );

      states.setAspect('a', CropAspect.story916);

      final next = states.stateOf('a');
      expect(next.aspect, CropAspect.story916);
      // The 9:16 canonical window is 562.5x1000, so a 1000x1000 source at
      // scale 1 still covers it and the scale is untouched.
      expect(next.scale, closeTo(1, 1e-12));
      final rect = toCropRect(
        next,
        const Size(1000, 1000),
        cropWindowSize(CropAspect.story916, kCanonicalCropArea),
      );
      expect(rect.isValid, isTrue);
      expect(rect.width, closeTo(0.5625, 1e-9));
    });

    test('setAspect raises the scale when the new window needs more', () async {
      final container = harness(
        page: [asset('a', width: 1000, height: 1000)],
        selected: ['a'],
      );
      addTearDown(container.dispose);
      await container.read(assetPageProvider.future);
      final states = container.read(cropStatesProvider.notifier);

      // Cover the 3:1 canonical window (1000x333.33) at scale 1, then switch to
      // 9:16 (562.5x1000): the source is now too short and must scale up.
      states.update(
        'a',
        const CropState(
          aspect: CropAspect.banner31,
          scale: 1,
          offset: Offset.zero,
        ),
      );

      states.setAspect('a', CropAspect.story916);

      expect(states.stateOf('a').scale, closeTo(1, 1e-12));
    });

    test('setAspect ignores an asset that is not selected', () async {
      final container = harness(page: [asset('a')], selected: ['a']);
      addTearDown(container.dispose);
      await container.read(assetPageProvider.future);
      final states = container.read(cropStatesProvider.notifier);

      states.setAspect('ghost', CropAspect.story916);

      expect(container.read(cropStatesProvider).containsKey('ghost'), isFalse);
    });

    test('applyAspectToAll copies the ASPECT and nothing else', () async {
      final container = harness(
        page: [
          asset('a', width: 2000, height: 1000),
          asset('b', width: 1000, height: 2000),
        ],
        selected: ['a', 'b'],
      );
      addTearDown(container.dispose);
      await container.read(assetPageProvider.future);
      final states = container.read(cropStatesProvider.notifier);

      states.update(
        'a',
        const CropState(
          aspect: CropAspect.square,
          scale: 2,
          offset: Offset(300, 0),
        ),
      );
      states.update(
        'b',
        const CropState(
          aspect: CropAspect.portrait45,
          scale: 1,
          offset: Offset.zero,
        ),
      );

      states.applyAspectToAll(CropAspect.landscape169);

      expect(states.stateOf('a').aspect, CropAspect.landscape169);
      expect(states.stateOf('b').aspect, CropAspect.landscape169);
      // b keeps its OWN framing, re-clamped — pan and zoom are meaningless on a
      // different image and are never copied (spec §2.4).
      expect(states.stateOf('b').offset, Offset.zero);
      expect(states.stateOf('a').offset.dx, greaterThan(0));
      expect(states.stateOf('a').offset, isNot(states.stateOf('b').offset));
    });

    test('applyAspectToAll re-clamps every asset through rule 3', () async {
      final container = harness(
        page: [asset('a', width: 1000, height: 1000)],
        selected: ['a'],
      );
      addTearDown(container.dispose);
      await container.read(assetPageProvider.future);
      final states = container.read(cropStatesProvider.notifier);

      states.update(
        'a',
        const CropState(
          aspect: CropAspect.square,
          scale: 1,
          offset: Offset(400, 400),
        ),
      );

      states.applyAspectToAll(CropAspect.square);

      // At scale 1 in a 1000x1000 window there is no slack at all, so a pan of
      // 400 is pulled back to zero rather than being trusted.
      expect(states.stateOf('a').offset, Offset.zero);
    });
  });

  group('FocusedAsset', () {
    test('starts null and remembers what it is told', () {
      final container = harness(page: const [], selected: const []);
      addTearDown(container.dispose);

      expect(container.read(focusedAssetProvider), isNull);

      container.read(focusedAssetProvider.notifier).focus('b');

      expect(container.read(focusedAssetProvider), 'b');
    });

    test('does not reset when the page reloads', () async {
      // Deriving the default inside build() would make the focus jump back to
      // the first asset every time the grid paged in more.
      final container =
          harness(page: [asset('a'), asset('b')], selected: ['a', 'b']);
      addTearDown(container.dispose);
      await container.read(assetPageProvider.future);

      container.read(focusedAssetProvider.notifier).focus('b');
      container.invalidate(assetPageProvider);
      await container.read(assetPageProvider.future);

      expect(container.read(focusedAssetProvider), 'b');
    });
  });

  group('CropInteraction', () {
    test('flips while a gesture is in flight', () {
      final container = harness(page: const [], selected: const []);
      addTearDown(container.dispose);

      expect(container.read(cropInteractionProvider), isFalse);

      container.read(cropInteractionProvider.notifier).begin();
      expect(container.read(cropInteractionProvider), isTrue);

      container.read(cropInteractionProvider.notifier).end();
      expect(container.read(cropInteractionProvider), isFalse);
    });
  });
}
