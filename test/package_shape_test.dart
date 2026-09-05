import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// `flutter test` runs with the package root as the current directory, so these
/// paths are relative to `packages/kutu_asset_picker/`.
void main() {
  test('the package declares no native platform support of its own', () {
    // Design §2.2: pana reads platform support from the package's OWN pubspec,
    // non-transitively. A pure-Dart package that merely DEPENDS on a plugin
    // still scores 20/20 — but only while it stays pure-Dart.
    expect(Directory('android').existsSync(), isFalse,
        reason: 'kutu_asset_picker must stay pure Dart; native code belongs in '
            'kutu_media_transform.');
    expect(Directory('ios').existsSync(), isFalse);
    expect(Directory('macos').existsSync(), isFalse);

    final String pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('pluginClass')));
    expect(pubspec, isNot(contains('plugin:')));
  });

  test('the pubspec pins the SDK and the photo_manager floor', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();

    expect(pubspec, contains('sdk: ^3.5.0'));

    // Below 3.8.1 SQL pagination fails with "Failed to obtain the cursor"
    // (design §4.1). ^3.11.0 keeps the floor comfortably above it.
    final RegExpMatch? photoManager =
        RegExp(r'photo_manager:\s*\^(\d+)\.(\d+)\.(\d+)').firstMatch(pubspec);
    expect(photoManager, isNotNull,
        reason: 'photo_manager must be a caret-pinned direct dependency.');
    final int major = int.parse(photoManager!.group(1)!);
    final int minor = int.parse(photoManager.group(2)!);
    final int patch = int.parse(photoManager.group(3)!);
    expect(major, 3);
    expect(minor * 1000 + patch, greaterThanOrEqualTo(8 * 1000 + 1));
  });

  test('the local path override lives outside pubspec.yaml', () {
    // Design §3.2: a package-side `dependency_overrides:` block triggers a
    // publish hint and invalidates pana's `pub downgrade` check (20 points).
    // pubspec_overrides.yaml carries it instead, and slice 7 deletes the file.
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, isNot(contains('dependency_overrides')));
    expect(pubspec, isNot(contains('path: ../')));

    final File overrides = File('pubspec_overrides.yaml');
    expect(overrides.existsSync(), isTrue);
    expect(overrides.readAsStringSync(), contains('../kutu_media_transform'));
  });

  test('the changelog carries the pubspec version verbatim', () {
    final String pubspec = File('pubspec.yaml').readAsStringSync();
    final String version =
        RegExp(r'^version:\s*(\S+)$', multiLine: true).firstMatch(pubspec)!.group(1)!;
    expect(File('CHANGELOG.md').readAsStringSync(), contains('## $version'));
  });

  test('the readme has no plain-http links', () {
    // pana docks 5 points for a single http:// link (design §13).
    expect(File('README.md').readAsStringSync(), isNot(contains('http://')));
  });
}
