import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/crop/video/scrubber_mode.dart';
import 'package:kutu_asset_picker/src/crop/video/scrubber_mode_toggle.dart';

import '../../support/picker_test_harness.dart';

void main() {
  const text = AssetPickerTextEn();

  testWidgets('offers both modes with delegate copy', (tester) async {
    await pumpPickerWidget(
      tester,
      const ScrubberModeToggle(),
      config: const AssetPickerConfig(),
    );

    expect(find.text(text.cropTrim), findsOneWidget);
    expect(find.text(text.cropCoverFrame), findsOneWidget);
  });

  testWidgets('selecting cover switches the mode', (tester) async {
    final container = await pumpPickerWidget(
      tester,
      const ScrubberModeToggle(),
      config: const AssetPickerConfig(),
    );
    expect(container.read(scrubberModeControllerProvider), ScrubberMode.trim);

    await tester.tap(find.text(text.cropCoverFrame));
    await tester.pump();

    expect(container.read(scrubberModeControllerProvider), ScrubberMode.cover);
  });

  testWidgets('selecting trim switches back', (tester) async {
    final container = await pumpPickerWidget(
      tester,
      const ScrubberModeToggle(),
      config: const AssetPickerConfig(),
    );
    await tester.tap(find.text(text.cropCoverFrame));
    await tester.pump();

    await tester.tap(find.text(text.cropTrim));
    await tester.pump();

    expect(container.read(scrubberModeControllerProvider), ScrubberMode.trim);
  });

  testWidgets('renders nothing when the config leaves only one mode',
      (tester) async {
    await pumpPickerWidget(
      tester,
      const ScrubberModeToggle(),
      config: const AssetPickerConfig(enableCoverFrame: false),
    );

    expect(find.text(text.cropTrim), findsNothing);
    expect(find.text(text.cropCoverFrame), findsNothing);
  });
}
