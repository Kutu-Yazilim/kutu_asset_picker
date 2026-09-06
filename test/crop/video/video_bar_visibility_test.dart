import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/crop/video/video_bar_visibility.dart';

PickerAsset _asset(String id, PickerMediaType type) => PickerAsset(
      id: id,
      type: type,
      width: 100,
      height: 100,
      createdAt: DateTime.utc(2026, 8, 4),
    );

void main() {
  test('the bar shows when either video sub-step is enabled', () {
    expect(showsVideoBar(const AssetPickerConfig()), isTrue);
    expect(
      showsVideoBar(const AssetPickerConfig(enableCoverFrame: false)),
      isTrue,
    );
    expect(
      showsVideoBar(const AssetPickerConfig(enableTrim: false)),
      isTrue,
    );
  });

  test('the bar disappears when both are off', () {
    expect(
      showsVideoBar(
        const AssetPickerConfig(enableTrim: false, enableCoverFrame: false),
      ),
      isFalse,
    );
  });

  group('reservesVideoBarBand', () {
    final photo = _asset('p', PickerMediaType.image);
    final video = _asset('v', PickerMediaType.video);

    test('reserves the band once the selection holds a video', () {
      expect(
        reservesVideoBarBand(const AssetPickerConfig(), [photo, video]),
        isTrue,
      );
      expect(reservesVideoBarBand(const AssetPickerConfig(), [video]), isTrue);
    });

    test('never for a photo-only selection', () {
      expect(
        reservesVideoBarBand(const AssetPickerConfig(), [photo, photo]),
        isFalse,
      );
      expect(
          reservesVideoBarBand(const AssetPickerConfig(), const []), isFalse);
    });

    test('never when the bar itself has nothing to show', () {
      expect(
        reservesVideoBarBand(
          const AssetPickerConfig(enableTrim: false, enableCoverFrame: false),
          [video],
        ),
        isFalse,
      );
    });
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
