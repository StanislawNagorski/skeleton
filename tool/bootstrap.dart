// Bootstrap rename script for the Skeleton Flutter template.
//
// Usage:
//   dart run tool/bootstrap.dart --name MyApp --bundle com.example.myapp
//
// Renames the Dart package, Android config, iOS config, pubspec, README,
// and Drift database name in a single pass. Prints a Firebase setup
// checklist after successful rename.
//
// Pure Dart -- no external package dependencies.

import 'dart:io';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Converts PascalCase / camelCase to snake_case.
///
/// Example: `MyApp` -> `my_app`, `todoList` -> `todo_list`.
String _toSnakeCase(String name) {
  final buffer = StringBuffer();
  for (var i = 0; i < name.length; i++) {
    final char = name[i];
    if (char == char.toUpperCase() && char != char.toLowerCase()) {
      // It's an uppercase letter.
      if (i > 0) buffer.write('_');
      buffer.write(char.toLowerCase());
    } else {
      buffer.write(char);
    }
  }
  return buffer.toString();
}

/// Returns the value following [flag] in [args], or `null` if absent.
String? _parseArg(List<String> args, String flag) {
  for (var i = 0; i < args.length - 1; i++) {
    if (args[i] == flag) return args[i + 1];
  }
  return null;
}

/// Validates `--name` input. Exits with code 1 on failure.
void _validateName(String name) {
  final regex = RegExp(r'^[a-zA-Z][a-zA-Z0-9]*$');
  if (!regex.hasMatch(name)) {
    stderr.writeln(
      'Error: Invalid --name "$name".\n'
      'Name must start with a letter and contain only alphanumeric '
      'characters (no spaces, dots, slashes, or special characters).\n'
      'Example: MyApp, TodoList, skeleton',
    );
    exit(1);
  }
}

/// Validates `--bundle` input. Exits with code 1 on failure.
void _validateBundle(String bundle) {
  final regex = RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*){2,}$');
  if (!regex.hasMatch(bundle)) {
    stderr.writeln(
      'Error: Invalid --bundle "$bundle".\n'
      'Bundle ID must be in reverse-domain format with at least 3 '
      'segments, lowercase letters, digits, and underscores only.\n'
      'Example: com.example.myapp, com.company.todo_list',
    );
    exit(1);
  }
}

/// Reads [path], replaces all occurrences of [from] with [to], writes back.
/// Returns `true` if the file was actually modified.
bool _replaceInFile(String path, String from, String to) {
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('Warning: File not found, skipping: $path');
    return false;
  }
  final original = file.readAsStringSync();
  final updated = original.replaceAll(from, to);
  if (updated == original) return false;
  file.writeAsStringSync(updated);
  return true;
}

/// Recursively finds all `.dart` files under [directory] and replaces
/// [from] with [to] in each. Returns the number of files modified.
int _replaceInDartFiles(String directory, String from, String to) {
  var count = 0;
  final dir = Directory(directory);
  if (!dir.existsSync()) return count;

  for (final entity in dir.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      if (_replaceInFile(entity.path, from, to)) count++;
    }
  }
  return count;
}

/// Moves the Android Kotlin directory from the old bundle path to the new
/// one and cleans up empty parent directories.
void _moveKotlinDir(String oldBundle, String newBundle) {
  const kotlinBase = 'android/app/src/main/kotlin';
  final oldPath = '$kotlinBase/${oldBundle.replaceAll('.', '/')}';
  final newPath = '$kotlinBase/${newBundle.replaceAll('.', '/')}';

  final oldDir = Directory(oldPath);
  if (!oldDir.existsSync()) {
    stderr.writeln('Warning: Kotlin directory not found at $oldPath');
    return;
  }

  // Create new directory structure.
  Directory(newPath).createSync(recursive: true);

  // Move all files from old to new.
  for (final entity in oldDir.listSync()) {
    if (entity is File) {
      // Read, update package declaration, write to new location.
      var content = entity.readAsStringSync();
      content = content.replaceAll(
        'package $oldBundle',
        'package $newBundle',
      );
      final fileName = entity.uri.pathSegments.last;
      File('$newPath/$fileName').writeAsStringSync(content);
      entity.deleteSync();
    }
  }

  // Recursively delete empty parent directories back to kotlin/.
  var current = oldDir;
  while (current.path != kotlinBase && current.path.startsWith(kotlinBase)) {
    if (current.existsSync() && current.listSync().isEmpty) {
      current.deleteSync();
    } else {
      break;
    }
    current = current.parent;
  }
}

// ---------------------------------------------------------------------------
// Main
// ---------------------------------------------------------------------------

