import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/src/picker/selection_badge.dart';

import '../support/pump_picker.dart';
import 'package:kutu_asset_picker/src/theme/asset_picker_theme.dart';

void main() {
  testWidgets('index 0 renders no number', (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(1));
    addTearDown(source.dispose);

    await pumpPicker(tester, const SelectionBadge(index: 0), source: source);

    expect(find.byType(Text), findsNothing);
  });

  testWidgets('a selected index renders its 1-based number',
      (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(1));
    addTearDown(source.dispose);

    await pumpPicker(tester, const SelectionBadge(index: 3), source: source);

    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('the badge uses theme tokens, never a hardcoded colour',
      (WidgetTester tester) async {
    const Color brand = Color(0xFF00A86B);
    final source = fakeSourceWith(testAssets(1));
    addTearDown(source.dispose);

    await pumpPicker(
      tester,
      const SelectionBadge(index: 1),
      source: source,
      theme: ThemeData(
        extensions: const <ThemeExtension<dynamic>>[
          AssetPickerTheme(selectionBadgeFill: brand),
        ],
      ),
    );

    final DecoratedBox box = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(SelectionBadge),
        matching: find.byType(DecoratedBox),
      ),
    );
    expect((box.decoration as BoxDecoration).color, brand);
  });
}
