---
phase: 04-firebase-wiring-auth-providers
plan: 01
subsystem: firebase-deps-di-environment
tags: [firebase, bom-4.12.0, di, environment, stub]
dependency_graph:
  requires: []
  provides: [firebase-bom-4.12.0, stub-firebase-options, di-environment-param]
  affects: [pubspec.yaml, lib/firebase_options.dart, lib/core/injectable/injection.dart, lib/core/auth/fake_auth_service.dart, lib/core/injectable/injection.config.dart]
tech_stack:
  added: [firebase_auth ^6.4.0, google_sign_in ^7.2.0, sign_in_with_apple ^7.0.1, crypto ^3.0.6]
  patterns: [di-environment-switching, stub-firebase-options]
key_files:
  created: [lib/firebase_options.dart]
  modified: [pubspec.yaml, pubspec.lock, lib/core/injectable/injection.dart, lib/core/auth/fake_auth_service.dart, lib/core/injectable/injection.config.dart]
decisions:
  - "Default DI environment is 'dev' — FakeAuthService registered only in dev, prod requires explicit environment override"
metrics:
  duration: 125s
  completed: 2026-04-17T16:24:52Z
---

# Phase 4 Plan 01: Firebase BoM 4.12.0 Deps + DI Environment Wiring Summary

All 7 Firebase packages pinned to BoM 4.12.0 matrix, 4 new auth dependencies added, stub firebase_options.dart enables fresh-clone compilation, and DI environment parameter gates FakeAuthService to 'dev' so downstream plans can register FirebaseAuthService under 'prod'.

## Task Results

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Bump Firebase packages to BoM 4.12.0 and add new auth dependencies | 517a224 | pubspec.yaml, pubspec.lock |
| 2 | Create stub firebase_options.dart and wire DI environment parameter | e1e668d | lib/firebase_options.dart, lib/core/injectable/injection.dart, lib/core/auth/fake_auth_service.dart, lib/core/injectable/injection.config.dart |

## Changes Made

### Task 1: Firebase BoM 4.12.0 + Auth Dependencies
- Bumped 6 existing Firebase packages to BoM 4.12.0 matrix versions:
  - firebase_core ^4.7.0, cloud_firestore ^6.3.0, firebase_crashlytics ^5.2.0
  - firebase_analytics ^12.3.0, firebase_performance ^0.11.3, firebase_app_check ^0.4.3
- Added 4 new dependencies: firebase_auth ^6.4.0, google_sign_in ^7.2.0, sign_in_with_apple ^7.0.1, crypto ^3.0.6
- `flutter pub get` resolves cleanly with all 10 packages

### Task 2: Stub firebase_options.dart + DI Environment
- Created `lib/firebase_options.dart` stub with `DefaultFirebaseOptions.currentPlatform` throwing `UnsupportedError` — allows compilation without `flutterfire configure`
- Updated `configureDependenciesApp()` to accept `{String environment = 'dev'}` and forward to `$initGetIt`
- Annotated `FakeAuthService` with `env: [Environment.dev]` so it only registers in dev environment
- Regenerated `injection.config.dart` — confirms `registerFor: {_dev}` filter on FakeAuthService

## Decisions Made

- **DI environment default is 'dev'**: Ensures fresh clones without Firebase config get FakeAuthService automatically. Plans 02-03 will register FirebaseAuthService under 'prod' and StartUpService will pass the environment based on Firebase.initializeApp success/failure (per D-01).

## Deviations from Plan

None — plan executed exactly as written.

## Verification Results

- `flutter pub get` exits 0 with all BoM 4.12.0 packages resolved
- `flutter analyze --no-fatal-infos` passes (2 pre-existing info-level deprecation warnings in startup_service.dart about `androidProvider`/`appleProvider` renamed params — not caused by this plan)
- All 10 dependency version constraints verified in pubspec.yaml
- Generated injection.config.dart contains `const String _dev = 'dev'` and `registerFor: {_dev}` on FakeAuthService

## Threat Flags

None found — no new network endpoints, auth paths, or trust boundary changes beyond those documented in the plan's threat model.

## Self-Check: PASSED
