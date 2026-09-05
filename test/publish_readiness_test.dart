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
      expect(pubspec['version'], '0.1.0');
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

  group('local monorepo link', () {
    test('the override lives in pubspec_overrides.yaml and is gitignored', () {
      // Slice 3 Task 1 created this file. It is not deleted here — the package
      // cannot resolve without it until kutu_media_transform 0.1.0 is on
      // pub.dev — it is gitignored so `dart pub publish` never ships it.
      final File overrides = File('pubspec_overrides.yaml');
      expect(
        overrides.existsSync(),
        isTrue,
        reason: 'local resolution needs a path override outside pubspec.yaml',
      );
      final YamlMap parsed = loadYaml(overrides.readAsStringSync()) as YamlMap;
      final YamlMap declared = parsed['dependency_overrides'] as YamlMap;
      final YamlMap transform = declared['kutu_media_transform'] as YamlMap;
      expect(transform['path'], '../kutu_media_transform');

      final String rootIgnore = File('../../.gitignore').readAsStringSync();
      expect(rootIgnore, contains('packages/*/pubspec_overrides.yaml'));
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
}
