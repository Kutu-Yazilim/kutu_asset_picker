import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/picker/picker_footer.dart';

import '../support/pump_picker.dart';

bool _nextEnabled(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byType(FilledButton)).onPressed != null;

void main() {
  testWidgets('NEXT IS ENABLED AT minSelection, NOT AT ONE',
      (WidgetTester tester) async {
    // design §5. With the default minSelection of 1 this rule and "enabled at
    // one item" are indistinguishable, which is why the regression hides until
    // somebody configures a real minimum.
    final source = fakeSourceWith(testAssets(3));
    addTearDown(source.dispose);

    final ProviderContainer container = await pumpPicker(
      tester,
      PickerFooter(onNext: () {}),
      source: source,
      config: const AssetPickerConfig(minSelection: 3, maxSelection: 5),
    );

    expect(_nextEnabled(tester), isFalse);

    container.read(selectionProvider.notifier).toggleAsset(testAsset('a0'));
    await tester.pump();
    expect(_nextEnabled(tester), isFalse, reason: 'one is not three');

    container.read(selectionProvider.notifier).toggleAsset(testAsset('a1'));
    await tester.pump();
    expect(_nextEnabled(tester), isFalse, reason: 'two is not three either');

    container.read(selectionProvider.notifier).toggleAsset(testAsset('a2'));
    await tester.pump();
    expect(_nextEnabled(tester), isTrue, reason: 'enabled AT the minimum');
  });

  testWidgets('with the default config an empty selection cannot advance',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(2));
    addTearDown(source.dispose);

    final ProviderContainer container =
        await pumpPicker(tester, PickerFooter(onNext: () {}), source: source);

    expect(_nextEnabled(tester), isFalse);

    container.read(selectionProvider.notifier).toggleAsset(testAsset('a0'));
    await tester.pump();

    expect(_nextEnabled(tester), isTrue);
  });

  testWidgets('the count reads through the delegate',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(3));
    addTearDown(source.dispose);

    final ProviderContainer container =
        await pumpPicker(tester, PickerFooter(onNext: () {}), source: source);

    expect(find.text(en.selectedCount(0)), findsOneWidget);

    container.read(selectionProvider.notifier)
      ..toggleAsset(testAsset('a0'))
      ..toggleAsset(testAsset('a1'));
    await tester.pump();

    expect(find.text(en.selectedCount(2)), findsOneWidget);
    expect(find.text(en.pickerNext), findsOneWidget);
  });

  testWidgets('at the cap the count switches to the limit hint',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(3));
    addTearDown(source.dispose);

    final ProviderContainer container = await pumpPicker(
      tester,
      PickerFooter(onNext: () {}),
      source: source,
      config: const AssetPickerConfig(maxSelection: 2),
    );
    container.read(selectionProvider.notifier)
      ..toggleAsset(testAsset('a0'))
      ..toggleAsset(testAsset('a1'));
    await tester.pump();

    expect(find.text(en.limitReached(2)), findsOneWidget);
    expect(find.text(en.selectedCount(2)), findsNothing);
    expect(_nextEnabled(tester), isTrue,
        reason: 'the cap stops selecting more, it does not stop advancing');
  });

  testWidgets('an all-local selection advances immediately',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(2));
    addTearDown(source.dispose);

    int advanced = 0;
    final ProviderContainer container = await pumpPicker(
      tester,
      PickerFooter(onNext: () => advanced += 1),
      source: source,
    );
    container.read(selectionProvider.notifier).toggleAsset(testAsset('a0'));
    await tester.pump();

    await tester.tap(find.text(en.pickerNext));
    await tester.pumpAndSettle();

    expect(advanced, 1);
  });

  testWidgets('A CLOUD-ONLY ASSET HOLDS NEXT UNTIL IT IS ON THE DEVICE',
      (WidgetTester tester) async {
    // design §4.5: the grid looks complete over an asset that lives only in
    // iCloud. Advancing here and failing at export is the exact behaviour the
    // pre-flight exists to prevent.
    final source = fakeSourceWith(testAssets(2));
    addTearDown(source.dispose);
    source.locallyUnavailable.add('a0');
    source.pendingFiles.add('a0');

    int advanced = 0;
    final ProviderContainer container = await pumpPicker(
      tester,
      PickerFooter(onNext: () => advanced += 1),
      source: source,
    );
    container.read(selectionProvider.notifier).toggleAsset(testAsset('a0'));
    await tester.pump();

    await tester.tap(find.text(en.pickerNext));
    await tester.pump();

    expect(advanced, 0);
    expect(_nextEnabled(tester), isFalse,
        reason: 'the button goes inert while the pre-flight runs, so a second '
            'tap cannot start a second batch');

    source.completeFile('a0', File('/fake/a0'));
    await tester.pumpAndSettle();

    expect(advanced, 1);
    expect(_nextEnabled(tester), isTrue);
  });

  testWidgets('a failed pre-flight leaves Next pressable again',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(2));
    addTearDown(source.dispose);
    source.locallyUnavailable.add('a0');
    source.failingFiles.add('a0');

    int advanced = 0;
    final ProviderContainer container = await pumpPicker(
      tester,
      PickerFooter(onNext: () => advanced += 1),
      source: source,
    );
    container.read(selectionProvider.notifier).toggleAsset(testAsset('a0'));
    await tester.pump();

    await tester.tap(find.text(en.pickerNext));
    await tester.pumpAndSettle();

    expect(advanced, 0);
    expect(_nextEnabled(tester), isTrue);
  });
}
