# Phase 6: Bootstrap + i18n Cleanup + Tests - Research

**Researched:** 2026-04-18
**Domain:** Dart CLI tooling, Flutter l10n, Flutter testing (bloc_test + Drift)
**Confidence:** HIGH

## Summary

Phase 6 delivers three independent workstreams: (1) a pure-Dart bootstrap script that renames the skeleton in a single pass, (2) an ARB template switch from PL to EN with reconciliation, and (3) reference tests for the counter feature establishing the copy-paste pattern for downstream work.

The bootstrap script is a straightforward `dart:io` file manipulation tool. The codebase has 31 files in `lib/` importing `package:skeleton`, plus Android (namespace, applicationId, Kotlin package directory, AndroidManifest label), iOS (3 PRODUCT_BUNDLE_IDENTIFIER entries in project.pbxproj, CFBundleDisplayName + CFBundleName in Info.plist), pubspec.yaml (name + description), and README.md (title). The ARB files are already in sync (24 keys each, identical key sets), making the template switch trivial. Testing infrastructure is partially in place: `bloc_test ^10.0.0` is a direct dev dependency, `mocktail` is a transitive dependency (needs promotion to direct), and `sqlite3` is transitively available for Drift in-memory testing.

**Primary recommendation:** Build the bootstrap script first (standalone, no lib/ dependencies), then do the ARB switch (3-file edit), then add tests (which exercise the existing counter feature code).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Script lives at `tool/bootstrap.dart` and is invoked via `dart run tool/bootstrap.dart --name <AppName> --bundle <com.foo.app>` -- pure Dart, no shell dependencies
- **D-02:** Full rename pass covers: Dart package name (`skeleton` -> new), iOS bundle identifier, Android namespace + applicationId, `Info.plist` `CFBundleDisplayName`, `pubspec.yaml` name + description, `README.md` title
- **D-03:** Script uses `dart:io` `File`/`Directory` for file system operations -- no external packages needed
- **D-04:** Script validates inputs (non-empty name, valid reverse-domain bundle ID format) before starting rename
- **D-05:** Post-run checklist printed to stdout after successful rename -- covers Firebase project creation, `flutterfire configure` invocation, SHA-1 registration, Apple capability steps
- **D-06:** `l10n.yaml` `template-arb-file` changes from `app_pl.arb` to `app_en.arb` -- EN becomes the source of truth
- **D-07:** Both ARB files reconciled so no keys are missing in either -- `untranslated-messages-file: untranslated_messages.txt` added to `l10n.yaml` and the output file gitignored
- **D-08:** Existing key order preserved; no key renames needed (keys are already `feature_element` format)
- **D-09:** Test framework: `bloc_test` for cubit tests, `mocktail` for fakes, Drift `NativeDatabase.memory()` for repository tests -- matches project stack
- **D-10:** Test location: `test/features/home_page/` with `home_cubit_test.dart` and `counter_repository_test.dart` -- mirrors `lib/features/` structure
- **D-11:** Tests serve as copy-paste templates -- clear setup/teardown, named groups, comments explaining the pattern for new features
- **D-12:** Bootstrap script itself tested in `test/tool/bootstrap_test.dart` -- runs rename on a fixture copy, asserts `flutter analyze` passes on the renamed output

### Claude's Discretion
- Bootstrap script internal structure (function decomposition, error handling approach)
- Test assertion granularity and naming conventions
- Whether to add a `--dry-run` flag to bootstrap (nice-to-have, not required)

