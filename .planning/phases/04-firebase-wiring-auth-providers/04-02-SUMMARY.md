---
phase: 04-firebase-wiring-auth-providers
plan: 02
subsystem: firebase-init-crashlytics-appcheck-di-module
tags: [firebase, crashlytics, app-check, di-module, startup]
dependency_graph:
  requires: [firebase-bom-4.12.0, stub-firebase-options, di-environment-param]
  provides: [firebase-init-with-fallback, crashlytics-error-handlers, app-check-release-only, firebase-di-module]
  affects: [lib/startup_service.dart, lib/core/firebase/firebase_module.dart, lib/core/injectable/injection.config.dart]
tech_stack:
  added: []
  patterns: [firebase-init-graceful-fallback, crashlytics-handler-trio, release-only-app-check, injectable-module-env-gating]
key_files:
  created: [lib/core/firebase/firebase_module.dart]
  modified: [lib/startup_service.dart, lib/core/injectable/injection.config.dart]
decisions:
  - "Catch Object (not Exception) in Firebase init -- stub throws UnsupportedError which extends Error"
  - "Use non-deprecated providerApple/providerAndroid params with typed AppleAppAttestProvider/AndroidPlayIntegrityProvider"
  - "Firestore persistence explicitly enabled via cascade on instance"
metrics:
  duration: 253s
  completed: 2026-04-17T16:31:33Z
---

# Phase 4 Plan 02: Firebase Init, Crashlytics, App Check, and DI Module Summary

StartUpService restructured with real Firebase.initializeApp and graceful dev fallback (catches UnsupportedError from stub), Crashlytics error handler trio (Flutter + PlatformDispatcher + Isolate), release-only App Check with appAttest/playIntegrity, and FirebaseModule registering Analytics/Performance/Firestore as prod-only lazy singletons in DI.

## Task Results

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Restructure StartUpService with Firebase init, Crashlytics, and App Check | 831097f | lib/startup_service.dart |
| 2 | Create FirebaseModule for Analytics, Performance, and Firestore DI registration | 1fc40d9 | lib/core/firebase/firebase_module.dart, lib/core/injectable/injection.config.dart |

## Changes Made

### Task 1: StartUpService Restructure
- Rewrote `lib/startup_service.dart` with try/catch around `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)`
- On success: sets environment to `'prod'`, wires Crashlytics and App Check
- On failure (UnsupportedError from stub or missing config): stays in `'dev'` mode, logs warning
- Catches `Object` instead of `Exception` because `UnsupportedError` extends `Error` (Rule 1 bug fix from plan)
- Crashlytics handler trio: `FlutterError.onError`, `PlatformDispatcher.instance.onError`, `Isolate.current.addErrorListener`
- `setCrashlyticsCollectionEnabled(kReleaseMode)` disables collection in debug
- App Check skips entirely in non-release mode (`if (!kReleaseMode) return`)
- Uses `AppleAppAttestProvider()` and `AndroidPlayIntegrityProvider()` (non-deprecated typed provider API)
- Removed unused `flutter/widgets.dart` import, fixed line lengths, used `var` per lint

### Task 2: FirebaseModule DI Registration
- Created `lib/core/firebase/firebase_module.dart` as `@module` abstract class
- Three `@lazySingleton` + `@Environment(Environment.prod)` getters: `FirebaseAnalytics`, `FirebasePerformance`, `FirebaseFirestore`
- Firestore getter uses cascade to set `persistenceEnabled: true`
- Regenerated `injection.config.dart` -- confirms `_$FirebaseModule` class and all three services with `registerFor: {_prod}`

## Decisions Made

- **Catch Object not Exception**: The plan specified `on Exception catch (e)` but the stub `firebase_options.dart` throws `UnsupportedError` (an `Error` subclass, not `Exception`). Changed to `on Object catch (e)` to ensure the dev fallback actually triggers.
- **Non-deprecated App Check API**: Used `providerApple: const AppleAppAttestProvider()` and `providerAndroid: const AndroidPlayIntegrityProvider()` instead of deprecated `appleProvider`/`androidProvider` enum params.
- **Explicit Firestore persistence**: Set `persistenceEnabled: true` even though it is the mobile default, for documentation clarity.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed catch clause type for Firebase init fallback**
- **Found during:** Task 1
- **Issue:** Plan specified `on Exception catch (e)` but `DefaultFirebaseOptions.currentPlatform` in the stub throws `UnsupportedError` which extends `Error`, not `Exception`. The dev fallback would never trigger.
- **Fix:** Changed to `on Object catch (e)` to catch both `Error` and `Exception` subtypes
- **Files modified:** lib/startup_service.dart
- **Commit:** 831097f

**2. [Rule 1 - Bug] Updated deprecated App Check provider parameters**
- **Found during:** Task 1
- **Issue:** Plan used deprecated `AppleProvider`/`AndroidProvider` enum values with old parameter names. The new BoM 4.12.0 version has `providerApple`/`providerAndroid` params expecting typed provider objects.
- **Fix:** Used `AppleAppAttestProvider()` and `AndroidPlayIntegrityProvider()` with new parameter names
- **Files modified:** lib/startup_service.dart
- **Commit:** 831097f

## Verification Results

- `fvm flutter analyze --no-fatal-infos` passes (1 remaining info: redundant default argument value -- intentionally explicit)
- `grep "Firebase.initializeApp" lib/startup_service.dart` confirms real init
- `grep "Isolate.current.addErrorListener" lib/startup_service.dart` confirms handler trio
- `grep "AppleAppAttestProvider" lib/startup_service.dart` confirms correct Apple provider
- `grep "FirebaseModule" lib/core/injectable/injection.config.dart` confirms DI registration
- All three Firebase services registered with `registerFor: {_prod}` in generated code

## Threat Flags

None found -- all security surfaces match the plan's threat model (T-04-03 through T-04-06).

## Self-Check: PASSED
