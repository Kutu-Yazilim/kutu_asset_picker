// Guards the pana-scored packaging invariants for this package. Every assertion here
// corresponds to a check in `pana` 0.23.x that is worth points on pub.dev, so a red test
// in this file is a score regression, not a style nit.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

/// pana reports a pubspec description shorter than this as "too short".
const int minDescriptionLength = 60;

/// pana reports a pubspec description longer than this as "too long".
const int maxDescriptionLength = 180;

/// pub.dev topic grammar: lowercase, starts with a letter, ends alphanumeric,
/// hyphens allowed in between, 2..32 characters.
final RegExp topicPattern = RegExp(r'^[a-z][a-z0-9-]{0,30}[a-z0-9]$');

/// pub.dev accepts at most five topics per package.
const int maxTopics = 5;

/// Markdown with fenced code blocks and inline code spans removed.
///
/// Needed so that a literal like the Android XML namespace URI inside a snippet
/// is not mistaken for an insecure link. pana only penalises real Markdown
/// links, and so does this check.
String withoutCode(String markdown) => markdown
    .replaceAll(RegExp(r'^```[\s\S]*?^```', multiLine: true), '')
    .replaceAll(RegExp(r'`[^`]*`'), '');

/// Every Markdown file the package ships, excluding build output.
Iterable<File> packageMarkdown() sync* {
  for (final FileSystemEntity entity
      in Directory('.').listSync(recursive: true, followLinks: false)) {
    if (entity is! File || !entity.path.endsWith('.md')) {
      continue;
    }
    if (entity.path.contains('/.dart_tool/') ||
        entity.path.contains('/build/')) {
      continue;
    }
    yield entity;
  }
}

/// Whether git ignores [path] from this package's directory — asked of git
/// itself rather than read from a particular `.gitignore`, so the assertion
/// holds whether the package lives in the monorepo, whose root supplies the
/// rule, or in its own repository, whose `.gitignore` does.
bool isGitIgnored(String path) =>
    Process.runSync('git', <String>['check-ignore', '-q', path]).exitCode == 0;