### Deferred Ideas (OUT OF SCOPE)
None -- discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TOOL-01 | Bootstrap rename script covering Dart package, iOS/Android bundle ids, display names, pubspec, README | Rename target inventory (Section: Bootstrap Rename Targets); `dart:io` patterns (Section: Code Examples) |
| TOOL-02 | Bootstrap prints post-bootstrap checklist for Firebase setup | Checklist content documented (Section: Architecture Patterns > Pattern 3) |
| TOOL-04 | ARB template switched PL -> EN, drift reconciled | ARB analysis shows 24 keys in sync (Section: Architecture Patterns > Pattern 2) |
| TOOL-05 | `untranslated-messages-file` configured in l10n.yaml and gitignored | l10n.yaml config documented (Section: Architecture Patterns > Pattern 2) |
| TOOL-06 | Counter feature tests (cubit + repository) as copy-paste templates | Test patterns from Context7 (Section: Code Examples); dependency audit (Section: Standard Stack) |
| TOOL-07 | Bootstrap script end-to-end tests | Fixture-based testing strategy (Section: Architecture Patterns > Pattern 4) |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Bootstrap rename | CLI tool (dart:io) | -- | Pure file manipulation, no Flutter runtime |
| ARB template switch | Build config (l10n.yaml) | -- | Changes gen-l10n behavior at build time |
| Cubit unit tests | Test runner | -- | Pure Dart, no Flutter widgets needed for cubit logic |
| Repository integration tests | Test runner | Database (Drift in-memory) | Tests exercise real Drift queries against SQLite in-memory |
| Bootstrap end-to-end tests | Test runner + CLI | -- | Spawns `dart run` / `flutter analyze` as subprocess |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `dart:io` | (SDK) | File/Directory manipulation for bootstrap script | No external deps needed for file ops [VERIFIED: codebase] |
| `bloc_test` | `^10.0.0` | Cubit testing with `blocTest<C,S>()` helper | Already in pubspec.yaml dev_dependencies [VERIFIED: pubspec.yaml] |
| `mocktail` | `^1.0.5` | Mock generation without codegen | Transitive dep, needs promotion to direct dev_dependency [VERIFIED: pubspec.lock] |
| `drift` | `^2.32.1` | `NativeDatabase.memory()` for repository tests | Already in pubspec.yaml [VERIFIED: pubspec.yaml] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `flutter_test` | (SDK) | Base test framework | All tests [VERIFIED: pubspec.yaml] |
| `sqlite3` | (transitive) | Native SQLite binding for Drift in-memory tests | Transitively available via `drift` [VERIFIED: pubspec.lock] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `mocktail` | `mockito` | `mockito` requires `build_runner` codegen; `mocktail` is zero-codegen -- matches project preference [ASSUMED] |
| Manual file fixture | `dart:io` `Directory.systemTemp` | Temp dir is cleaner for bootstrap tests -- no fixture cleanup issues |

**Installation:**
```bash
# mocktail needs to be promoted from transitive to direct dev_dependency
fvm flutter pub add --dev mocktail
```

**Version verification:** `bloc_test ^10.0.0` and `drift ^2.32.1` already declared in pubspec.yaml. `mocktail` resolved transitively -- needs explicit `^1.0.5` in dev_dependencies for direct import. [VERIFIED: pubspec.yaml, pubspec.lock]

## Architecture Patterns

### System Architecture Diagram

```
Bootstrap Script (tool/bootstrap.dart)
  --name AppName --bundle com.foo.app
         |
         v
  [Input Validation]
  (non-empty name, reverse-domain format)
         |
         v
  [Rename Pass] --> pubspec.yaml (name, description)
       |    |-----> lib/**/*.dart (package:skeleton -> package:app_name)
       |    |-----> android/app/build.gradle.kts (namespace, applicationId)
       |    |-----> android/.../MainActivity.kt (package declaration)
       |    |-----> android/.../kotlin/com/example/skeleton/ -> .../com/foo/app/ (dir rename)
       |    |-----> android/app/src/main/AndroidManifest.xml (android:label)
       |    |-----> ios/Runner.xcodeproj/project.pbxproj (PRODUCT_BUNDLE_IDENTIFIER x3)
       |    |-----> ios/Runner/Info.plist (CFBundleDisplayName, CFBundleName)
       |    |-----> README.md (title)
       |    |-----> lib/core/database/app_database.dart (driftDatabase name)
       |
       v
  [Post-Run Checklist] --> stdout
```

```
Test Architecture
  test/
  |- features/home_page/
  |   |- home_cubit_test.dart      (bloc_test + mocktail)
  |   |- counter_repository_test.dart (Drift NativeDatabase.memory)
  |- tool/
      |- bootstrap_test.dart        (fixture copy + flutter analyze)
```

