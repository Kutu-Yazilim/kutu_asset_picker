import 'dart:convert';
import 'dart:typed_data';

/// A real 2×2 opaque PNG, 74 bytes.
///
/// Widget tests that mount an `Image` need bytes the engine can actually
/// decode; a handful of arbitrary bytes throws inside the codec and the failure
/// arrives as an unrelated-looking exception from the image cache.
Uint8List tinyPngBytes() => base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAIAAAACCAYAAABytg0kAAAAEUlEQVR42mOwqr76H4QZYAwAVgQKJR0BEE8AAAAASUVORK5CYII=',
    );
