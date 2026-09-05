import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/testing.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:kutu_media_transform/testing.dart';

const _fallbackVideoInfo = VideoInfo(
  duration: Duration(seconds: 30),
  codedWidth: 1920,
  codedHeight: 1080,
  rotationDegrees: 0,
  isHdr: false,
  hasAudio: true,
);

/// Pumps [child] inside a fixed-size box with the three overrides every picker
/// widget assumes (contract §9 — unoverridden reads throw on purpose).
///
/// Returns the container so a test can read providers after pumping.
Future<ProviderContainer> pumpPickerWidget(
  WidgetTester tester,
  Widget child, {
  required AssetPickerConfig config,
  AssetSource? source,
  MediaTransform? transform,
  List<Override> overrides = const <Override>[],
  Size surfaceSize = const Size(360, 640),
}) async {
  // Owned defaults are torn down here; a caller-supplied double stays the
  // caller's to dispose, because the caller is usually still asserting on it.
  final AssetSource resolvedSource;
  if (source != null) {
    resolvedSource = source;
  } else {
    final owned = FakeAssetSource();
    addTearDown(owned.dispose);
    resolvedSource = owned;
  }

  final MediaTransform resolvedTransform;
  if (transform != null) {
    resolvedTransform = transform;
  } else {
    final owned = FakeMediaTransform(videoInfo: _fallbackVideoInfo);
    addTearDown(owned.dispose);
    resolvedTransform = owned;
  }

  final container = ProviderContainer(
    overrides: [
      assetPickerConfigProvider.overrideWithValue(config),
      assetSourceProvider.overrideWithValue(resolvedSource),
      mediaTransformProvider.overrideWithValue(resolvedTransform),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: surfaceSize.width,
              height: surfaceSize.height,
              child: child,
            ),
          ),
        ),
      ),
    ),
  );
  return container;
}