### Recommended Project Structure
```
tool/
  bootstrap.dart              # Bootstrap rename script
test/
  features/
    home_page/
      home_cubit_test.dart    # Cubit test template
      counter_repository_test.dart  # Repository test template
  tool/
    bootstrap_test.dart       # Bootstrap E2E test
  helpers/
    pump_app.dart             # (future) Widget test helper
```

### Pattern 1: Bootstrap Rename Script
**What:** Pure Dart CLI that reads file contents, applies string replacements, and writes back. Handles directory renames for Android Kotlin package structure.
**When to use:** One-time on clone to customize the skeleton.
**Key design decisions:**
- Derive the Dart package name from `--name` by converting to `snake_case` (e.g., `MyApp` -> `my_app`) [ASSUMED]
- Derive display name from `--name` as-is (preserving casing)
- Bundle ID from `--bundle` used directly for Android `applicationId` and iOS `PRODUCT_BUNDLE_IDENTIFIER`
- Android namespace = bundle ID (same as applicationId per current config)
- Kotlin directory structure must be physically renamed: `android/app/src/main/kotlin/com/example/skeleton/` -> path matching new bundle ID

### Pattern 2: ARB Template Switch
**What:** 3-file edit: `l10n.yaml` template-arb-file change, add `untranslated-messages-file`, gitignore the output.
**When to use:** This phase only.
**Current state:**
- `l10n.yaml`: `template-arb-file: app_pl.arb` (needs -> `app_en.arb`)
- `app_en.arb`: 24 keys, `@@locale: "en"` [VERIFIED: codebase]
- `app_pl.arb`: 24 keys, `@@locale: "pl"` [VERIFIED: codebase]
- Keys are identical in both files -- reconciliation confirms no drift [VERIFIED: codebase]

**Changes needed:**
1. `l10n.yaml`: change `template-arb-file: app_pl.arb` to `template-arb-file: app_en.arb`
2. `l10n.yaml`: add `untranslated-messages-file: untranslated_messages.txt`
3. `.gitignore`: add `untranslated_messages.txt`
4. `app_en.arb`: add `@` description metadata for each key (template file convention) [ASSUMED -- optional but standard practice]

### Pattern 3: Post-Bootstrap Checklist
**What:** Printed to stdout after successful rename.
**Content covers (per D-05 + TOOL-02):**
1. Create Firebase projects (e.g., `<name>-dev`, `<name>-prod` if using flavors, or single project)
2. Register Android + iOS apps in each Firebase project with correct bundle IDs
3. Download `google-services.json` -> `android/app/`
4. Download `GoogleService-Info.plist` -> `ios/Runner/`
5. Run `flutterfire configure --project=<project-id>`
6. Register SHA-1 fingerprints (debug + release keystores)
7. Apple: enable "Sign in with Apple" capability in Xcode
8. Apple: configure Services ID for Sign in with Apple
9. Add reversed client ID to `ios/Runner/Info.plist` URL schemes

### Pattern 4: Bootstrap E2E Test Strategy
**What:** Test creates a temporary copy of the project, runs the bootstrap script against it, then verifies the result.
**Key considerations:**
- Test must copy the entire project to a temp directory [VERIFIED: dart:io Directory.systemTemp]
- After rename: run `flutter analyze` to verify no broken imports
- TOOL-07 says "verified flutter build apk --flavor dev" but flavors were dropped from scope -- verify `flutter analyze` is sufficient [ASSUMED]
- Test timeout needs to be generous (analyze can take 30-60 seconds)
- Generated files (*.g.dart, *.gr.dart, *.config.dart) contain hardcoded `package:skeleton` -- bootstrap must handle these OR they are regenerated after rename

