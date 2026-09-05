import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/testing.dart';

ProviderContainer _container(
  FakeAssetSource source, {
  AssetPickerConfig config = const AssetPickerConfig(),
  List<Override> extra = const <Override>[],
}) {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      assetPickerConfigProvider.overrideWithValue(config),
      assetSourceProvider.overrideWithValue(source),
      ...extra,
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  test('requests permission for exactly the configured media types', () async {
    final FakeAssetSource source = FakeAssetSource();
    addTearDown(source.dispose);
    final ProviderContainer container = _container(
      source,
      config: const AssetPickerConfig(
        mediaTypes: <PickerMediaType>{PickerMediaType.video},
      ),
    );

    await container.read(assetPickerPermissionProvider.future);

    expect(source.permissionRequests.single,
        <PickerMediaType>{PickerMediaType.video});
  });

  test('surfaces limited as limited, not as an error', () async {
    final FakeAssetSource source =
        FakeAssetSource(permission: PickerPermission.limited);
    addTearDown(source.dispose);
    final ProviderContainer container = _container(source);

    expect(
      await container.read(assetPickerPermissionProvider.future),
      PickerPermission.limited,
    );
  });

  test('surfaces denied as denied', () async {
    final FakeAssetSource source =
        FakeAssetSource(permission: PickerPermission.denied);
    addTearDown(source.dispose);
    final ProviderContainer container = _container(source);

    expect(
      await container.read(assetPickerPermissionProvider.future),
      PickerPermission.denied,
    );
  });

  test('openSettings opens the OS screen and then re-checks', () async {
    final FakeAssetSource source =
        FakeAssetSource(permission: PickerPermission.denied);
    addTearDown(source.dispose);

    int opened = 0;
    final ProviderContainer container = _container(
      source,
      extra: <Override>[
        pickerSettingsOpenerProvider.overrideWithValue(() async {
          opened += 1;
          // The user grants access while they are away.
          source.permission = PickerPermission.full;
        }),
      ],
    );

    expect(await container.read(assetPickerPermissionProvider.future),
        PickerPermission.denied);

    await container.read(permissionActionsProvider.notifier).openSettings();
    await container.pump();

    expect(opened, 1);
    // The re-check must be a fresh request, not a replay of the cached answer:
    // returning from Settings is the ONLY moment a denied user can become a
    // granted one without the app restarting.
    expect(await container.read(assetPickerPermissionProvider.future),
        PickerPermission.full);
    expect(source.permissionRequests, hasLength(2));
  });

  test('recheck re-requests without touching settings', () async {
    final FakeAssetSource source =
        FakeAssetSource(permission: PickerPermission.denied);
    addTearDown(source.dispose);
    final ProviderContainer container = _container(source);

    await container.read(assetPickerPermissionProvider.future);
    source.permission = PickerPermission.limited;

    container.read(permissionActionsProvider.notifier).recheck();
    await container.pump();

    expect(await container.read(assetPickerPermissionProvider.future),
        PickerPermission.limited);
    expect(source.permissionRequests, hasLength(2));
  });
}
