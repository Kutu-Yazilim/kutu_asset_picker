import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';

/// A consumer overriding exactly one string — the whole point of a concrete
/// base class instead of package-scoped gen-l10n (design §8.2).
final class _OneStringOverride extends AssetPickerTextEn {
  const _OneStringOverride();

  @override
  String get pickerNext => 'Continue';
}

void main() {
  test('the default delegate is English, not the author\'s language', () {
    const AssetPickerText text = AssetPickerTextEn();

    expect(text.pickerNext, 'Next');
    expect(text.pickerCancel, 'Cancel');
    expect(text.pickerAlbumAll, 'Recent');
    expect(text.pickerManageSelection, 'Manage selection');
    expect(text.pickerOpenSettings, 'Open settings');
    expect(text.pickerRetry, 'Retry');
  });

  test('THE LIMITED EMPTY STATE NEVER SAYS NO PHOTOS FOUND', () {
    // design §4.2: neither OS reports which media kinds are in a limited
    // selection. Request images, have the user grant only videos, and you get
    // `limited` plus zero results — indistinguishable from an empty library.
    // Telling that user "no photos found" is telling them a lie about their
    // own device.
    const AssetPickerText text = AssetPickerTextEn();

    expect(text.pickerEmptyLimited.toLowerCase(), isNot(contains('no photos')));
    expect(text.pickerEmptyLimited.toLowerCase(), isNot(contains('empty')));
    // It points at the fix instead.
    expect(text.pickerEmptyLimited.toLowerCase(), contains('selected'));

    // The genuinely-empty full-access state is a DIFFERENT string, which is
    // why the two cannot share one key.
    expect(text.pickerEmptyLibrary, isNot(text.pickerEmptyLimited));
  });

  test('pluralised strings read correctly at 0, 1 and many', () {
    const AssetPickerText text = AssetPickerTextEn();

    expect(text.selectedCount(0), '0 selected');
    expect(text.selectedCount(1), '1 selected');
    expect(text.selectedCount(7), '7 selected');
    expect(text.limitReached(1), 'You can select up to 1 item');
    expect(text.limitReached(10), 'You can select up to 10 items');
  });

  test('videoTooLong and fileTooLarge render human units', () {
    const AssetPickerText text = AssetPickerTextEn();

    expect(text.videoTooLong(const Duration(seconds: 60)),
        'Videos must be 60 seconds or shorter');
    expect(
        text.fileTooLarge(15 * 1024 * 1024), 'Files must be 15 MB or smaller');
  });

  test('overriding a single string is extends plus one getter', () {
    const AssetPickerText text = _OneStringOverride();

    expect(text.pickerNext, 'Continue');
    expect(text.pickerCancel, 'Cancel', reason: 'everything else is inherited');
  });

  test('the provider defaults to English and is overridable', () {
    final ProviderContainer plain = ProviderContainer();
    addTearDown(plain.dispose);
    expect(plain.read(assetPickerTextProvider), isA<AssetPickerTextEn>());

    final ProviderContainer custom = ProviderContainer(
      overrides: <Override>[
        assetPickerTextProvider.overrideWithValue(const _OneStringOverride()),
      ],
    );
    addTearDown(custom.dispose);
    expect(custom.read(assetPickerTextProvider).pickerNext, 'Continue');
  });
}