### Anti-Patterns to Avoid
- **Shell-dependent bootstrap:** Don't use `sed`, `grep`, or other shell commands -- pure Dart per D-03
- **Regex for structured files:** Don't regex-parse `build.gradle.kts` or `project.pbxproj` -- use targeted string replacement on known patterns
- **Testing with real Flutter project:** Don't run `flutter build` in CI tests -- `flutter analyze` is sufficient and 10x faster

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Cubit state testing | Manual stream subscription + expect | `blocTest<C,S>()` from `bloc_test` | Handles stream lifecycle, seed state, timeout, act/expect separation |
| Mock generation | Hand-written stub classes | `mocktail` `Mock` + `when()`/`verify()` | Type-safe, concise, no codegen overhead |
| In-memory SQLite for tests | Mock the database layer | `NativeDatabase.memory()` from `drift/native.dart` | Tests real SQL queries, not mock behavior |
| Bundle ID validation | Custom regex | Standard reverse-domain regex `^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$` | Well-established pattern |

**Key insight:** The counter feature tests should exercise real Drift queries (not mocked) at the repository level, and mock only the service/repository boundary at the cubit level. This catches both business logic bugs (cubit) and query bugs (repository) without coupling them.

## Common Pitfalls

### Pitfall 1: Forgetting Generated Files in Bootstrap Rename
**What goes wrong:** `package:skeleton` appears in generated files (`injection.config.dart`, `router.gr.dart`, `app_database.g.dart`, localization files). If the bootstrap script doesn't touch these, the renamed project won't compile.
**Why it happens:** Generated files are excluded from analysis but still need correct import paths.
**How to avoid:** The bootstrap script must either (a) rename `package:skeleton` in ALL `.dart` files including generated ones, or (b) the post-bootstrap instructions tell the user to run `build_runner` to regenerate. Option (a) is simpler -- just replace in all `.dart` files under `lib/`.
**Warning signs:** `flutter analyze` fails with "target URI doesn't exist" errors.

### Pitfall 2: Android Kotlin Directory Must Be Physically Moved
**What goes wrong:** Changing `package com.example.skeleton` in `MainActivity.kt` isn't enough -- the file must physically live at `android/app/src/main/kotlin/com/foo/app/MainActivity.kt` matching the new bundle ID.
**Why it happens:** Android/Kotlin requires directory structure to match package declaration.
**How to avoid:** Bootstrap script must: (1) create new directory path, (2) move `MainActivity.kt` with updated package, (3) delete old empty directories.
**Warning signs:** Android build fails with "Source file not found" or "Package does not match directory".

### Pitfall 3: Drift NativeDatabase.memory() Requires sqlite3 Native Library
**What goes wrong:** `NativeDatabase.memory()` needs the native `sqlite3` library available at test time. On macOS this works out of the box (system SQLite). On Linux CI it may need `libsqlite3-dev`.
**Why it happens:** Drift's `NativeDatabase` uses FFI to call native SQLite, not a Dart-only implementation.
**How to avoid:** For local dev on macOS: works automatically. For CI: ensure `sqlite3` is installed. [VERIFIED: Context7 drift docs]
**Warning signs:** `Failed to load dynamic library 'libsqlite3.so'` at test time.

### Pitfall 4: Localization Generated Files Are Excluded from Analysis
**What goes wrong:** `analysis_options.yaml` excludes `lib/core/localization/app_localizations*.dart`. These generated files also contain `package:skeleton` imports. Bootstrap must rename in these files too, or they must be regenerated.
**Why it happens:** The exclude pattern means `flutter analyze` won't catch broken imports in these files.
**How to avoid:** Bootstrap renames in ALL `.dart` files regardless of analysis exclusion. Alternatively, regenerate with `flutter gen-l10n` post-rename.
**Warning signs:** Runtime crash on first localization access.

### Pitfall 5: iOS project.pbxproj Has Multiple Bundle ID Entries
**What goes wrong:** The `project.pbxproj` file contains `PRODUCT_BUNDLE_IDENTIFIER = com.example.skeleton` in 3 build configurations (Debug, Profile, Release) plus 3 for RunnerTests. Missing any one causes a build mismatch.
**Why it happens:** Xcode uses per-configuration settings.
**How to avoid:** Replace ALL occurrences of `com.example.skeleton` in `project.pbxproj`, not just the first.
**Warning signs:** iOS build signs with wrong bundle ID or RunnerTests fail to find the host app.

