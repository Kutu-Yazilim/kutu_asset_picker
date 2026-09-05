import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/src/picker/picker_image_cache_scope.dart';
import 'package:kutu_media_transform/kutu_media_transform.dart';
import 'package:kutu_asset_picker/src/config/picker_tuning.dart';

void main() {
  testWidgets('the budget is derived from the entry cap and the thumb size',
      (WidgetTester tester) async {
    // design §4.4: at 200x200x4 = 160 KB a thumbnail, the default 100 MiB byte
    // cap binds at ~655 entries — well before the 1000-entry count cap. Sizing
    // the byte budget as (entries x bytes-per-thumbnail) makes the two caps
    // bind together instead of one silently shadowing the other.
    final int entries = PaintingBinding.instance.imageCache.maximumSize;

    expect(
      pickerImageCacheBytes(const ThumbSize.square(200)),
      entries * 200 * 200 * 4,
    );
  });

  testWidgets('a small thumbnail never LOWERS the budget',
      (WidgetTester tester) async {
    final int before = PaintingBinding.instance.imageCache.maximumSizeBytes;

    // 64x64x4 x 1000 is well under the default cap; the scope raises, it never
    // shrinks the host app's cache out from under it.
    expect(
      pickerImageCacheBytes(const ThumbSize.square(64)),
      greaterThanOrEqualTo(before),
    );
  });

  testWidgets('an absurd thumbnail size is capped',
      (WidgetTester tester) async {
    expect(
      pickerImageCacheBytes(const ThumbSize.square(4096)),
      PickerGridTuning.imageCacheCeilingBytes,
    );
  });

  testWidgets('the scope raises the budget on entry and restores it on exit',
      (WidgetTester tester) async {
    final int original = PaintingBinding.instance.imageCache.maximumSizeBytes;

    await tester.pumpWidget(
      const PickerImageCacheScope(
        thumbSize: ThumbSize.square(200),
        child: SizedBox.shrink(),
      ),
    );

    expect(
      PaintingBinding.instance.imageCache.maximumSizeBytes,
      pickerImageCacheBytes(const ThumbSize.square(200)),
    );

    await tester.pumpWidget(const SizedBox.shrink());

    expect(PaintingBinding.instance.imageCache.maximumSizeBytes, original,
        reason: 'a picker that permanently inflates the host app\'s image '
            'cache is a memory leak with a UI');
  });
}
