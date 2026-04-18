# Phase 7: Documentation - Pattern Map

**Mapped:** 2026-04-18
**Files analyzed:** 3 (new/modified markdown files)
**Analogs found:** 3 / 3

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `README.md` | config (project docs) | N/A (static) | `README.md` (current, being rewritten) | exact (rewrite-in-place) |
| `docs/rebase-runbook.md` | config (runbook) | N/A (static) | `.planning/rebase_manifest.md` | role-match |
| `docs/upgrade-playbook.md` | config (playbook) | N/A (static) | `.planning/rebase_manifest.md` | partial |

## Pattern Assignments

### `README.md` (full rewrite)

**Analog:** Current `README.md` (lines 170-275 — Firebase Setup section is the only current content to preserve and integrate)

**Section to preserve** (lines 170-275 of current README):
The entire `## Firebase Setup` section was rewritten in Phase 4 and is accurate. It covers:
- Prerequisites + FlutterFire CLI install
- `flutterfire configure` usage
- Google Sign-In (Android SHA-1 + iOS reversed client ID)
- Apple Sign-In (Xcode capability + Services ID)
- App Check (release-only, Play Integrity + App Attest)
- Crashlytics wiring
- Dev Mode fallback

This section should be incorporated into the new README structure under `## Firebase Integration`, not duplicated.

**Section to preserve** (lines 47-81 of current README):
The `## Release Signing` section (added in Phase 1) is accurate and current. Incorporate as-is.

**Sections to discard entirely:**
- Lines 1-45: Old manual package renaming instructions — replaced by bootstrap script
- Lines 83-96: Old troubleshooting referencing `flutter_lints`, manual pod cache cleaning
- Lines 97-118: Architecture section — accurate in structure but needs update (references `dartz`, ObjectBox)
- Lines 119-168: Packages section — lists `dartz`, `objectbox`, `device_info_plus`, `flutter_lints` (all replaced)
- Lines 277-282: Old changelog — no longer relevant after full refresh

**Bootstrap script usage** (from `tool/bootstrap.dart` lines 1-10):
```
Usage:
  dart run tool/bootstrap.dart --name MyApp --bundle com.example.myapp

Renames the Dart package, Android config, iOS config, pubspec, README,
and Drift database name in a single pass. Prints a Firebase setup
checklist after successful rename.
```

**Bootstrap post-run checklist** (from `tool/bootstrap.dart` lines 306-327):
```
Next steps:
  1. Run: fvm flutter pub get
  2. Run: dart run build_runner build --delete-conflicting-outputs
  3. Create a Firebase project at https://console.firebase.google.com
  4. Register Android app with package name: $bundleId
  5. Register iOS app with bundle ID: $bundleId
  6. Download google-services.json -> android/app/
  7. Download GoogleService-Info.plist -> ios/Runner/
  8. Run: flutterfire configure --project=<your-firebase-project-id>
  9. Register SHA-1 fingerprints:
     - Debug:   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android
     - Release: keytool -list -v -keystore <your-release-keystore> -alias <your-alias>
  10. Apple Sign-in: Enable "Sign in with Apple" capability in Xcode
  11. Apple Sign-in: Configure Services ID at https://developer.apple.com
  12. Run: fvm flutter run
```

**AuthService contract** (from `lib/core/auth/auth_service.dart` lines 10-40):
```dart
abstract class AuthService {
  Stream<AuthUser?> get authStateChanges;
  AuthUser? get currentUser;
  Future<AuthResult> signInWithEmail({required String email, required String password});
  Future<AuthResult> signUpWithEmail({required String email, required String password});
  Future<AuthResult> signInWithGoogle();
  Future<AuthResult> signInWithApple();
  Future<void> signOut();
  Future<AuthResult> sendPasswordReset({required String email});
}
```

**Dev/prod fallback** (from `lib/startup_service.dart` lines 27-50):
```dart
static Future<void> initServices() async {
  var environment = 'dev';
  await RiveNative.init();
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    environment = 'prod';
    _configureCrashlytics();
    await _configureAppCheck();
  } on Object catch (e) {
    _logger.w('Firebase not configured: $e. Running in dev mode.');
  }
  await configureDependenciesApp(environment: environment);
}
```

**Architecture description source:** `CLAUDE.md` `## Architecture` section contains the authoritative layer descriptions (data/domain/presentation + core), data flow (Cubit + state + status enum), and key abstractions (Failure, abstract+Impl, ObjectBox store, AppRouter). The README architecture section should summarize these, not repeat them verbatim.

**Version matrix source** (from `.planning/rebase_manifest.md` lines 64-74):

| Component | Version |
|-----------|---------|
| Flutter SDK | 3.41.5 |
| Dart SDK | ^3.9.0 (actual 3.11.3) |
| AGP | 8.11.1 |
| Kotlin | 2.2.20 |
| Gradle | 8.14 |
| iOS Podfile floor | 15.0 |

---

### `docs/rebase-runbook.md` (new file)

**Analog:** `.planning/rebase_manifest.md` (structure: checklist with verification)

**Structure pattern** (from `.planning/rebase_manifest.md` lines 1-6):
```markdown
# Rebase Manifest: Phase 1 -- Native Rebase

**Date:** 2026-04-16
**Flutter SDK:** 3.41.5 (via FVM)
**Branch:** 2026-update
```