### Pitfall 6: Database Name in Drift driftDatabase()
**What goes wrong:** `app_database.dart` calls `driftDatabase(name: 'skeleton_db')`. If the bootstrap doesn't update this, the database file name still says "skeleton" on disk.
**Why it happens:** It's a string literal, not a package import.
**How to avoid:** Bootstrap should replace `'skeleton_db'` with `'<new_name>_db'` in `app_database.dart`.
**Warning signs:** Cosmetic only -- app works fine but database file has wrong name.

## Code Examples

### Bootstrap Script Structure
```dart
// Source: dart:io API [VERIFIED: Dart SDK docs]
import 'dart:io';

void main(List<String> args) {
  // Parse args
  final name = _parseArg(args, '--name');
  final bundle = _parseArg(args, '--bundle');

  // Validate
  _validateName(name);
  _validateBundle(bundle);

  // Derive values
  final dartPackage = _toSnakeCase(name);
  final displayName = name;

  // Execute rename
  _renameDartPackage(dartPackage);
  _renameAndroidConfig(bundle, displayName);
  _renameAndroidKotlinDir(bundle);
  _renameIosConfig(bundle, displayName);
  _renamePubspec(dartPackage, displayName);
  _renameReadme(displayName);
  _renameDriftDatabase(dartPackage);

  // Print checklist
  _printChecklist(name, bundle);
}
```

### Bundle ID Validation
```dart
// Source: Standard reverse-domain format [ASSUMED]
void _validateBundle(String bundle) {
  final pattern = RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*){2,}$');
  if (!pattern.hasMatch(bundle)) {
    stderr.writeln(
      'Invalid bundle ID: "$bundle". '
      'Expected reverse-domain format (e.g., com.example.myapp).',
    );
    exit(1);
  }
}
```

### Cubit Test with bloc_test + mocktail
```dart
// Source: Context7 bloclibrary.dev [VERIFIED]
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:skeleton/core/errors/result.dart';
import 'package:skeleton/features/home_page/data/model/counter_model.dart';
import 'package:skeleton/features/home_page/domain/counter_service.dart';
import 'package:skeleton/features/home_page/presentation/cubit/home_cubit.dart';

class MockCounterService extends Mock implements CounterService {}

void main() {
  late MockCounterService mockService;

  setUp(() {
    mockService = MockCounterService();
    // Register fallback values for mocktail any() matchers
    registerFallbackValue(const CounterModel(value: 0));
  });

  group('HomeCubit', () {
    blocTest<HomeCubit, HomeState>(
      'emits [success] when init finds existing counter',
      build: () {
        when(() => mockService.getCounter()).thenAnswer(
          (_) async => const Success(CounterModel(value: 5)),
        );
        when(() => mockService.watchCounter()).thenAnswer(
          (_) => Stream.value(const Success(CounterModel(value: 5))),
        );
        return HomeCubit(mockService);
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        isA<HomeState>()
            .having((s) => s.status, 'status', HomePageStatus.success)
            .having((s) => s.counter.value, 'counter', 5),
      ],
    );
  });
}
```

### Drift Repository Test with NativeDatabase.memory()
```dart
// Source: Context7 drift testing docs [VERIFIED]
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeleton/core/database/app_database.dart';
import 'package:skeleton/features/home_page/data/local_database/counter_local_database.dart';
import 'package:skeleton/features/home_page/data/model/counter_model.dart';
import 'package:skeleton/features/home_page/data/repository/counter_repository.dart';

void main() {
  late AppDatabase db;
  late CounterLocalDataBaseImpl dataSource;
  late CounterRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dataSource = CounterLocalDataBaseImpl(db);
    repository = CounterRepositoryImpl(dataSource);
  });

  tearDown(() async {
    await db.close();
  });

  group('CounterRepository', () {
    test('getCounter returns Failure when no data exists', () async {
      final result = await repository.getCounter();
      expect(result, isA<Failure<CounterModel>>());
    });

    test('setCounter then getCounter returns Success', () async {
      await repository.setCounter(
        counter: const CounterModel(value: 42),
      );
      final result = await repository.getCounter();
      expect(result, isA<Success<CounterModel>>());
    });
  });
}
```

