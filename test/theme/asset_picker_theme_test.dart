import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/theme/asset_picker_media_colors.dart';
import 'package:kutu_asset_picker/src/theme/asset_picker_theme_scope.dart';
import 'package:kutu_asset_picker/src/constants/asset_picker_radii.dart';

Future<ResolvedAssetPickerTheme> _resolve(
  WidgetTester tester, {
  ThemeData? theme,
  AssetPickerTheme? override,
}) async {
  late ResolvedAssetPickerTheme resolved;
  await tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Builder(
        builder: (BuildContext context) {
          resolved = AssetPickerTheme.resolve(context, override);
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  return resolved;
}

const Color kCropAmbient = Color(0xFF112233);
const Color kCropOverride = Color(0xFF445566);
const Color kSeed = Color(0xFF2E7D32);

void main() {
  testWidgets('with nothing configured it falls back to the ColorScheme',
      (WidgetTester tester) async {
    // The adoption-critical property (design §8.1): a consumer who configures
    // nothing still gets something that looks native, not a wall of black.
    final ThemeData theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3355FF)),
    );

    final ResolvedAssetPickerTheme resolved =
        await _resolve(tester, theme: theme);

    expect(resolved.background, theme.colorScheme.surface);
    expect(resolved.onSurface, theme.colorScheme.onSurface);
    expect(resolved.selectionBadgeFill, theme.colorScheme.primary);
    expect(resolved.selectionBadgeText, theme.colorScheme.onPrimary);
    expect(resolved.danger, theme.colorScheme.error);
    expect(resolved.cellRadius, PickerChromeSizes.cellRadius);
  });

  testWidgets('an app-level ThemeExtension wins over the ColorScheme',
      (WidgetTester tester) async {
    const Color brand = Color(0xFF00A86B);
    final ThemeData theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3355FF)),
      extensions: const <ThemeExtension<dynamic>>[
        AssetPickerTheme(selectionBadgeFill: brand, cellRadius: 12),
      ],
    );

    final ResolvedAssetPickerTheme resolved =
        await _resolve(tester, theme: theme);

    expect(resolved.selectionBadgeFill, brand);
    expect(resolved.cellRadius, 12);
    // Unset fields still fall through.
    expect(resolved.danger, theme.colorScheme.error);
  });

  testWidgets('a widget-argument override wins over both',
      (WidgetTester tester) async {
    const Color extensionColor = Color(0xFF00A86B);
    const Color argumentColor = Color(0xFFFF6F00);
    final ThemeData theme = ThemeData(
      extensions: const <ThemeExtension<dynamic>>[
        AssetPickerTheme(selectionBadgeFill: extensionColor),
      ],
    );

    final ResolvedAssetPickerTheme resolved = await _resolve(
      tester,
      theme: theme,
      override: const AssetPickerTheme(selectionBadgeFill: argumentColor),
    );

    expect(resolved.selectionBadgeFill, argumentColor);
  });

  testWidgets('an override with a null field falls through, not to null',
      (WidgetTester tester) async {
    const Color extensionColor = Color(0xFF00A86B);
    final ThemeData theme = ThemeData(
      extensions: const <ThemeExtension<dynamic>>[
        AssetPickerTheme(selectionBadgeFill: extensionColor),
      ],
    );

    final ResolvedAssetPickerTheme resolved = await _resolve(
      tester,
      theme: theme,
      // Overrides only what it names.
      override: const AssetPickerTheme(cellRadius: 2),
    );

    expect(resolved.cellRadius, 2);
    expect(resolved.selectionBadgeFill, extensionColor);
  });

  test('copyWith replaces only what it is given', () {
    const AssetPickerTheme base = AssetPickerTheme(
      background: Color(0xFF000000),
      cellRadius: 4,
    );

    final AssetPickerTheme copy = base.copyWith(cellRadius: 8);

    expect(copy.background, const Color(0xFF000000));
    expect(copy.cellRadius, 8);
  });

  test('lerp cross-fades, which is why this is a ThemeExtension', () {
    // A plain config object cannot do this: a light/dark switch would hard-cut
    // (design §8.1).
    const AssetPickerTheme light = AssetPickerTheme(
      background: Color(0xFF000000),
      cellRadius: 0,
    );
    const AssetPickerTheme dark = AssetPickerTheme(
      background: Color(0xFFFFFFFF),
      cellRadius: 10,
    );

    final AssetPickerTheme mid = light.lerp(dark, 0.5);

    expect(mid.cellRadius, 5);
    expect(mid.background, Color.lerp(light.background, dark.background, 0.5));
    expect(light.lerp(dark, 0).background, light.background);
    expect(light.lerp(dark, 1).background, dark.background);
  });

  test('lerp against a non-AssetPickerTheme returns this', () {
    const AssetPickerTheme theme = AssetPickerTheme(cellRadius: 4);
    expect(theme.lerp(null, 0.5), same(theme));
  });

  group('the crop and chip tokens resolve', () {
    testWidgets('a consumer who configures nothing gets the ColorScheme', (
      WidgetTester tester,
    ) async {
      // This is the adoption-critical property (spec §8.1): a picker that is a
      // wall of black on a light app is a picker nobody drops in. Asserting
      // isNotNull would be a tautology — every field is already non-nullable —
      // so this pins the actual fallback wiring instead.
      late ResolvedAssetPickerTheme resolved;
      late ThemeData ambient;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorSchemeSeed: kSeed),
          home: Builder(
            builder: (BuildContext context) {
              ambient = Theme.of(context);
              resolved = AssetPickerTheme.resolve(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final ColorScheme scheme = ambient.colorScheme;

      expect(resolved.background, scheme.surface);
      expect(resolved.surface, scheme.surfaceContainerHighest);
      expect(resolved.onSurface, scheme.onSurface);
      expect(resolved.onSurfaceMuted, scheme.onSurfaceVariant);
      expect(resolved.selectionBadgeFill, scheme.primary);
      expect(resolved.selectionBadgeText, scheme.onPrimary);
      expect(resolved.danger, scheme.error);
      expect(resolved.progressIndicator, scheme.primary);
      expect(resolved.chipSelectedFill, scheme.primary);
      expect(resolved.chipSelectedText, scheme.onPrimary);
      expect(resolved.chipUnselectedFill, scheme.surfaceContainerHighest);
      expect(resolved.chipUnselectedText, scheme.onSurfaceVariant);
      expect(resolved.titleStyle, ambient.textTheme.titleMedium);
      expect(resolved.badgeStyle, ambient.textTheme.labelSmall);
      expect(resolved.cellRadius, PickerChromeSizes.cellRadius);
      expect(resolved.sheetRadius, PickerChromeSizes.sheetRadius);
      expect(resolved.chipRadius, AssetPickerRadii.chip);
    });

    testWidgets('the three on-media tokens do NOT come from the scheme', (
      WidgetTester tester,
    ) async {
      // Chrome drawn over a photograph has to contrast with the photograph,
      // not with the app. A dark scheme's onSurface is nearly black, which is
      // invisible over a night shot.
      late ResolvedAssetPickerTheme resolved;
      late ColorScheme scheme;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: kSeed, brightness: Brightness.dark),
          ),
          home: Builder(
            builder: (BuildContext context) {
              scheme = Theme.of(context).colorScheme;
              resolved = AssetPickerTheme.resolve(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.cropMask.a, closeTo(0.72, 0.01));
      expect(resolved.cropGridLine.a, closeTo(0.55, 0.01));
      expect(resolved.cropWindowBorder.a, closeTo(0.9, 0.01));
      for (final Color onMedia in <Color>[
        resolved.cropGridLine,
        resolved.cropWindowBorder,
      ]) {
        expect(onMedia.r, 1);
        expect(onMedia.g, 1);
        expect(onMedia.b, 1);
      }
      expect(resolved.cropMask.r, 0);
      expect(resolved.cropGridLine, isNot(scheme.onSurface));
    });

    testWidgets('a light and a dark ColorScheme resolve differently', (
      WidgetTester tester,
    ) async {
      late ResolvedAssetPickerTheme light;
      late ResolvedAssetPickerTheme dark;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: kSeed)),
          home: Builder(
            builder: (BuildContext context) {
              light = AssetPickerTheme.resolve(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
                seedColor: kSeed, brightness: Brightness.dark),
          ),
          home: Builder(
            builder: (BuildContext context) {
              dark = AssetPickerTheme.resolve(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      // MaterialApp animates a theme change; the first frame after the pump
      // still resolves the light scheme, so let the cross-fade finish.
      await tester.pumpAndSettle();

      expect(light.background, isNot(dark.background));
      expect(light.onSurface, isNot(dark.onSurface));
      expect(light.chipUnselectedFill, isNot(dark.chipUnselectedFill));
      // …but the on-media tokens are identical in both, by design.
      expect(light.cropMask, dark.cropMask);
      expect(light.cropGridLine, dark.cropGridLine);
    });

    testWidgets('the app ThemeExtension beats the ColorScheme for a crop token',
        (WidgetTester tester) async {
      late ResolvedAssetPickerTheme resolved;
      late ColorScheme scheme;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorSchemeSeed: kSeed,
            extensions: const <ThemeExtension<dynamic>>[
              AssetPickerTheme(cropMask: kCropAmbient, chipRadius: 4),
            ],
          ),
          home: Builder(
            builder: (BuildContext context) {
              scheme = Theme.of(context).colorScheme;
              resolved = AssetPickerTheme.resolve(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.cropMask, kCropAmbient);
      expect(resolved.chipRadius, 4);
      // A partial extension must not wipe the fields it does not name back to a
      // default — they still come from the ColorScheme. `isNotNull` would be a
      // tautology here (the resolved field is non-nullable), so this names the
      // value the fallback is supposed to produce.
      expect(resolved.chipSelectedFill, scheme.primary);
      expect(resolved.chipUnselectedFill, scheme.surfaceContainerHighest);
      expect(resolved.cropGridLine,
          AssetPickerMediaColors.onMedia.withValues(alpha: 0.55));
    });

    testWidgets('the widget argument beats the app ThemeExtension', (
      WidgetTester tester,
    ) async {
      late ResolvedAssetPickerTheme resolved;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            colorSchemeSeed: kSeed,
            extensions: const <ThemeExtension<dynamic>>[
              AssetPickerTheme(
                  cropMask: kCropAmbient, cropGridLine: kCropAmbient),
            ],
          ),
          home: Builder(
            builder: (BuildContext context) {
              resolved = AssetPickerTheme.resolve(
                context,
                const AssetPickerTheme(cropMask: kCropOverride),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved.cropMask, kCropOverride);
      // The override only names cropMask, so cropGridLine still comes from the
      // app extension rather than being wiped back to the on-media default.
      expect(resolved.cropGridLine, kCropAmbient);
    });
  });

  group('copyWith and lerp cover the new fields', () {
    test('copyWith replaces only the named crop field', () {
      const AssetPickerTheme base = AssetPickerTheme(
        cropMask: kCropAmbient,
        chipSelectedFill: kCropAmbient,
      );

      final AssetPickerTheme next = base.copyWith(cropMask: kCropOverride);

      expect(next.cropMask, kCropOverride);
      expect(next.chipSelectedFill, kCropAmbient);
    });

    test('lerp interpolates the crop colors instead of snapping', () {
      // A ThemeExtension exists precisely so a light/dark switch cross-fades.
      // A lerp that returned `t < 0.5 ? this : other` would be a hard cut
      // wearing a lerp's clothes.
      const AssetPickerTheme black =
          AssetPickerTheme(cropMask: Color(0xFF000000));
      const AssetPickerTheme white =
          AssetPickerTheme(cropMask: Color(0xFFFFFFFF));

      final AssetPickerTheme mid = black.lerp(white, 0.5);

      expect(mid.cropMask!.r, closeTo(0.5, 0.02));
      expect(mid.cropMask!.g, closeTo(0.5, 0.02));
      expect(mid.cropMask!.b, closeTo(0.5, 0.02));
    });

    test('lerp interpolates chipRadius', () {
      const AssetPickerTheme a = AssetPickerTheme(chipRadius: 0);
      const AssetPickerTheme b = AssetPickerTheme(chipRadius: 20);

      expect(
        a.lerp(b, 0.5).chipRadius,
        closeTo(10, 1e-9),
      );
    });

    test('lerp endpoints are exact and a foreign extension returns this', () {
      const AssetPickerTheme a = AssetPickerTheme(cropMask: Color(0xFF000000));
      const AssetPickerTheme b = AssetPickerTheme(cropMask: Color(0xFFFFFFFF));

      expect(a.lerp(b, 0).cropMask, a.cropMask);
      expect(a.lerp(b, 1).cropMask, b.cropMask);
      expect(a.lerp(null, 0.5), same(a));
    });
  });

  group('AssetPickerThemeScope', () {
    testWidgets('carries a widget-argument override down the subtree', (
      WidgetTester tester,
    ) async {
      // This is the whole reason the scope exists: resolve() can only apply an
      // override where it is called, and AssetPickerView takes `theme:` as a
      // widget argument that has to reach widgets five levels down.
      late ResolvedAssetPickerTheme scoped;
      late ResolvedAssetPickerTheme unscoped;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorSchemeSeed: kSeed),
          home: Builder(
            builder: (BuildContext outer) {
              unscoped = outer.pickerTheme;
              return AssetPickerThemeScope(
                resolved: AssetPickerTheme.resolve(
                  outer,
                  const AssetPickerTheme(background: kCropOverride),
                ),
                child: Builder(
                  builder: (BuildContext inner) {
                    scoped = inner.pickerTheme;
                    return const SizedBox.shrink();
                  },
                ),
              );
            },
          ),
        ),
      );

      expect(scoped.background, kCropOverride);
      // Without a scope every chrome widget still resolves on its own, which is
      // what makes each of them independently pumpable in a golden test.
      expect(unscoped.background, isNot(kCropOverride));
    });

    testWidgets('context.pickerTheme falls back to resolve when unscoped', (
      WidgetTester tester,
    ) async {
      late ResolvedAssetPickerTheme viaExtension;
      late ResolvedAssetPickerTheme viaResolve;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorSchemeSeed: kSeed),
          home: Builder(
            builder: (BuildContext context) {
              viaExtension = context.pickerTheme;
              viaResolve = AssetPickerTheme.resolve(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(viaExtension, viaResolve);
    });
  });
}
