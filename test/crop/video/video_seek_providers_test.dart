import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/src/crop/video/seek_target.dart';
import 'package:kutu_asset_picker/src/crop/video/video_seek_providers.dart';

import '../../support/fake_seek_target.dart';

void main() {
  test('the coalescer seeks through whatever target is installed', () {
    fakeAsync((async) {
      final target = FakeSeekTarget();
      final container = ProviderContainer(
        overrides: [
          videoSeekTargetProvider('clip-1').overrideWithValue(target)
        ],
      );

      container
          .read(videoSeekCoalescerProvider('clip-1'))
          .request(const Duration(seconds: 4));
      async.flushMicrotasks();

      expect(target.seeks, const [Duration(seconds: 4)]);
      container.dispose();
    });
  });

  test('each asset gets its own coalescer', () {
    final first = FakeSeekTarget();
    final second = FakeSeekTarget();
    final container = ProviderContainer(
      overrides: [
        videoSeekTargetProvider('a').overrideWithValue(first),
        videoSeekTargetProvider('b').overrideWithValue(second),
      ],
    );
    addTearDown(container.dispose);

    expect(
      container.read(videoSeekCoalescerProvider('a')),
      isNot(same(container.read(videoSeekCoalescerProvider('b')))),
    );
  });

  test('disposing the scope disposes the coalescer, so no seek escapes', () {
    fakeAsync((async) {
      final target = FakeSeekTarget(latency: const Duration(milliseconds: 100));
      final container = ProviderContainer(
        overrides: [
          videoSeekTargetProvider('clip-1').overrideWithValue(target)
        ],
      );
      final coalescer = container.read(videoSeekCoalescerProvider('clip-1'));

      container.dispose();
      coalescer.request(const Duration(seconds: 4));
      async.elapse(const Duration(seconds: 1));

      expect(target.seeks, isEmpty);
    });
  });

  test('an uninitialised player yields a no-op target rather than throwing',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(videoSeekTargetProvider('never-loaded')),
        isA<NoopSeekTarget>());
  });
}