## Bootstrap Rename Targets

Complete inventory of files/locations containing `skeleton` that the bootstrap script must handle:

### Dart Package Imports (31 files)
All files in `lib/` importing `package:skeleton/...` -- replace with `package:<new_name>/...`. [VERIFIED: grep]

### Android
| File | Target | Current Value |
|------|--------|---------------|
| `android/app/build.gradle.kts` | `namespace` | `com.example.skeleton` |
| `android/app/build.gradle.kts` | `applicationId` | `com.example.skeleton` |
| `android/app/src/main/AndroidManifest.xml` | `android:label` | `skeleton` |
| `android/app/src/main/kotlin/com/example/skeleton/MainActivity.kt` | `package` declaration | `com.example.skeleton` |
| `android/app/src/main/kotlin/com/example/skeleton/` | Directory path | Must match new bundle ID |

[VERIFIED: grep across android/]

### iOS
| File | Target | Current Value |
|------|--------|---------------|
| `ios/Runner.xcodeproj/project.pbxproj` | `PRODUCT_BUNDLE_IDENTIFIER` (x6) | `com.example.skeleton` (x3 Runner, x3 RunnerTests) |
| `ios/Runner/Info.plist` | `CFBundleDisplayName` | `Skeleton` |
| `ios/Runner/Info.plist` | `CFBundleName` | `skeleton` |

[VERIFIED: grep across ios/]

### Project Root
| File | Target | Current Value |
|------|--------|---------------|
| `pubspec.yaml` | `name:` | `skeleton` |
| `pubspec.yaml` | `description:` | Contains "Skeleton" |
| `README.md` | Title line | `# Skeleton - Flutter App Template` |
| `lib/core/database/app_database.dart` | `driftDatabase(name:)` | `'skeleton_db'` |

[VERIFIED: codebase inspection]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `mockito` + `build_runner` | `mocktail` (no codegen) | 2022 | Faster test iteration, no generated mock files |
| `Either<Failure,T>` from `dartz` | Sealed `Result<T>` | Phase 2 (this project) | Tests use `isA<Success>()` / `isA<Failure>()` pattern matching |
| ObjectBox testing | Drift `NativeDatabase.memory()` | Phase 2 (this project) | In-memory SQLite for tests, no temp file cleanup |
| `flutter_lints` | `very_good_analysis` | Phase 2 (this project) | Stricter rules, already configured |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Derive Dart package name from `--name` via snake_case conversion | Pattern 1 | Low -- standard Dart convention, but user may prefer a different mapping |
| A2 | `flutter analyze` is sufficient for bootstrap E2E test (no `flutter build apk`) | Pattern 4 | Medium -- TOOL-07 mentions APK build, but flavors are dropped; analyze catches import errors |
| A3 | `mocktail ^1.0.5` is the correct version constraint for direct dev_dependency | Standard Stack | Low -- lockfile already resolves mocktail transitively |
| A4 | Optional: EN ARB template file should have `@key` description metadata | Pattern 2 | Low -- descriptions are conventional but not required for gen-l10n |
| A5 | Bundle ID regex allows underscores in segments | Code Examples | Low -- some Android apps use underscores; standard allows it |

## Open Questions

1. **Should bootstrap rename in generated files or instruct user to regenerate?**
   - What we know: Generated files (`*.g.dart`, `*.gr.dart`, `*.config.dart`, `app_localizations*.dart`) contain `package:skeleton` imports
   - What's unclear: Whether to rename in-place (simpler, works immediately) or add `flutter pub get && dart run build_runner build` to the post-bootstrap checklist
   - Recommendation: Rename in-place in ALL `.dart` files -- it's simpler and means `flutter analyze` passes immediately after bootstrap without requiring build_runner