void main() {
  final YamlMap pubspec =
      loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;

  group('pubspec metadata', () {
    test('description sits inside the pana-scored length range', () {
      final String description = pubspec['description'] as String;
      expect(
        description.length,
        inInclusiveRange(minDescriptionLength, maxDescriptionLength),
        reason: 'description is ${description.length} characters',
      );
    });

    test('declares homepage, repository and issue_tracker over https', () {
      for (final String key in <String>[
        'homepage',
        'repository',
        'issue_tracker',
      ]) {
        final Object? value = pubspec[key];
        expect(value, isA<String>(), reason: 'pubspec.yaml is missing `$key`');
        expect(
          value as String,
          startsWith('https://'),
          reason: '`$key` must be an https URL',
        );
      }
    });

    test('declares between one and five well-formed topics', () {
      final Object? topics = pubspec['topics'];
      expect(topics, isA<YamlList>(),
          reason: 'pubspec.yaml is missing `topics`');
      final YamlList list = topics! as YamlList;
      expect(list, isNotEmpty);
      expect(list.length, lessThanOrEqualTo(maxTopics));
      for (final Object? topic in list) {
        expect(
          topic! as String,
          matches(topicPattern),
          reason: '`$topic` is not a valid pub.dev topic',
        );
      }
    });

    test('is publishable: no publish_to, no overrides, no path dependencies',
        () {
      expect(
        pubspec['publish_to'],
        isNull,
        reason: 'publish_to: none would make the package unpublishable',
      );
      expect(
        pubspec['dependency_overrides'],
        isNull,
        reason:
            'a package-side override invalidates pana pub downgrade (20 pts)',
      );
      final YamlMap dependencies = pubspec['dependencies'] as YamlMap;
      for (final MapEntry<Object?, Object?> entry in dependencies.entries) {
        final Object? constraint = entry.value;
        if (constraint is YamlMap) {
          expect(
            constraint['path'],
            isNull,
            reason:
                'dart pub publish refuses a path dependency on `${entry.key}`',
          );
        }
      }
    });

    test('declares the version this slice ships', () {
      expect(pubspec['version'], '0.1.1');
    });

    test('depends on kutu_media_transform as a hosted version', () {
      final YamlMap dependencies = pubspec['dependencies'] as YamlMap;
      expect(dependencies['kutu_media_transform'], '^0.2.0');
    });

    test('keeps the photo_manager floor at or above the pagination fix', () {
      final YamlMap dependencies = pubspec['dependencies'] as YamlMap;
      final String constraint = dependencies['photo_manager'] as String;
      final RegExpMatch? match =
          RegExp(r'^\^(\d+)\.(\d+)\.(\d+)$').firstMatch(constraint);
      expect(match, isNotNull,
          reason: 'expected a caret constraint, got $constraint');
      final int major = int.parse(match!.group(1)!);
      final int minor = int.parse(match.group(2)!);
      final int patch = int.parse(match.group(3)!);
      expect(major, 3);
      expect(
        minor > 8 || (minor == 8 && patch >= 1),
        isTrue,
        reason: 'photo_manager below 3.8.1 fails SQL pagination',
      );
    });
  });

  group('the transform is a hosted dependency, everywhere', () {
    test('pubspec.yaml names a hosted constraint and no path', () {
      // kutu_media_transform 0.2.0 is on pub.dev, so nothing local is needed
      // to resolve any more. A path dependency here would make the package
      // unpublishable; `dart pub publish` refuses one outright.
      final Object? declared =
          (pubspec['dependencies'] as YamlMap)['kutu_media_transform'];
      expect(
        declared,
        isA<String>(),
        reason: 'a map would mean a path or git dependency',
      );
      expect(declared, startsWith('^'));
    });

    test('any local override is gitignored, so the archive cannot pick it up',
        () {
      // Developing the two packages side by side is still legitimate, and a
      // `pubspec_overrides.yaml` is how you do it. It must never ship, and
      // `dart pub publish` honours gitignore — asked of git itself, so this
      // holds both in a monorepo whose root supplies the rule and in this
      // package's own repository.
      for (final String path in <String>[
        'pubspec_overrides.yaml',
        'example/pubspec_overrides.yaml',
      ]) {
        if (File(path).existsSync()) {
          expect(
            isGitIgnored(path),
            isTrue,
            reason: '$path exists and would reach the archive',
          );
        }
      }
    });
  });

  group('licence', () {
    test('ships verbatim MIT text that pana can detect', () {
      final File license = File('LICENSE');
      expect(license.existsSync(), isTrue, reason: 'no LICENSE file');
      final String text = license.readAsStringSync();
      expect(text, startsWith('MIT License'));
      expect(text, contains('Copyright (c) 2026 Kutu Yazılım'));
      expect(
        text,
        contains(
            'Permission is hereby granted, free of charge, to any person obtaining a copy'),
      );
      expect(
          text,
          contains(
              'THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND'));
    });
  });

  group('changelog', () {
    test('names the pubspec version and describes the release that ships', () {
      final File changelog = File('CHANGELOG.md');
      expect(changelog.existsSync(), isTrue, reason: 'no CHANGELOG.md');
      final String version = pubspec['version'] as String;
      final List<String> lines = changelog.readAsLinesSync();
      final String firstHeading = lines.firstWhere(
        (String line) => line.startsWith('## '),
        orElse: () => '',
      );
      expect(
        firstHeading,
        '## $version',
        reason: 'pana looks for the literal current version in CHANGELOG.md',
      );

      // Slices 1 and 3 each wrote an entry that disclaimed features later
      // slices then shipped. A changelog that denies what the package does is
      // the first thing a reader on pub.dev sees, so the denial is asserted
      // gone rather than left to review.
      final String text = changelog.readAsStringSync();
      for (final String supersededClaim in <String>[
        'UnimplementedError',
        'not in this release',
      ]) {
        expect(
          text,
          isNot(contains(supersededClaim)),
          reason: 'CHANGELOG.md still claims `$supersededClaim`',
        );
      }
    });
  });

  group('readme', () {
    test('exists and documents the sections a consumer needs', () {
      final File readme = File('README.md');
      expect(readme.existsSync(), isTrue, reason: 'no README.md');
      final String text = readme.readAsStringSync();
      for (final String heading in <String>[
        '# kutu_asset_picker',
        '## Install',
        '## Quick start',
        '## Embedding it in your own route',
        '## AssetPickerConfig',
        '## The result, and who owns the files',
        '## Theming',
        '## Text and localisation',
        '## Platform setup',
        '### Android',
        '### iOS',
        '## Limited access is a designed state, not a fallback',
        '## What this package does not do',
      ]) {
        expect(text, contains(heading), reason: 'README is missing `$heading`');
      }
    });

    test('documents every AssetPickerConfig field', () {
      final String text = File('README.md').readAsStringSync();
      for (final String field in <String>[
        'mediaTypes',
        'minSelection',
        'maxSelection',
        'aspects',
        'initialAspect',
        'allowPerAssetAspect',
        'cropOverlayShape',
        'gridColumns',
        'cellAspectRatio',
        'gridSpacing',
        'pickerSurface',
        'cropSurface',
        'enableCamera',
        'enableCrop',
        'enableTrim',
        'enableCoverFrame',
        'maxVideoDuration',
        'maxSourceMegapixels',
        'keepOriginals',
        'imageEncode',
        'videoEncode',
        'thumbSize',
      ]) {
        expect(
          text,
          contains('`$field`'),
          reason: 'README does not document AssetPickerConfig.$field',
        );
      }
    });

    test('no shipped Markdown carries an insecure link', () {
      for (final File file in packageMarkdown()) {
        expect(
          withoutCode(file.readAsStringSync()),
          isNot(contains('http://')),
          reason: '${file.path} has an http:// link — pana docks 5 points',
        );
      }
    });
  });

  group('example', () {
    test('has a pubspec, an entry point, a README and a smoke test', () {
      expect(File('example/pubspec.yaml').existsSync(), isTrue);
      expect(File('example/lib/main.dart').existsSync(), isTrue);
      expect(
        File('example/README.md').existsSync(),
        isTrue,
        reason: 'pub.dev renders example/README.md as its own tab',
      );
      expect(
        File('example/test/example_smoke_test.dart').existsSync(),
        isTrue,
        reason: 'the example must be proven to still build a widget tree',
      );
    });

    test('the example depends on this package by path, not by version', () {
      final YamlMap examplePubspec =
          loadYaml(File('example/pubspec.yaml').readAsStringSync()) as YamlMap;
      final YamlMap dependencies = examplePubspec['dependencies'] as YamlMap;
      final YamlMap self = dependencies['kutu_asset_picker'] as YamlMap;
      expect(self['path'], '../');
      expect(
        examplePubspec['publish_to'],
        'none',
        reason: 'the example is shipped as files, never published itself',
      );
    });

    test('the example depends on the transform as a hosted package', () {
      // This file ships inside the published archive, where a path such as
      // ../../kutu_media_transform does not exist — a consumer unpacking the
      // example could not resolve it. Only the smoke test needs the
      // dependency at all, for FakeMediaTransform.
      final YamlMap examplePubspec =
          loadYaml(File('example/pubspec.yaml').readAsStringSync()) as YamlMap;
      final Object? declared = (examplePubspec['dev_dependencies']
          as YamlMap)['kutu_media_transform'];
      expect(
        declared,
        isA<String>(),
        reason: 'a map would mean a path dependency that cannot ship',
      );
      expect(declared, startsWith('^'));
    });

    test('the example ships the platform setup the README promises', () {
      // Spec §4.3: the example is the working reference for the block the
      // package README tells consumers to paste. A README that claims it while
      // the files are bare is worse than no claim at all.
      final String manifest =
          File('example/android/app/src/main/AndroidManifest.xml')
              .readAsStringSync();
      for (final String permission in <String>[
        'android.permission.READ_MEDIA_IMAGES',
        'android.permission.READ_MEDIA_VIDEO',
        'android.permission.READ_MEDIA_VISUAL_USER_SELECTED',
        'android.permission.READ_EXTERNAL_STORAGE',
        'android.permission.CAMERA',
      ]) {
        expect(
          manifest,
          contains(permission),
          reason: 'the example manifest is missing $permission',
        );
      }

      final String plist =
          File('example/ios/Runner/Info.plist').readAsStringSync();
      for (final String key in <String>[
        'NSPhotoLibraryUsageDescription',
        'NSCameraUsageDescription',
        'NSMicrophoneUsageDescription',
        'PHPhotoLibraryPreventAutomaticLimitedAccessAlert',
      ]) {
        expect(
          RegExp('<key>$key</key>').allMatches(plist).length,
          1,
          reason: 'Info.plist must declare $key exactly once — duplicate keys '
              'in one dict are invalid and the later one silently wins',
        );
      }
    });
  });

  group('screenshots', () {
    test('every declared screenshot exists, is a PNG, and is small', () {
      final Object? declared = pubspec['screenshots'];
      expect(
        declared,
        isA<YamlList>(),
        reason: 'pubspec.yaml declares no screenshots',
      );
      final YamlList screenshots = declared! as YamlList;
      expect(screenshots, isNotEmpty);

      for (final Object? entry in screenshots) {
        final YamlMap shot = entry! as YamlMap;

        final String description = shot['description'] as String;
        expect(
          description.length,
          inInclusiveRange(10, 160),
          reason: 'screenshot description "$description" is a bad length',
        );

        final File file = File(shot['path'] as String);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'declared screenshot ${shot['path']} does not exist',
        );
        expect(
          file.lengthSync(),
          lessThan(2 * 1024 * 1024),
          reason: '${shot['path']} is over 2 MiB',
        );

        final RandomAccessFile handle = file.openSync();
        final List<int> header = handle.readSync(8);
        handle.closeSync();
        expect(
          header,
          <int>[0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A],
          reason: '${shot['path']} is not a PNG',
        );
      }
    });
  });
}
