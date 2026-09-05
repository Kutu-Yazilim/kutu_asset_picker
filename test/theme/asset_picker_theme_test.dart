import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';

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
}
