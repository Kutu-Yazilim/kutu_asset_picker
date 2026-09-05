import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:photo_manager/photo_manager.dart';

/// `photo_manager`'s method channel. Mocking it lets the source's platform
/// calls run in a plain `flutter test` with no device.
const MethodChannel _channel =
    MethodChannel('com.fluttercandies/photo_manager');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<MethodCall> calls;

  void mock(Object? Function(MethodCall call) handler) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, (MethodCall call) async {
      calls.add(call);
      return handler(call);
    });
  }

  setUp(() {
    calls = <MethodCall>[];
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  });

  test('is an AssetSource', () {
    expect(PhotoManagerAssetSource(), isA<AssetSource>());
  });

  test('a limited platform response survives as PickerPermission.limited',
      () async {
    mock((MethodCall call) => call.method == 'requestPermissionExtend'
        ? PermissionState.limited.index
        : null);
    final PhotoManagerAssetSource source = PhotoManagerAssetSource();
    addTearDown(source.dispose);

    final PickerPermission permission = await source
        .requestPermission(<PickerMediaType>{PickerMediaType.image});

    expect(permission, PickerPermission.limited);
  });

  test('the permission request asks for exactly the configured kinds',
      () async {
    mock((MethodCall call) => PermissionState.authorized.index);
    final PhotoManagerAssetSource source = PhotoManagerAssetSource();
    addTearDown(source.dispose);

    await source.requestPermission(<PickerMediaType>{PickerMediaType.image});

    final MethodCall call = calls
        .firstWhere((MethodCall c) => c.method == 'requestPermissionExtend');
    final Map<String, dynamic> args =
        (call.arguments as Map<Object?, Object?>).cast<String, dynamic>();
    final Map<Object?, Object?> android =
        args['androidPermission']! as Map<Object?, Object?>;

    // Images only — never the audio bit.
    expect(android['type'], RequestType.image.value);
    expect(android['mediaLocation'], isFalse);
  });

  test('assets() for an unlisted album fails loudly', () async {
    mock((MethodCall call) => null);
    final PhotoManagerAssetSource source = PhotoManagerAssetSource();
    addTearDown(source.dispose);

    await expectLater(
      source.assets(
        album: const PickerAlbum(
          id: 'never-listed',
          name: 'Nope',
          assetCount: 3,
          isAll: false,
        ),
        offset: 0,
        count: 10,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('assets() returns empty for a non-positive count without a round trip',
      () async {
    // AssetPathEntity.getAssetListRange asserts `end > start`, so a zero count
    // would crash rather than return nothing.
    mock((MethodCall call) => null);
    final PhotoManagerAssetSource source = PhotoManagerAssetSource();
    addTearDown(source.dispose);

    final List<PickerAsset> result = await source.assets(
      album: const PickerAlbum(
          id: 'never-listed', name: 'Nope', assetCount: 3, isAll: false),
      offset: 0,
      count: 0,
    );

    expect(result, isEmpty);
    expect(calls, isEmpty);
  });

  test('changes is a broadcast stream that survives a second listener', () {
    final PhotoManagerAssetSource source = PhotoManagerAssetSource();
    addTearDown(source.dispose);

    expect(source.changes.isBroadcast, isTrue);
    final StreamSubscription<void> a = source.changes.listen((_) {});
    final StreamSubscription<void> b = source.changes.listen((_) {});
    addTearDown(a.cancel);
    addTearDown(b.cancel);
  });
}
