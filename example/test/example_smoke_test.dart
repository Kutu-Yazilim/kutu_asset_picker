// The example is a scored artefact: pub.dev shows it, and a reader who copies a
// broken example gets a broken app. These two tests prove the demo app builds
// and that the README's "embed it yourself" shape mounts — with no device, no
// gallery and no platform channel.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/kutu_asset_picker.dart';
import 'package:kutu_asset_picker/testing.dart';
import 'package:kutu_asset_picker_example/demo_configs.dart';
import 'package:kutu_asset_picker_example/example_app.dart';
import 'package:kutu_asset_picker_example/example_home.dart';
import 'package:kutu_media_transform/testing.dart';

void main() {
  testWidgets('the demo app offers all four configurations', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ExampleApp());
    await tester.pump();

    expect(find.text(DemoLabels.post), findsOneWidget);
    expect(find.text(DemoLabels.story), findsOneWidget);
    expect(find.text(DemoLabels.avatar), findsOneWidget);
    expect(find.text(DemoLabels.banner), findsOneWidget);
    expect(
      tester.widget<Text>(find.byKey(ExampleHome.summaryKey)).data,
      DemoLabels.nothingPicked,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'AssetPickerView mounts over the fakes, exactly as the README shows',
      (WidgetTester tester) async {
    final FakeAssetSource source = FakeAssetSource(
      albumList: const <PickerAlbum>[
        PickerAlbum(id: 'all', name: 'Recent', assetCount: 0, isAll: true),
      ],
      assetsByAlbum: <String, List<PickerAsset>>{'all': const <PickerAsset>[]},
    );
    addTearDown(source.dispose);
    final FakeMediaTransform transform = FakeMediaTransform();
    addTearDown(transform.dispose);

    AssetPickerResult? delivered;
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          assetPickerConfigProvider.overrideWithValue(DemoConfigs.post),
          assetSourceProvider.overrideWithValue(source),
          mediaTransformProvider.overrideWithValue(transform),
        ],
        child: MaterialApp(
          home: AssetPickerView(
            onCompleted: (AssetPickerResult result) => delivered = result,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AssetPickerView), findsOneWidget);
    expect(
      delivered,
      isNull,
      reason: 'nothing was selected, so onCompleted must not have fired',
    );
    expect(tester.takeException(), isNull);
  });
}