**Checklist pattern** (from `.planning/rebase_manifest.md` lines 9-17):
```markdown
## Actions Taken

### FVM + SDK
- [x] `.fvmrc` bumped from `3.29.0` to `3.41.5` (D-05)
- [x] `fvm install 3.41.5 && fvm use 3.41.5` run before scaffold generation (D-05)

### Native Directory Swap
- [x] `android/` replaced with fresh `flutter create --platforms=android,ios` output (D-02)
```

**Source material for runbook steps:**
- Phase 1 Plan 01 (`.planning/phases/01-native-rebase/01-01-PLAN.md`): Tasks 1-3 cover the full rebase procedure:
  - Task 1 (lines 88-141): FVM bump, `flutter create --platforms=android,ios` in temp dir
  - Task 2 (lines 144-229): Delete old dirs, copy fresh scaffold, Podfile floor bump, pubspec env update
  - Task 3 (lines 248-307): Regenerate lockfiles, build_runner, pod install, flutter analyze
- Phase 1 Plan 02 (`.planning/phases/01-native-rebase/01-02-PLAN.md`): Task 1 covers release signing scaffolding
- Rebase manifest (`.planning/rebase_manifest.md`): Records actual decisions made, including deviations from plan (e.g., Kotlin DSL instead of Groovy, l10n import migration)

**Runbook should transform plan tasks into numbered steps with:**
1. The command to run
2. What to verify after
3. What can go wrong (from plan's acceptance criteria and RESEARCH.md pitfalls)

---

### `docs/upgrade-playbook.md` (new file)

**Analog:** `.planning/rebase_manifest.md` (checklist-with-verification style)

**Checklist pattern** (same as runbook — numbered steps with verification commands):
```markdown
### FlutterFire BoM Bump

1. Update versions in `pubspec.yaml`:
   ```yaml
   firebase_core: ^X.Y.Z
   ```
2. Run: `fvm flutter pub get`
3. Verify: `fvm flutter analyze`
4. Runtime verify: Build release APK, install, check Firebase Console
```

**Source material for playbook topics:**

1. **FlutterFire BoM bump** — Phase 4 research/plans document the Firebase dependency matrix. Key files: `pubspec.yaml` (Firebase deps), `lib/startup_service.dart` (init sequence)
2. **App Check verification** — Current App Check wiring in `lib/startup_service.dart` lines 53-60+ (release-only activation via `kReleaseMode`)
3. **auto_route guard migration** — Phase 3 upgraded to auto_route 11 with `RootStackRouter` + guards property. Key file: `lib/core/router/router.dart`
4. **Drift schema migration** — Phase 2 replaced ObjectBox with Drift. Key file: `lib/core/database/app_database.dart`

---

## Shared Patterns

### Markdown Formatting Convention

**Source:** Current `README.md` (Firebase Setup section, lines 170-275)
**Apply to:** All three documentation files

The Firebase Setup section demonstrates the project's markdown style:
- Level 2 `##` for top sections, Level 3 `###` for subsections
- Numbered steps for procedures
- Fenced code blocks with language tags (`bash`, `xml`, `yaml`, `dart`)
- Tables for structured data (variables, providers)
- Blockquote `>` for notes/warnings
- Inline backticks for file paths, commands, and identifiers

### Cross-Reference Pattern

**Apply to:** README linking to docs/

The README should link to detailed procedures in `docs/` rather than inlining them:
```markdown
## Upgrading
See [Upgrade Playbook](docs/upgrade-playbook.md) for step-by-step checklists.

## Rebasing on a New Flutter Version
See [Rebase Runbook](docs/rebase-runbook.md) for the full procedure.
```

### Version Pinning Pattern

**Source:** `.planning/rebase_manifest.md` Version Matrix (lines 62-74)
**Apply to:** README prerequisites, runbook, playbook

Always pair version numbers with their source of truth:
```markdown
- Flutter `3.41.5` (pinned in `.fvmrc`)
- Dart `^3.9.0` (declared in `pubspec.yaml`)
```

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| (none) | -- | -- | All files have analogs or source material in the codebase |

## Key Content Sources Summary

The documentation phase draws from these existing files (planner should reference them in task `read_first` blocks):

| Content | Source File | Lines |
|---------|------------|-------|
| Bootstrap usage + post-run checklist | `tool/bootstrap.dart` | 1-10, 306-327 |
| AuthService contract | `lib/core/auth/auth_service.dart` | 10-40 |
| Dev/prod fallback | `lib/startup_service.dart` | 27-50 |
| Firebase Setup (preservable) | `README.md` | 170-275 |
| Release Signing (preservable) | `README.md` | 47-81 |
| Rebase procedure (actual) | `.planning/rebase_manifest.md` | 1-74 |
| Rebase procedure (planned steps) | `.planning/phases/01-native-rebase/01-01-PLAN.md` | 88-307 |
| Release signing scaffold | `.planning/phases/01-native-rebase/01-02-PLAN.md` | 86-198 |
| Architecture conventions | `CLAUDE.md` | Architecture section |
| Version matrix | `.planning/rebase_manifest.md` | 62-74 |

## Metadata

**Analog search scope:** Project root, `.planning/`, `lib/`, `tool/`, `docs/`
**Files scanned:** ~15 (markdown files + key Dart sources)
**Pattern extraction date:** 2026-04-18
