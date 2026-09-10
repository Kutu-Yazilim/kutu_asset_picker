import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/testing.dart';

void main() {
  test('records the capture and returns the configured asset', () async {
    final source = FakeAssetSource();
    final capture =
        CapturedMedia(file: File('/tmp/shot.jpg'), kind: PickerMediaType.image);

    final saved = await source.saveToLibrary(capture);

    expect(source.savedCaptures, <CapturedMedia>[capture]);
    expect(saved?.id, 'captured');
  });

  test('saveThrows models a refused write', () async {
    final source = FakeAssetSource()..saveThrows = true;

    await expectLater(
      source.saveToLibrary(
        CapturedMedia(file: File('/tmp/shot.jpg'), kind: PickerMediaType.image),
      ),
      throwsStateError,
    );
  });
}