2. **How should bootstrap handle the `driftDatabase(name:)` string?**
   - What we know: `app_database.dart` has `driftDatabase(name: 'skeleton_db')`
   - What's unclear: Should new name be `<package>_db` or just `app_db` (generic)?
   - Recommendation: Replace with `<dart_package_name>_db` for consistency

3. **Should TOOL-07 test run `flutter build apk` or just `flutter analyze`?**
   - What we know: TOOL-07 says "flutter build apk --flavor dev verified" but flavors are dropped from v1 scope
   - What's unclear: Whether `flutter analyze` alone is sufficient verification
   - Recommendation: Use `flutter analyze` only -- APK builds are slow (2-5 min) and depend on local Android SDK setup; `analyze` catches all import/type errors in under 30s

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test (SDK) + bloc_test 10.0.0 + mocktail (transitive) |
| Config file | none -- default Flutter test runner |
| Quick run command | `fvm flutter test --no-pub` |
| Full suite command | `fvm flutter test` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TOOL-01 | Bootstrap renames all targets | integration | `fvm flutter test test/tool/bootstrap_test.dart` | No -- Wave 0 |
| TOOL-02 | Bootstrap prints checklist | unit | `fvm flutter test test/tool/bootstrap_test.dart` | No -- Wave 0 |
| TOOL-04 | l10n.yaml uses EN template | manual | Verify `l10n.yaml` content after edit | N/A |
| TOOL-05 | untranslated-messages-file configured | manual | Verify `l10n.yaml` + `.gitignore` | N/A |
| TOOL-06 | Counter cubit + repository tests pass | unit/integration | `fvm flutter test test/features/home_page/` | No -- Wave 0 |
| TOOL-07 | Bootstrap E2E test passes | integration | `fvm flutter test test/tool/bootstrap_test.dart --timeout 120s` | No -- Wave 0 |

### Sampling Rate
- **Per task commit:** `fvm flutter test --no-pub`
- **Per wave merge:** `fvm flutter test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/features/home_page/home_cubit_test.dart` -- covers TOOL-06 (cubit tests)
- [ ] `test/features/home_page/counter_repository_test.dart` -- covers TOOL-06 (repository tests)
- [ ] `test/tool/bootstrap_test.dart` -- covers TOOL-01, TOOL-02, TOOL-07
- [ ] `mocktail` promoted to direct dev_dependency in pubspec.yaml
- [ ] `test/` directory created (does not exist yet)

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | no | N/A -- phase is tooling/testing only |
| V3 Session Management | no | N/A |
| V4 Access Control | no | N/A |
| V5 Input Validation | yes | Bootstrap script validates `--name` and `--bundle` inputs before file operations |
| V6 Cryptography | no | N/A |

### Known Threat Patterns

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Path traversal via `--name` input | Tampering | Validate name contains only alphanumeric chars; reject `/`, `..`, shell metacharacters |
| Malicious bundle ID | Tampering | Regex validation before any file writes |

Note: This phase has minimal security surface -- the bootstrap script runs locally by the developer, not in production. Input validation is defense-in-depth.

## Sources

### Primary (HIGH confidence)
- Context7 `/simolus3/drift` -- Drift testing with NativeDatabase.memory() patterns
- Context7 `/websites/bloclibrary_dev` -- bloc_test + mocktail cubit testing patterns
- Codebase inspection -- pubspec.yaml, pubspec.lock, l10n.yaml, ARB files, build configs, all lib/ Dart files

### Secondary (MEDIUM confidence)
- [pub.dev/packages/mocktail](https://pub.dev/packages/mocktail) -- Package metadata
- [pub.dev/packages/bloc_test](https://pub.dev/packages/bloc_test) -- Package metadata

### Tertiary (LOW confidence)
- None

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all packages already in pubspec.yaml/lock, versions verified
- Architecture: HIGH -- bootstrap targets fully inventoried via grep, test patterns verified via Context7
- Pitfalls: HIGH -- based on direct codebase inspection (generated files, pbxproj entries, Kotlin dir structure)

**Research date:** 2026-04-18
**Valid until:** 2026-05-18 (stable domain, no fast-moving dependencies)