void main(List<String> args) {
  // -- Parse arguments -------------------------------------------------------
  final name = _parseArg(args, '--name');
  final bundle = _parseArg(args, '--bundle');

  if (name == null || bundle == null) {
    stderr.writeln(
      'Usage: dart run tool/bootstrap.dart --name <AppName> '
      '--bundle <com.foo.app>\n\n'
      'Arguments:\n'
      '  --name    App display name (PascalCase, e.g. MyApp)\n'
      '  --bundle  Bundle / application ID (reverse-domain, '
      'e.g. com.example.myapp)',
    );
    exit(1);
  }

  // -- Validate inputs -------------------------------------------------------
  _validateName(name);
  _validateBundle(bundle);

  // -- Derived values --------------------------------------------------------
  final dartPackage = _toSnakeCase(name);
  final displayName = name;
  final bundleId = bundle;

  stdout
    ..writeln('Bootstrapping: $displayName ($bundleId)')
    ..writeln('Dart package:  $dartPackage')
    ..writeln();

  var totalFilesModified = 0;

  try {
    // 1. Dart package imports ------------------------------------------------
    stdout.writeln('[1/9] Renaming Dart package imports...');
    final dartCount = _replaceInDartFiles(
      'lib',
      'package:skeleton/',
      'package:$dartPackage/',
    );
    totalFilesModified += dartCount;
    stdout.writeln('       $dartCount file(s) updated.');

    // 2. Android build.gradle.kts -------------------------------------------
    stdout.writeln('[2/9] Updating Android build.gradle.kts...');
    if (_replaceInFile(
      'android/app/build.gradle.kts',
      'com.example.skeleton',
      bundleId,
    )) {
      totalFilesModified++;
    }

    // 3. Android AndroidManifest.xml ----------------------------------------
    stdout.writeln('[3/9] Updating Android AndroidManifest.xml...');
    if (_replaceInFile(
      'android/app/src/main/AndroidManifest.xml',
      'android:label="skeleton"',
      'android:label="$displayName"',
    )) {
      totalFilesModified++;
    }

    // 4. Android Kotlin directory -------------------------------------------
    stdout.writeln('[4/9] Moving Android Kotlin directory...');
    _moveKotlinDir('com.example.skeleton', bundleId);
    totalFilesModified++; // MainActivity.kt always counts

    // 5. iOS project.pbxproj ------------------------------------------------
    stdout.writeln('[5/9] Updating iOS project.pbxproj...');
    if (_replaceInFile(
      'ios/Runner.xcodeproj/project.pbxproj',
      'com.example.skeleton',
      bundleId,
    )) {
      totalFilesModified++;
    }

    // 6. iOS Info.plist ------------------------------------------------------
    stdout.writeln('[6/9] Updating iOS Info.plist...');
    final plistFile = File('ios/Runner/Info.plist');
    if (plistFile.existsSync()) {
      final plistOriginal = plistFile.readAsStringSync();
      var plistContent = plistOriginal;

      // CFBundleDisplayName: <string>Skeleton</string>
      final displayNamePattern = RegExp(
        r'(<key>CFBundleDisplayName</key>\s*<string>)Skeleton(</string>)',
      );
      plistContent = plistContent.replaceAllMapped(
        displayNamePattern,
        (match) => '${match.group(1)}$displayName${match.group(2)}',
      );

      // CFBundleName: <string>skeleton</string>
      final bundleNamePattern = RegExp(
        r'(<key>CFBundleName</key>\s*<string>)skeleton(</string>)',
      );
      plistContent = plistContent.replaceAllMapped(
        bundleNamePattern,
        (match) => '${match.group(1)}$dartPackage${match.group(2)}',
      );

      if (plistContent != plistOriginal) {
        plistFile.writeAsStringSync(plistContent);
        totalFilesModified++;
      }
    }

    // 7. pubspec.yaml --------------------------------------------------------
    stdout.writeln('[7/9] Updating pubspec.yaml...');
    final pubspecFile = File('pubspec.yaml');
    if (pubspecFile.existsSync()) {
      var content = pubspecFile.readAsStringSync();
      content = content.replaceFirst(
        RegExp(r'^name:\s+skeleton$', multiLine: true),
        'name: $dartPackage',
      );
      content = content.replaceFirst(
        RegExp(r'^description:.*$', multiLine: true),
        'description: "$displayName Flutter application."',
      );
      pubspecFile.writeAsStringSync(content);
      totalFilesModified++;
    }

    // 8. README.md -----------------------------------------------------------
    stdout.writeln('[8/9] Updating README.md...');
    final readmeFile = File('README.md');
    if (readmeFile.existsSync()) {
      var content = readmeFile.readAsStringSync();
      content = content.replaceFirst(
        '# Skeleton - Flutter App Template',
        '# $displayName',
      );
      readmeFile.writeAsStringSync(content);
      totalFilesModified++;
    }

    // 9. Drift database name -------------------------------------------------
    stdout.writeln('[9/9] Updating Drift database name...');
    if (_replaceInFile(
      'lib/core/database/app_database.dart',
      "'skeleton_db'",
      "'${dartPackage}_db'",
    )) {
      totalFilesModified++;
    }

    // -- Summary -------------------------------------------------------------
    stdout
      ..writeln()
      ..writeln('$totalFilesModified file(s) modified total.')
      ..writeln();

    // -- Post-run checklist (per D-05 / TOOL-02) -----------------------------
    stdout.writeln(
      'Bootstrap complete! $displayName ($bundleId) is ready.\n'
      '\n'
      'Next steps:\n'
      '  1. Run: fvm flutter pub get\n'
      '  2. Run: dart run build_runner build --delete-conflicting-outputs\n'
      '  3. Create a Firebase project at https://console.firebase.google.com\n'
      '  4. Register Android app with package name: $bundleId\n'
      '  5. Register iOS app with bundle ID: $bundleId\n'
      '  6. Download google-services.json -> android/app/\n'
      '  7. Download GoogleService-Info.plist -> ios/Runner/\n'
      '  8. Run: flutterfire configure --project=<your-firebase-project-id>\n'
      '  9. Register SHA-1 fingerprints:\n'
      '     - Debug:   keytool -list -v -keystore ~/.android/debug.keystore '
      '-alias androiddebugkey -storepass android\n'
      '     - Release: keytool -list -v -keystore <your-release-keystore> '
      '-alias <your-alias>\n'
      '  10. Apple Sign-in: Enable "Sign in with Apple" capability in Xcode\n'
      '  11. Apple Sign-in: Configure Services ID at '
      'https://developer.apple.com\n'
      '  12. Run: fvm flutter run',
    );
  } on Exception catch (e) {
    stderr.writeln('Error during bootstrap: $e');
    exit(2);
  }
}
