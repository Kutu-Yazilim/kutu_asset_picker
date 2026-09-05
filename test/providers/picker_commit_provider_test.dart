import 'dart:io';

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

ProviderContainer _container(FakeAssetSource source) {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      assetPickerConfigProvider.overrideWithValue(const AssetPickerConfig()),
      assetSourceProvider.overrideWithValue(source),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('an all-local selection hands over without a single download', () async {
    final FakeAssetSource source = FakeAssetSource();
    addTearDown(source.dispose);
    final ProviderContainer container = _container(source);
    container.read(selectionProvider.notifier)
      ..toggleAsset(_image('a'))
      ..toggleAsset(_image('b'));

    bool ready = false;
    await container
        .read(pickerCommitProvider.notifier)
        .commit(onReady: () => ready = true);

    expect(ready, isTrue);
    expect(
      container.read(pickerCommitProvider).byAsset.values,
      everyElement(const AssetReady()),
    );
    expect(container.read(pickerCommitProvider).progress, 1);
    expect(container.read(pickerCommitProvider).running, isFalse);
  });

  test('a cloud-only asset reports per-asset progress while it downloads',
      () async {
    final FakeAssetSource source = FakeAssetSource();
    addTearDown(source.dispose);
    source.locallyUnavailable.add('cloud');
    source.pendingFiles.add('cloud');

    final ProviderContainer container = _container(source);
    container.read(selectionProvider.notifier).toggleAsset(_image('cloud'));

    bool ready = false;
    final Future<void> run = container
        .read(pickerCommitProvider.notifier)
        .commit(onReady: () => ready = true);
    await _flush();

    expect(container.read(pickerCommitProvider).running, isTrue);

    source.emitFileProgress('cloud', 0.4);
    expect(container.read(pickerCommitProvider).byAsset['cloud'],
        const AssetDownloading(0.4));
    expect(container.read(pickerCommitProvider).progress, closeTo(0.4, 1e-9));
    expect(ready, isFalse);

    source.completeFile('cloud', File('/fake/cloud'));
    await run;

    expect(ready, isTrue);
    expect(container.read(pickerCommitProvider).running, isFalse);
  });

  test('ONE SLOW ASSET NEVER BLOCKS THE BATCH', () async {
    // design §4.5. Exports are strictly sequential because they are CPU work;
    // these are network waits, and serialising them would make a five-item
    // selection wait for the sum of five downloads instead of the slowest one.
    final FakeAssetSource source = FakeAssetSource();
    addTearDown(source.dispose);
    source.locallyUnavailable.addAll(<String>{'fast', 'slow'});
    source.pendingFiles.add('slow');

    final ProviderContainer container = _container(source);
    container.read(selectionProvider.notifier)
      ..toggleAsset(_image('fast'))
      ..toggleAsset(_image('slow'));

    bool ready = false;
    final Future<void> run = container
        .read(pickerCommitProvider.notifier)
        .commit(onReady: () => ready = true);
    await _flush();

    expect(container.read(pickerCommitProvider).byAsset['fast'],
        const AssetReady(),
        reason: 'the fast asset resolved on its own, behind nobody');
    expect(container.read(pickerCommitProvider).byAsset['slow'],
        isA<AssetDownloading>());
    expect(ready, isFalse, reason: 'the batch is not ready until all of it is');

    source.completeFile('slow', File('/fake/slow'));
    await run;

    expect(ready, isTrue);
  });

  test('a failed asset is a per-asset failure, not a batch failure', () async {
    final FakeAssetSource source = FakeAssetSource();
    addTearDown(source.dispose);
    source.locallyUnavailable.addAll(<String>{'good', 'bad'});
    source.failingFiles.add('bad');

    final ProviderContainer container = _container(source);
    container.read(selectionProvider.notifier)
      ..toggleAsset(_image('good'))
      ..toggleAsset(_image('bad'));

    bool ready = false;
    await container
        .read(pickerCommitProvider.notifier)
        .commit(onReady: () => ready = true);

    expect(ready, isFalse, reason: 'Next must not fire on a partial batch');
    expect(container.read(pickerCommitProvider).failed, <String>['bad']);
    expect(container.read(pickerCommitProvider).byAsset['good'],
        const AssetReady());
    expect(container.read(pickerCommitProvider).hasFailures, isTrue);
    expect(container.read(pickerCommitProvider).running, isFalse,
        reason: 'the failure state survives the run so the bar can offer '
            'Retry instead of vanishing');
  });

  test('retry re-runs the pre-flight and hands over when it succeeds',
      () async {
    final FakeAssetSource source = FakeAssetSource();
    addTearDown(source.dispose);
    source.locallyUnavailable.add('flaky');
    source.failingFiles.add('flaky');

    final ProviderContainer container = _container(source);
    container.read(selectionProvider.notifier).toggleAsset(_image('flaky'));

    bool ready = false;
    await container
        .read(pickerCommitProvider.notifier)
        .commit(onReady: () => ready = true);
    expect(ready, isFalse);

    source.failingFiles.remove('flaky');
    await container.read(pickerCommitProvider.notifier).retry();

    expect(ready, isTrue);
    expect(container.read(pickerCommitProvider).hasFailures, isFalse);
  });

  test('cancel abandons the batch and leaves nothing running', () async {
    final FakeAssetSource source = FakeAssetSource();
    addTearDown(source.dispose);
    source.locallyUnavailable.add('slow');
    source.pendingFiles.add('slow');

    final ProviderContainer container = _container(source);
    container.read(selectionProvider.notifier).toggleAsset(_image('slow'));

    bool ready = false;
    final Future<void> run = container
        .read(pickerCommitProvider.notifier)
        .commit(onReady: () => ready = true);
    await _flush();
    expect(container.read(pickerCommitProvider).running, isTrue);

    container.read(pickerCommitProvider.notifier).cancel();
    // A real AssetSource aborts the platform download through the cancel token
    // it was handed; FakeAssetSource holds the future open until the test
    // releases it, which is what makes the late-completion path observable.
    source.completeFile('slow', null);
    await run;

    expect(ready, isFalse);
    expect(container.read(pickerCommitProvider).running, isFalse);
    expect(container.read(pickerCommitProvider).byAsset, isEmpty,
        reason: 'a late completion must not resurrect a cancelled batch');
  });

  test('an empty selection never calls onReady', () async {
    final FakeAssetSource source = FakeAssetSource();
    addTearDown(source.dispose);
    final ProviderContainer container = _container(source);

    bool ready = false;
    await container
        .read(pickerCommitProvider.notifier)
        .commit(onReady: () => ready = true);

    expect(ready, isFalse);
    expect(container.read(pickerCommitProvider).running, isFalse);
  });
}

/// Riverpod 3's `ProviderContainer.pump` only awaits the scheduler's pending
/// work; the pre-flight's own awaits need a real event-loop turn to settle.
Future<void> _flush() => Future<void>.delayed(Duration.zero);
