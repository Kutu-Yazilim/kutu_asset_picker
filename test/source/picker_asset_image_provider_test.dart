import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/testing.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

/// A real 1x1 PNG, so `decode` produces a real codec.
final Uint8List _onePixelPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
);

PickerAsset _asset(String id) => PickerAsset(
      id: id,
      type: PickerMediaType.image,
      width: 100,
      height: 100,
      createdAt: DateTime.utc(2026, 8, 4),
    );

void main() {
  group('PickerAssetKey', () {
    test('two keys over the same triple are equal and hash equal', () {
      // design §4.4: this value equality IS the dedup mechanism. Two cells
      // asking for the same asset at the same size must resolve to ONE cache
      // entry and ONE platform call.
      const PickerAssetKey a = PickerAssetKey(
        assetId: 'a1',
        size: ThumbSize.square(200),
        quality: 85,
      );
      const PickerAssetKey b = PickerAssetKey(
        assetId: 'a1',
        size: ThumbSize.square(200),
        quality: 85,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('equality survives distinct ThumbSize instances', () {
      // The key must not depend on ThumbSize implementing == : it compares
      // width and height itself. A separately-constructed, non-const
      // ThumbSize with the same dimensions must still dedup.
      final PickerAssetKey a = PickerAssetKey(
        assetId: 'a1',
        size: ThumbSize(200, 200),
        quality: 85,
      );
      final PickerAssetKey b = PickerAssetKey(
        assetId: 'a1',
        size: ThumbSize(200, 200),
        quality: 85,
      );

      expect(identical(a.size, b.size), isFalse);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('any of the three fields differing breaks equality', () {
      const PickerAssetKey base = PickerAssetKey(
        assetId: 'a1',
        size: ThumbSize.square(200),
        quality: 85,
      );

      expect(
        base,
        isNot(equals(const PickerAssetKey(
            assetId: 'a2', size: ThumbSize.square(200), quality: 85))),
      );
      expect(
        base,
        isNot(equals(const PickerAssetKey(
            assetId: 'a1', size: ThumbSize.square(320), quality: 85))),
      );
      expect(
        base,
        isNot(equals(const PickerAssetKey(
            assetId: 'a1', size: ThumbSize.square(200), quality: 95))),
      );
    });
  });

  group('PickerAssetImageProvider', () {
    testWidgets('obtainKey carries asset id, size and quality',
        (WidgetTester tester) async {
      final FakeAssetSource source = FakeAssetSource();
      addTearDown(source.dispose);

      final PickerAssetImageProvider provider = PickerAssetImageProvider(
        _asset('a1'),
        source: source,
        size: const ThumbSize.square(200),
        quality: 85,
      );

      final PickerAssetKey key =
          await provider.obtainKey(ImageConfiguration.empty);

      expect(key.assetId, 'a1');
      expect(key.size.width, 200);
      expect(key.quality, 85);
    });

    testWidgets('resolves real bytes into a real image',
        (WidgetTester tester) async {
      final FakeAssetSource source = FakeAssetSource();
      addTearDown(source.dispose);
      source.thumbnailBytes = _onePixelPng;

      final PickerAssetImageProvider provider = PickerAssetImageProvider(
        _asset('a1'),
        source: source,
        size: const ThumbSize.square(200),
      );

      // A real decode completes on the engine's own thread, outside the
      // test's fake async zone, so it only finishes inside runAsync.
      await tester.runAsync(() async {
        final Completer<ui.Image> completer = Completer<ui.Image>();
        provider.resolve(ImageConfiguration.empty).addListener(
              ImageStreamListener(
                  (ImageInfo info, bool _) => completer.complete(info.image)),
            );

        final ui.Image image = await completer.future;
        expect(image.width, 1);
        expect(image.height, 1);
      });
    });

    testWidgets('an empty thumbnail response surfaces as an image error',
        (WidgetTester tester) async {
      final FakeAssetSource source = FakeAssetSource();
      addTearDown(source.dispose);
      source.thumbnailBytes = Uint8List(0);

      final PickerAssetImageProvider provider = PickerAssetImageProvider(
        _asset('gone'),
        source: source,
        size: const ThumbSize.square(200),
      );

      Object? captured;
      provider.resolve(ImageConfiguration.empty).addListener(
            ImageStreamListener(
              (ImageInfo info, bool _) {},
              onError: (Object error, StackTrace? _) => captured = error,
            ),
          );
      await tester.pumpAndSettle();

      expect(captured, isA<StateError>());
      // The failed key must not be left in the cache, or the tile can never
      // recover on a later rebuild.
      expect(
        PaintingBinding.instance.imageCache.containsKey(
          const PickerAssetKey(
            assetId: 'gone',
            size: ThumbSize.square(200),
            quality: 85,
          ),
        ),
        isFalse,
      );
    });

    testWidgets('two providers for the same asset and size are equal',
        (WidgetTester tester) async {
      final FakeAssetSource source = FakeAssetSource();
      addTearDown(source.dispose);

      final PickerAssetImageProvider a = PickerAssetImageProvider(
        _asset('a1'),
        source: source,
        size: const ThumbSize.square(200),
      );
      final PickerAssetImageProvider b = PickerAssetImageProvider(
        _asset('a1'),
        source: source,
        size: const ThumbSize.square(200),
      );

      // Image widgets compare providers to decide whether to re-resolve; if
      // this were identity-based every grid rebuild would restart every decode.
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
