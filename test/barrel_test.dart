import 'package:flutter_test/flutter_test.dart';
// The single import a consumer writes. If any exported file reaches into
// another package's `src/`, or two exports collide on a top-level name, this
// file fails to compile — which is the whole point of the test.
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:flutter/material.dart';

void main() {
  test('the public surface is reachable through one import', () {
    expect(const AssetPickerConfig().effectiveInitialAspect, CropAspect.square);
    expect(assetPickerTextFromLocale(null), isA<AssetPickerTextEn>());
    expect(
      scaleToCover(const Size(1000, 1000), const Size(500, 500)),
      closeTo(0.5, 1e-12),
    );
  });

  test('one AssetPickerView, one set of DI providers', () {
    // The two collisions this slice was closest to shipping: a second
    // `AssetPickerView` under `src/view/`, and a second declaration of the
    // three contract §9 providers. Either one is an ambiguous_export that only
    // shows up through the barrel — which is what this file imports.
    expect(
      const AssetPickerView(onCompleted: _ignoreResult),
      isA<AssetPickerView>(),
    );
    expect(assetPickerConfigProvider, isNotNull);
    expect(assetSourceProvider, isNotNull);
    expect(mediaTransformProvider, isNotNull);
  });
}

void _ignoreResult(AssetPickerResult result) {}
