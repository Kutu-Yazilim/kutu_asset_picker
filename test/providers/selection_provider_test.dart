import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/testing.dart';

PickerAsset _image(String id) => PickerAsset(
      id: id,
      type: PickerMediaType.image,
      width: 100,
      height: 100,
      createdAt: DateTime.utc(2026, 8, 4),
    );

ProviderContainer _container({
  AssetPickerConfig config = const AssetPickerConfig(),
}) {
  final FakeAssetSource source = FakeAssetSource();
  addTearDown(source.dispose);
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      assetPickerConfigProvider.overrideWithValue(config),
      assetSourceProvider.overrideWithValue(source),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('starts empty', () {
    final ProviderContainer container = _container();
    expect(container.read(selectionProvider), isEmpty);
  });

  test('toggle adds then removes, preserving order', () {
    final ProviderContainer container = _container();
    final Selection selection = container.read(selectionProvider.notifier);

    selection
      ..toggle('a')
      ..toggle('b')
      ..toggle('c');
    expect(container.read(selectionProvider), <String>['a', 'b', 'c']);

    selection.toggle('b');
    expect(container.read(selectionProvider), <String>['a', 'c']);
  });

  test('selectionIndex is 1-based and 0 when unselected', () {
    final ProviderContainer container = _container();
    container.read(selectionProvider.notifier)
      ..toggle('a')
      ..toggle('b');

    expect(container.read(selectionIndexProvider('a')), 1);
    expect(container.read(selectionIndexProvider('b')), 2);
    expect(container.read(selectionIndexProvider('never')), 0);
  });

  test('deselecting renumbers everything after it', () {
    final ProviderContainer container = _container();
    container.read(selectionProvider.notifier)
      ..toggle('a')
      ..toggle('b')
      ..toggle('c');

    container.read(selectionProvider.notifier).toggle('a');

    expect(container.read(selectionIndexProvider('b')), 1);
    expect(container.read(selectionIndexProvider('c')), 2);
  });

  test('the cap is enforced and reported', () {
    final ProviderContainer container =
        _container(config: const AssetPickerConfig(maxSelection: 2));
    final Selection selection = container.read(selectionProvider.notifier);

    selection.toggle('a');
    expect(container.read(selectionCapReachedProvider), isFalse);
    expect(selection.canSelectMore(), isTrue);

    selection.toggle('b');
    expect(container.read(selectionCapReachedProvider), isTrue);
    expect(selection.canSelectMore(), isFalse);

    selection.toggle('c');
    expect(container.read(selectionProvider), <String>['a', 'b'],
        reason: 'a tap past the cap must be inert, not silently drop an '
            'earlier pick');

    // Deselecting frees a slot again.
    selection.toggle('a');
    expect(container.read(selectionCapReachedProvider), isFalse);
  });

  test('reorder follows ReorderableListView index semantics', () {
    final ProviderContainer container = _container();
    final Selection selection = container.read(selectionProvider.notifier);
    selection
      ..toggle('a')
      ..toggle('b')
      ..toggle('c');

    // "Move a to before index 2" lands it at index 1.
    selection.reorder(0, 2);
    expect(container.read(selectionProvider), <String>['b', 'a', 'c']);

    // Moving backwards needs no adjustment.
    selection.reorder(2, 0);
    expect(container.read(selectionProvider), <String>['c', 'b', 'a']);
  });

  test('reorder ignores out-of-range indices instead of throwing', () {
    final ProviderContainer container = _container();
    container.read(selectionProvider.notifier).toggle('a');

    container.read(selectionProvider.notifier).reorder(5, 0);
    container.read(selectionProvider.notifier).reorder(0, 99);

    expect(container.read(selectionProvider), <String>['a']);
  });

  test('selectedAssets survives an album switch', () {
    // AssetPage only holds the CURRENT album. Selecting from Camera, switching
    // to Screenshots and pressing Next must still yield the Camera asset.
    final ProviderContainer container = _container();
    final Selection selection = container.read(selectionProvider.notifier);

    selection
      ..toggleAsset(_image('cam-1'))
      ..toggleAsset(_image('shot-1'));

    expect(
      selection.selectedAssets.map((PickerAsset a) => a.id),
      <String>['cam-1', 'shot-1'],
    );
  });

  test('selectedAssets follows the reordered selection order', () {
    final ProviderContainer container = _container();
    final Selection selection = container.read(selectionProvider.notifier);
    selection
      ..toggleAsset(_image('a'))
      ..toggleAsset(_image('b'))
      ..reorder(1, 0);

    expect(
      selection.selectedAssets.map((PickerAsset a) => a.id),
      <String>['b', 'a'],
    );
  });

  test('TOGGLING ONE ASSET NOTIFIES ONLY THAT ASSET\'S CELL', () async {
    // Contract §9: selectionIndexProvider(assetId) IS the rebuild-granularity
    // mechanism. A grid cell watches THAT and nothing else, so toggling one
    // asset rebuilds one cell — a 1000-cell grid does not repaint because the
    // user tapped a thumbnail.
    //
    // Riverpod only notifies a listener when the computed value CHANGES, and
    // selectionIndexProvider('b') stays 0 while 'a' goes 0 -> 1. A listener
    // notification is precisely "this cell would rebuild".
    final ProviderContainer container = _container();

    int aRebuilds = 0;
    int bRebuilds = 0;
    int cRebuilds = 0;
    container.listen<int>(
      selectionIndexProvider('a'),
      (int? _, int __) => aRebuilds += 1,
    );
    container.listen<int>(
      selectionIndexProvider('b'),
      (int? _, int __) => bRebuilds += 1,
    );
    container.listen<int>(
      selectionIndexProvider('c'),
      (int? _, int __) => cRebuilds += 1,
    );

    container.read(selectionProvider.notifier).toggle('a');
    await container.pump();

    expect(aRebuilds, 1, reason: 'the tapped cell rebuilds');
    expect(bRebuilds, 0, reason: 'every other cell must NOT rebuild');
    expect(cRebuilds, 0);
  });

  test('deselecting notifies only the cells whose number actually moved',
      () async {
    final ProviderContainer container = _container();
    final Selection selection = container.read(selectionProvider.notifier);
    selection
      ..toggle('a')
      ..toggle('b');

    int aRebuilds = 0;
    int bRebuilds = 0;
    int idleRebuilds = 0;
    container.listen<int>(
      selectionIndexProvider('a'),
      (int? _, int __) => aRebuilds += 1,
    );
    container.listen<int>(
      selectionIndexProvider('b'),
      (int? _, int __) => bRebuilds += 1,
    );
    container.listen<int>(
      selectionIndexProvider('idle'),
      (int? _, int __) => idleRebuilds += 1,
    );

    selection.toggle('a');
    await container.pump();

    expect(aRebuilds, 1, reason: '1 -> 0');
    expect(bRebuilds, 1, reason: '2 -> 1, the badge number really did change');
    expect(idleRebuilds, 0, reason: 'unselected cells stay at 0 and stay put');
  });
}
