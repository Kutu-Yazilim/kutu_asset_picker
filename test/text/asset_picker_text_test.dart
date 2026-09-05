import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/picker/duration_format.dart';
import 'package:kutu_asset_picker/src/text/asset_picker_text_locale.dart';
import 'package:kutu_asset_picker/src/text/asset_picker_text_scope.dart';
import 'package:kutu_asset_picker/src/text/asset_picker_text_tr.dart';
import 'package:flutter/material.dart';

/// A consumer overriding exactly one string — the whole point of a concrete
/// base class instead of package-scoped gen-l10n (design §8.2).
final class _OneStringOverride extends AssetPickerTextEn {
  const _OneStringOverride();

  @override
  String get pickerNext => 'Continue';
}

/// Contract §8's full surface: 25 getters and 7 methods.
List<String> allStrings(AssetPickerText text) => <String>[
      text.pickerTitle,
      text.pickerNext,
      text.pickerCancel,
      text.pickerDone,
      text.pickerAlbumAll,
      text.pickerAlbumSwitch,
      text.pickerCameraTile,
      text.pickerRemove,
      text.pickerPermissionDeniedTitle,
      text.pickerPermissionDeniedBody,
      text.pickerOpenSettings,
      text.pickerLimitedBanner,
      text.pickerManageSelection,
      text.pickerEmptyLimited,
      text.pickerEmptyLibrary,
      text.pickerDownloadingFromCloud,
      text.pickerDownloadFailed,
      text.pickerRetry,
      text.cropTitle,
      text.cropApplyToAll,
      text.cropReorderHint,
      text.cropTrim,
      text.cropCoverFrame,
      text.exportFailed,
      text.exportCancel,
      text.selectedCount(3),
      text.limitReached(10),
      text.aspectLabel(CropAspectLabel.square),
      text.durationRange(Duration.zero, const Duration(seconds: 42)),
      text.exportProgress(2, 5),
      text.videoTooLong(const Duration(seconds: 60)),
      text.fileTooLarge(15 * 1024 * 1024),
    ];

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

  group('assetPickerTextFromLocale', () {
    test('an absent locale falls back to ENGLISH, not Turkish', () {
      // This is the whole point of the resolver. wechat_assets_picker's base
      // delegate is Chinese and silently wins whenever no Locale is in the
      // widget tree; a published package's neutral default is English
      // (spec §8.2).
      expect(assetPickerTextFromLocale(null), isA<AssetPickerTextEn>());
    });

    test('an unknown locale falls back to English', () {
      expect(
        assetPickerTextFromLocale(const Locale('zh')),
        isA<AssetPickerTextEn>(),
      );
      expect(
        assetPickerTextFromLocale(const Locale('de', 'DE')),
        isA<AssetPickerTextEn>(),
      );
    });

    test('Turkish resolves to the Turkish delegate', () {
      expect(
        assetPickerTextFromLocale(const Locale('tr')),
        isA<AssetPickerTextTr>(),
      );
      expect(
        assetPickerTextFromLocale(const Locale('tr', 'TR')),
        isA<AssetPickerTextTr>(),
      );
    });

    test('the language subtag is matched case-insensitively', () {
      // Locale does not lowercase what it is given, so Locale('TR') keeps its
      // capitals and a naive == 'tr' would miss it.
      expect(
        assetPickerTextFromLocale(const Locale('TR')),
        isA<AssetPickerTextTr>(),
      );
    });

    test('English resolves to English', () {
      expect(
        assetPickerTextFromLocale(const Locale('en', 'GB')),
        isA<AssetPickerTextEn>(),
      );
    });
  });

  group('delegate parity', () {
    test('English answers every string, non-empty', () {
      for (final String value in allStrings(const AssetPickerTextEn())) {
        expect(value, isNotEmpty);
      }
    });

    test('Turkish answers every string, non-empty', () {
      for (final String value in allStrings(const AssetPickerTextTr())) {
        expect(value, isNotEmpty);
      }
    });

    test('the checklist covers contract §8 in full', () {
      // 25 getters + 7 methods. If a member is added to the base class and not
      // to allStrings, a locale can ship with a hole in it and nothing fails.
      expect(allStrings(const AssetPickerTextEn()), hasLength(32));
    });

    test('Turkish is actually translated, not English wearing a tr label', () {
      const AssetPickerTextEn en = AssetPickerTextEn();
      const AssetPickerTextTr tr = AssetPickerTextTr();

      expect(tr.pickerTitle, isNot(en.pickerTitle));
      expect(tr.pickerDone, isNot(en.pickerDone));
      expect(tr.cropTitle, isNot(en.cropTitle));
      expect(tr.pickerManageSelection, isNot(en.pickerManageSelection));
      expect(tr.pickerEmptyLibrary, isNot(en.pickerEmptyLibrary));
      expect(tr.pickerRemove, isNot(en.pickerRemove));
    });

    test('the ratio labels are the digits, in both locales', () {
      for (final AssetPickerText text in const <AssetPickerText>[
        AssetPickerTextEn(),
        AssetPickerTextTr(),
      ]) {
        expect(text.aspectLabel(CropAspectLabel.square), '1:1');
        expect(text.aspectLabel(CropAspectLabel.portrait), '4:5');
        expect(text.aspectLabel(CropAspectLabel.landscape), '16:9');
        expect(text.aspectLabel(CropAspectLabel.story), '9:16');
        expect(text.aspectLabel(CropAspectLabel.banner), '3:1');
      }
    });

    test('the counted strings carry their number', () {
      expect(const AssetPickerTextEn().exportProgress(2, 5), contains('2'));
      expect(const AssetPickerTextEn().exportProgress(2, 5), contains('5'));
      expect(const AssetPickerTextTr().exportProgress(2, 5), contains('2'));
      expect(const AssetPickerTextTr().exportProgress(2, 5), contains('5'));
    });

    test('durationRange formats both ends through slice 3s formatter', () {
      // One formatter, not two: a second copy is a second place for 0:07 to
      // become 0:7.
      for (final AssetPickerText text in const <AssetPickerText>[
        AssetPickerTextEn(),
        AssetPickerTextTr(),
      ]) {
        final String label = text.durationRange(
          const Duration(seconds: 5),
          const Duration(seconds: 65),
        );

        expect(
            label, contains(formatPickerDuration(const Duration(seconds: 5))));
        expect(
            label, contains(formatPickerDuration(const Duration(seconds: 65))));
        expect(label, contains('0:05'));
        expect(label, contains('1:05'));
      }
    });
  });

  group('AssetPickerTextScope', () {
    testWidgets('hands the delegate down, and resolves when absent', (
      WidgetTester tester,
    ) async {
      late AssetPickerText scoped;
      late AssetPickerText unscoped;

      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (BuildContext outer) {
              unscoped = outer.pickerText;
              return AssetPickerTextScope(
                text: const AssetPickerTextTr(),
                child: Builder(
                  builder: (BuildContext inner) {
                    scoped = inner.pickerText;
                    return const SizedBox.shrink();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(scoped, isA<AssetPickerTextTr>());
      // No Localizations in this tree at all — the fallback must still be
      // English rather than a crash or a Chinese base delegate.
      expect(unscoped, isA<AssetPickerTextEn>());
    });

    testWidgets('an ambient Turkish locale resolves to Turkish', (
      WidgetTester tester,
    ) async {
      late AssetPickerText resolved;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('tr'),
          supportedLocales: const <Locale>[Locale('en'), Locale('tr')],
          // The default Material delegates only know English; a Turkish
          // MaterialApp needs the SDK's localised set to mount at all.
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Builder(
            builder: (BuildContext context) {
              resolved = context.pickerText;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, isA<AssetPickerTextTr>());
    });
  });
}
