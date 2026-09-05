import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kutu_asset_picker/src/crop/video/seek_coalescer.dart';

import '../../support/fake_seek_target.dart';

void main() {
  group('SeekCoalescer', () {
    test('60 rapid drag updates produce far fewer than 60 seeks', () {
      fakeAsync((async) {
        final target =
            FakeSeekTarget(latency: const Duration(milliseconds: 120));
        final coalescer = SeekCoalescer(
          target: target,
          debounce: const Duration(milliseconds: 40),
        );

        // A 120 Hz drag across half a second of finger travel.
        for (var i = 0; i < 60; i++) {
          coalescer.request(Duration(milliseconds: i * 100));
          async.elapse(const Duration(milliseconds: 8));
        }
        async.elapse(const Duration(seconds: 2));

        expect(target.seeks.length, lessThan(10));
        expect(target.seeks.length, greaterThan(1));
        coalescer.dispose();
      });
    });

    test('the final position is always honoured', () {
      fakeAsync((async) {
        final target =
            FakeSeekTarget(latency: const Duration(milliseconds: 120));
        final coalescer = SeekCoalescer(
          target: target,
          debounce: const Duration(milliseconds: 40),
        );

        for (var i = 0; i < 60; i++) {
          coalescer.request(Duration(milliseconds: i * 100));
          async.elapse(const Duration(milliseconds: 8));
        }
        async.elapse(const Duration(seconds: 2));

        expect(target.seeks.last, const Duration(milliseconds: 5900));
        expect(coalescer.pending, isNull);
        coalescer.dispose();
      });
    });

    test('seeks on the leading edge, so a frame appears immediately', () {
      fakeAsync((async) {
        final target =
            FakeSeekTarget(latency: const Duration(milliseconds: 120));
        final coalescer = SeekCoalescer(target: target);

        coalescer.request(const Duration(seconds: 1));
        async.flushMicrotasks();

        expect(target.seeks, const [Duration(seconds: 1)]);
        coalescer.dispose();
      });
    });

    test('a request that lands mid-flight is queued, not dropped', () {
      fakeAsync((async) {
        final target =
            FakeSeekTarget(latency: const Duration(milliseconds: 200));
        final coalescer = SeekCoalescer(
          target: target,
          debounce: const Duration(milliseconds: 40),
        );

        coalescer.request(const Duration(seconds: 1));
        async.elapse(const Duration(milliseconds: 50));
        expect(coalescer.isSeeking, isTrue);

        coalescer.request(const Duration(seconds: 9));
        async.elapse(const Duration(seconds: 1));

        expect(
          target.seeks,
          const [Duration(seconds: 1), Duration(seconds: 9)],
        );
        coalescer.dispose();
      });
    });

    test('only the newest of several mid-flight requests survives', () {
      fakeAsync((async) {
        final target =
            FakeSeekTarget(latency: const Duration(milliseconds: 200));
        final coalescer = SeekCoalescer(
          target: target,
          debounce: const Duration(milliseconds: 40),
        );

        coalescer.request(const Duration(seconds: 1));
        async.elapse(const Duration(milliseconds: 20));
        coalescer.request(const Duration(seconds: 2));
        coalescer.request(const Duration(seconds: 3));
        coalescer.request(const Duration(seconds: 4));
        async.elapse(const Duration(seconds: 1));

        expect(
          target.seeks,
          const [Duration(seconds: 1), Duration(seconds: 4)],
        );
        coalescer.dispose();
      });
    });

    test('flush skips the debounce floor', () {
      fakeAsync((async) {
        final target = FakeSeekTarget();
        final coalescer = SeekCoalescer(
          target: target,
          debounce: const Duration(seconds: 5),
        );

        coalescer.request(const Duration(seconds: 1));
        async.flushMicrotasks();
        coalescer.request(const Duration(seconds: 2));
        coalescer.flush();
        async.flushMicrotasks();

        expect(
          target.seeks,
          const [Duration(seconds: 1), Duration(seconds: 2)],
        );
        coalescer.dispose();
      });
    });

    test('a disposed coalescer stops seeking', () {
      fakeAsync((async) {
        final target =
            FakeSeekTarget(latency: const Duration(milliseconds: 120));
        final coalescer = SeekCoalescer(target: target);

        coalescer.request(const Duration(seconds: 1));
        async.elapse(const Duration(milliseconds: 60));
        coalescer.dispose();
        coalescer.request(const Duration(seconds: 2));
        async.elapse(const Duration(seconds: 2));

        expect(target.seeks, const [Duration(seconds: 1)]);
      });
    });
  });
}
