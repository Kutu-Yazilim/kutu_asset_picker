import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';

import '../config/picker_tuning.dart';

/// The image-cache byte budget for a grid of [size] thumbnails.
///
/// Derived rather than guessed: the framework's own entry cap times the
/// decoded size of one thumbnail. At the default 200² thumbnail and the
/// default 1000-entry cap that is 160 MB — the point where the byte cap and
/// the count cap bind together, instead of the byte cap silently shadowing the
/// count cap at ~655 entries (design §4.4).
///
/// Clamped up from whatever the host app already configured — this scope
/// raises the budget, it never shrinks it — and down to
/// [PickerGridTuning.imageCacheCeilingBytes].
int pickerImageCacheBytes(ThumbSize size) {
  final ImageCache cache = PaintingBinding.instance.imageCache;
  final int derived = cache.maximumSize *
      size.width *
      size.height *
      PickerGridTuning.bytesPerPixel;
  return math.min(
    PickerGridTuning.imageCacheCeilingBytes,
    math.max(cache.maximumSizeBytes, derived),
  );
}

/// Raises `ImageCache.maximumSizeBytes` while the picker is mounted and
/// restores the previous value on the way out.
///
/// The restore is not optional: leaving the host app with an inflated image
/// cache after the picker closes is a memory leak with a UI.
class PickerImageCacheScope extends StatefulWidget {
  const PickerImageCacheScope({
    super.key,
    required this.thumbSize,
    required this.child,
  });

  final ThumbSize thumbSize;
  final Widget child;

  @override
  State<PickerImageCacheScope> createState() => _PickerImageCacheScopeState();
}

class _PickerImageCacheScopeState extends State<PickerImageCacheScope> {
  late final int _previousBytes;

  @override
  void initState() {
    super.initState();
    final ImageCache cache = PaintingBinding.instance.imageCache;
    _previousBytes = cache.maximumSizeBytes;
    cache.maximumSizeBytes = pickerImageCacheBytes(widget.thumbSize);
  }

  @override
  void dispose() {
    // Assigning a smaller cap evicts down to fit, which is exactly what should
    // happen: those thumbnails belong to a screen that no longer exists.
    PaintingBinding.instance.imageCache.maximumSizeBytes = _previousBytes;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
