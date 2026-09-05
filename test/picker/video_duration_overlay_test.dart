import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/picker/video_duration_overlay.dart';

import '../support/pump_picker.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('a video shows its duration', (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(1));
    addTearDown(source.dispose);

    await pumpPicker(
      tester,
      VideoDurationOverlay(
        asset: testAsset(
          'v1',
          type: PickerMediaType.video,
          duration: const Duration(seconds: 83),
        ),
      ),
      source: source,
    );

    expect(find.text('1:23'), findsOneWidget);
  });

  testWidgets('A NULL-DURATION VIDEO STILL RENDERS, JUST WITHOUT A CHIP',
      (WidgetTester tester) async {
    // design §4.5: MediaStore's duration column is genuinely null for some
    // files. The query filter keeps those assets visible with
    // `allowNullable: true`; this widget is the other half — it must handle a
    // null duration rather than throw, and it must not invent "0:00".
    final source = fakeSourceWith(testAssets(1));
    addTearDown(source.dispose);

    await pumpPicker(
      tester,
      VideoDurationOverlay(
        asset: testAsset('v-null', type: PickerMediaType.video),
      ),
      source: source,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('0:00'), findsNothing);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('an image shows nothing', (WidgetTester tester) async {
    final source = fakeSourceWith(testAssets(1));
    addTearDown(source.dispose);

    await pumpPicker(
      tester,
      VideoDurationOverlay(asset: testAsset('i1')),
      source: source,
    );

    expect(find.byType(Text), findsNothing);
  });
}
