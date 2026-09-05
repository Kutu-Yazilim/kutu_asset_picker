import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/picker/cloud_progress_bar.dart';

import '../support/pump_picker.dart';

void main() {
  testWidgets('an idle pre-flight renders nothing at all',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(1));
    addTearDown(source.dispose);

    await pumpPicker(tester, const CloudProgressBar(), source: source);

    expect(find.byType(Text), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('a running pre-flight shows the copy, the progress and a cancel',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(1));
    addTearDown(source.dispose);
    source.locallyUnavailable.add('a0');
    source.pendingFiles.add('a0');

    final ProviderContainer container =
        await pumpPicker(tester, const CloudProgressBar(), source: source);
    container.read(selectionProvider.notifier).toggleAsset(testAsset('a0'));
    container.read(pickerCommitProvider.notifier).commit(onReady: () {});
    await tester.pump();

    source.emitFileProgress('a0', 0.25);
    await tester.pump();

    expect(find.text(en.pickerDownloadingFromCloud), findsOneWidget);
    expect(
      tester
          .widget<LinearProgressIndicator>(find.byType(LinearProgressIndicator))
          .value,
      closeTo(0.25, 1e-9),
    );
    expect(find.text(en.pickerCancel), findsOneWidget);

    source.completeFile('a0', File('/fake/a0'));
    await tester.pumpAndSettle();
  });

  testWidgets('cancel stops the pre-flight and the bar disappears',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(1));
    addTearDown(source.dispose);
    source.locallyUnavailable.add('a0');
    source.pendingFiles.add('a0');

    final ProviderContainer container =
        await pumpPicker(tester, const CloudProgressBar(), source: source);
    container.read(selectionProvider.notifier).toggleAsset(testAsset('a0'));
    container.read(pickerCommitProvider.notifier).commit(onReady: () {});
    await tester.pump();

    await tester.tap(find.text(en.pickerCancel));
    await tester.pump();

    expect(container.read(pickerCommitProvider).running, isFalse);
    expect(find.text(en.pickerDownloadingFromCloud), findsNothing);

    source.completeFile('a0', null);
    await tester.pumpAndSettle();
  });

  testWidgets('a failure offers Retry, and Retry re-runs the pre-flight',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(1));
    addTearDown(source.dispose);
    source.locallyUnavailable.add('a0');
    source.failingFiles.add('a0');

    int ready = 0;
    final ProviderContainer container =
        await pumpPicker(tester, const CloudProgressBar(), source: source);
    container.read(selectionProvider.notifier).toggleAsset(testAsset('a0'));
    await container
        .read(pickerCommitProvider.notifier)
        .commit(onReady: () => ready += 1);
    await tester.pump();

    expect(ready, 0);
    expect(find.text(en.pickerDownloadFailed), findsOneWidget);
    expect(find.text(en.pickerRetry), findsOneWidget);

    source.failingFiles.remove('a0');
    await tester.tap(find.text(en.pickerRetry));
    await tester.pumpAndSettle();

    expect(ready, 1);
    expect(find.text(en.pickerDownloadFailed), findsNothing);
  });
}
