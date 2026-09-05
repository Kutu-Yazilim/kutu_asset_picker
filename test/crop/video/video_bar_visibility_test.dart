import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/crop/video/video_bar_visibility.dart';

void main() {
  test('the bar shows when either video sub-step is enabled', () {
    expect(showsFloatingVideoBar(const AssetPickerConfig()), isTrue);
    expect(
      showsFloatingVideoBar(const AssetPickerConfig(enableCoverFrame: false)),
      isTrue,
    );
    expect(
      showsFloatingVideoBar(const AssetPickerConfig(enableTrim: false)),
      isTrue,
    );
  });

  test('the bar disappears when both are off', () {
    expect(
      showsFloatingVideoBar(
        const AssetPickerConfig(enableTrim: false, enableCoverFrame: false),
      ),
      isFalse,
    );
  });

  test('the toggle needs both modes to exist', () {
    expect(showsScrubberModeToggle(const AssetPickerConfig()), isTrue);
    expect(
      showsScrubberModeToggle(const AssetPickerConfig(enableTrim: false)),
      isFalse,
    );
    expect(
      showsScrubberModeToggle(const AssetPickerConfig(enableCoverFrame: false)),
      isFalse,
    );
  });

  test('the initial mode falls back to cover when trimming is off', () {
    expect(initialScrubberMode(const AssetPickerConfig()), ScrubberMode.trim);
    expect(
      initialScrubberMode(const AssetPickerConfig(enableTrim: false)),
      ScrubberMode.cover,
    );
  });
}
