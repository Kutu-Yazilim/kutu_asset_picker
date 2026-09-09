import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';

void main() {
  test('equality is by path and kind, not File identity', () {
    final a =
        CapturedMedia(file: File('/tmp/a.jpg'), kind: PickerMediaType.image);
    final b =
        CapturedMedia(file: File('/tmp/a.jpg'), kind: PickerMediaType.image);
    final c =
        CapturedMedia(file: File('/tmp/a.jpg'), kind: PickerMediaType.video);

    expect(a, b);
    expect(a.hashCode, b.hashCode);
    expect(a, isNot(c));
  });
}
