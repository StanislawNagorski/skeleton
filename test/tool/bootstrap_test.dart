@Timeout(Duration(minutes: 3))
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Recursively copies [source] to [destination], skipping directories that
/// are irrelevant or problematic for the bootstrap test (build artifacts,
/// VCS, platform dirs we don't test).
Future<void> _copyDirectory(Directory source, Directory destination) async {
  const skipDirs = {
    '.dart_tool',
    '.fvm',
    'build',
    '.git',
    'linux',
    'macos',
    'windows',
  };

  if (!destination.existsSync()) {
    destination.createSync(recursive: true);
  }

  await for (final entity in source.list(followLinks: false)) {
    final name = entity.uri.pathSegments
        .where((s) => s.isNotEmpty)
        .last;

    if (entity is Directory) {
      if (skipDirs.contains(name)) continue;
      final newDir = Directory('${destination.path}/$name');
      await _copyDirectory(entity, newDir);
    } else if (entity is File) {
      entity.copySync('${destination.path}/$name');
    } else if (entity is Link) {
      // Skip symlinks (e.g. .fvm/flutter_sdk).
    }
  }
}

void main() {
  late Directory tempDir;
  late String projectRoot;

  // Resolve the project root (two levels up from test/tool/).
  final scriptDir = Directory.current.path;
  // When run via `flutter test`, cwd is the project root.
  projectRoot = scriptDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('bootstrap_test_');
    await _copyDirectory(Directory(projectRoot), tempDir);
  });

  tearDownAll(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Bootstrap script E2E', () {
    late ProcessResult result;

    setUpAll(() async {
      result = await Process.run(
        'dart',
        [
          'run',
          'tool/bootstrap.dart',
          '--name',
          'TestApp',
          '--bundle',
          'com.test.myapp',
        ],
        workingDirectory: tempDir.path,
      );
    });

    test('exits with code 0', () {
      expect(
        result.exitCode,
        equals(0),
        reason: 'Bootstrap script failed.\n'
            'stdout: ${result.stdout}\n'
            'stderr: ${result.stderr}',
      );
    });

    test('prints completion message', () {
      expect(
        result.stdout.toString(),
        contains('Bootstrap complete!'),
      );
    });

    test('pubspec.yaml has renamed package', () {
      final pubspec =
          File('${tempDir.path}/pubspec.yaml').readAsStringSync();
      expect(pubspec, contains('name: test_app'));
      expect(pubspec, isNot(contains('name: skeleton')));
    });

    test('Android build.gradle.kts has new namespace', () {
      final gradle = File(
        '${tempDir.path}/android/app/build.gradle.kts',
      ).readAsStringSync();
      expect(gradle, contains('com.test.myapp'));
      expect(gradle, isNot(contains('com.example.skeleton')));
    });

    test('iOS project.pbxproj has new bundle ID', () {
      final pbxproj = File(
        '${tempDir.path}/ios/Runner.xcodeproj/project.pbxproj',
      ).readAsStringSync();
      expect(pbxproj, contains('com.test.myapp'));
      expect(pbxproj, isNot(contains('com.example.skeleton')));
    });

    test('iOS Info.plist has new display name', () {
      final plist = File(
        '${tempDir.path}/ios/Runner/Info.plist',
      ).readAsStringSync();
      expect(plist, contains('<string>TestApp</string>'));
    });

    test('README.md starts with new name', () {
      final readme =
          File('${tempDir.path}/README.md').readAsStringSync();
      expect(readme, startsWith('# TestApp'));
    });

    test('Drift database name is updated', () {
      final dbFile = File(
        '${tempDir.path}/lib/core/database/app_database.dart',
      ).readAsStringSync();
      expect(dbFile, contains("'test_app_db'"));
      expect(dbFile, isNot(contains("'skeleton_db'")));
    });

    test('Kotlin directory moved to new bundle path', () {
      final newKotlinDir = Directory(
        '${tempDir.path}/android/app/src/main/kotlin/com/test/myapp',
      );
      final oldKotlinDir = Directory(
        '${tempDir.path}/android/app/src/main/kotlin/com/example/skeleton',
      );

      expect(newKotlinDir.existsSync(), isTrue);
      expect(
        File('${newKotlinDir.path}/MainActivity.kt').existsSync(),
        isTrue,
      );
      expect(oldKotlinDir.existsSync(), isFalse);
    });

    test('no remaining package:skeleton/ imports in lib/', () {
      final libDir = Directory('${tempDir.path}/lib');
      // Spot-check key files.
      final filesToCheck = [
        'lib/main.dart',
        'lib/app.dart',
        'lib/startup_service.dart',
      ];

      for (final relativePath in filesToCheck) {
        final file = File('${tempDir.path}/$relativePath');
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          expect(
            content,
            isNot(contains('package:skeleton/')),
            reason: '$relativePath still contains package:skeleton/',
          );
        }
      }

      // Full scan of all .dart files under lib/.
      if (libDir.existsSync()) {
        for (final entity in libDir.listSync(recursive: true)) {
          if (entity is File && entity.path.endsWith('.dart')) {
            // Skip generated files.
            if (entity.path.endsWith('.g.dart') ||
                entity.path.endsWith('.gr.dart') ||
                entity.path.endsWith('.config.dart') ||
                entity.path.endsWith('.freezed.dart')) {
              continue;
            }
            final content = entity.readAsStringSync();
            expect(
              content,
              isNot(contains('package:skeleton/')),
              reason:
                  '${entity.path} still contains package:skeleton/',
            );
          }
        }
      }
    });
  });

  group('Bootstrap dart analyze', () {
    test('dart analyze passes on renamed project', () async {
      // After renaming the package from "skeleton" to "test_app", we must
      // regenerate .dart_tool/package_config.json so the analyzer can
      // resolve `package:test_app/` imports.
      final pubGetResult = await Process.run(
        'dart',
        ['pub', 'get'],
        workingDirectory: tempDir.path,
      );

      expect(
        pubGetResult.exitCode,
        equals(0),
        reason: 'dart pub get failed in renamed project.\n'
            'stdout: ${pubGetResult.stdout}\n'
            'stderr: ${pubGetResult.stderr}',
      );

      final analyzeResult = await Process.run(
        'dart',
        ['analyze', 'lib/'],
        workingDirectory: tempDir.path,
      );

      expect(
        analyzeResult.exitCode,
        equals(0),
        reason: 'dart analyze failed on renamed project.\n'
            'stdout: ${analyzeResult.stdout}\n'
            'stderr: ${analyzeResult.stderr}',
      );
    }, timeout: const Timeout(Duration(seconds: 120)));
  });

  group('Bootstrap input validation', () {
    late Directory validationTempDir;

    setUp(() {
      // Use a fresh temp dir for each validation test so we don't
      // need the full project copy -- the script validates before
      // touching the filesystem.
      validationTempDir = Directory.systemTemp.createTempSync(
        'bootstrap_validation_',
      );
      // Copy just the bootstrap script so `dart run` can find it.
      Directory('${validationTempDir.path}/tool').createSync();
      File('$projectRoot/tool/bootstrap.dart').copySync(
        '${validationTempDir.path}/tool/bootstrap.dart',
      );
    });

    tearDown(() {
      if (validationTempDir.existsSync()) {
        validationTempDir.deleteSync(recursive: true);
      }
    });

    test('rejects empty name', () async {
      final result = await Process.run(
        'dart',
        [
          'run',
          'tool/bootstrap.dart',
          '--name',
          '',
          '--bundle',
          'com.test.app',
        ],
        workingDirectory: validationTempDir.path,
      );
      expect(result.exitCode, equals(1));
    });

    test('rejects name with slashes', () async {
      final result = await Process.run(
        'dart',
        [
          'run',
          'tool/bootstrap.dart',
          '--name',
          'My/App',
          '--bundle',
          'com.test.app',
        ],
        workingDirectory: validationTempDir.path,
      );
      expect(result.exitCode, equals(1));
    });

    test('rejects invalid bundle ID', () async {
      final result = await Process.run(
        'dart',
        [
          'run',
          'tool/bootstrap.dart',
          '--name',
          'MyApp',
          '--bundle',
          'invalid',
        ],
        workingDirectory: validationTempDir.path,
      );
      expect(result.exitCode, equals(1));
    });

    test('rejects missing arguments', () async {
      final result = await Process.run(
        'dart',
        ['run', 'tool/bootstrap.dart'],
        workingDirectory: validationTempDir.path,
      );
      expect(result.exitCode, equals(1));
    });
  });
}
