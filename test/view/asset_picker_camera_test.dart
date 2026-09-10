import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/src/picker/camera_tile.dart';
import 'package:kutu_asset_picker/testing.dart';

class _NoopCamera implements PickerCameraDelegate {
  @override
  Future<CapturedMedia?> capture(Set<PickerMediaType> kinds) async => null;
}

final _asset = PickerAsset(
  id: 'a0',
  type: PickerMediaType.image,
  width: 1000,
  height: 1000,
  createdAt: DateTime.utc(2026, 8, 4),
);

void main() {
  testWidgets('a camera passed to the scope reaches the grid', (tester) async {
    final source = FakeAssetSource(
      permission: PickerPermission.full,
      albumList: const [
        PickerAlbum(id: 'all', name: 'Recents', assetCount: 1, isAll: true),
      ],
      assetsByAlbum: {
        'all': [_asset],
      },
    );
    addTearDown(source.dispose);

    // A host ProviderScope on purpose: the scope owns a ROOT container, so an
    // override placed here must NOT be what makes this pass. The camera has
    // to travel through the constructor.
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AssetPickerScope(
            config: const AssetPickerConfig(),
            source: source,
            camera: _NoopCamera(),
            onCompleted: (_) {},
            onCancelled: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CameraTile), findsOneWidget);
  });

  testWidgets('no camera means no tile', (tester) async {
    final source = FakeAssetSource(
      permission: PickerPermission.full,
      albumList: const [
        PickerAlbum(id: 'all', name: 'Recents', assetCount: 1, isAll: true),
      ],
      assetsByAlbum: {
        'all': [_asset],
      },
    );
    addTearDown(source.dispose);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: AssetPickerScope(
            config: const AssetPickerConfig(),
            source: source,
            onCompleted: (_) {},
            onCancelled: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CameraTile), findsNothing);
  });
}
