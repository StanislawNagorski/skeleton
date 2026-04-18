---
phase: 05-ux-patterns-onboarding-rive-splash-coach-marks
plan: 01
subsystem: routing, startup, localization, assets
tags: [rive, onboarding-guard, auth-guard-refactor, arb, preferences]
dependency_graph:
  requires: []
  provides: [OnboardingGuard, OnboardingRoute, RiveDemoRoute, PreferencesKeys, rive-runtime, tutorial-coach-mark-dep]
  affects: [router, startup-service, main, app]
tech_stack:
  added: [rive ^0.14.5, tutorial_coach_mark ^1.3.3]
  patterns: [pre-cached-guard-flag, per-route-auth-guard, listenable-merge-reevaluation, static-value-notifier]
key_files:
  created:
    - lib/core/preferences/preferences_keys.dart
    - lib/core/router/guards/onboarding_guard.dart
    - lib/features/onboarding/presentation/onboarding_page.dart
    - lib/features/rive_demo/presentation/rive_demo_page.dart
    - assets/images/onboarding/slide_1.webp
    - assets/images/onboarding/slide_2.webp
    - assets/images/onboarding/slide_3.webp
    - assets/rive/demo.riv
  modified:
    - pubspec.yaml
    - pubspec.lock
    - lib/startup_service.dart
    - lib/core/router/router.dart
    - lib/core/router/router.gr.dart
    - lib/main.dart
    - lib/app.dart
    - lib/core/presentation/app_dimensions.dart
    - lib/core/localization/app_en.arb
    - lib/core/localization/app_pl.arb
    - lib/core/localization/app_localizations.dart
    - lib/core/localization/app_localizations_en.dart
    - lib/core/localization/app_localizations_pl.dart
decisions:
  - "OnboardingGuard uses named parameter constructor with pre-cached bool to satisfy avoid_positional_boolean_parameters lint"
  - "AuthGuard moved from global guards list to per-route on LoginRoute only (D-04)"
  - "MyApp converted from StatelessWidget to StatefulWidget with static ValueNotifier for onboarding re-evaluation"
  - "Stub pages created for OnboardingPage and RiveDemoPage to enable build_runner code generation"
  - "demo.riv is an empty placeholder -- must be replaced with a real .riv file before RIVE demo page functions"
metrics:
  duration: 272s
  completed: 2026-04-18
  tasks: 2
  files: 22
---

# Phase 5 Plan 01: Foundation Wiring Summary

RIVE 0.14 runtime initialization, OnboardingGuard with pre-cached boolean flag, AuthGuard refactored from global to per-route on LoginRoute, 4 routes registered (home, onboarding, rive-demo, login), Listenable.merge composing auth + onboarding re-evaluation signals, 17 ARB entries in EN+PL, and placeholder assets for onboarding slides and RIVE demo.

## Task Completion

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | Dependencies, assets, constants, and ARB entries | 406b23c | pubspec.yaml, preferences_keys.dart, app_en.arb, app_pl.arb, app_dimensions.dart, assets/ |
| 2 | RIVE init, OnboardingGuard, router refactor, main/app wiring | cdc64e2 | startup_service.dart, onboarding_guard.dart, router.dart, main.dart, app.dart, stub pages |

## What Was Built

### Task 1: Dependencies and Static Assets
- Added `rive: ^0.14.5` and `tutorial_coach_mark: ^1.3.3` to pubspec.yaml
- Registered `assets/images/onboarding/` and `assets/rive/` in flutter assets
- Created `PreferencesKeys` with `hasSeenOnboarding` and `tourHomeCompleted` constants
- Added `spacingXXL` (48) and `spacingXXXL` (64) tokens to `AppDimensions`
- Added 17 new localization entries across both EN and PL ARB files covering onboarding slides, coach marks, and RIVE demo
- Created 3 minimal WebP placeholder images for onboarding slides
- Created empty `demo.riv` placeholder (must be replaced with real .riv file)

### Task 2: Runtime Wiring
- Added `await RiveNative.init()` in `StartUpService.initServices()` before Firebase init (UX-06)
- Created `OnboardingGuard` that checks a pre-cached `hasSeenOnboarding` boolean (no async I/O in `onNavigation` per Pitfall 1)
- Refactored `AuthGuard` from global `guards` list to per-route on `LoginRoute` only (D-04)
- Added `OnboardingRoute` (/onboarding), `RiveDemoRoute` (/rive-demo) to router
- Updated `main.dart` to pre-read onboarding flag via `PreferencesService` and inject into guard
- Converted `MyApp` from `StatelessWidget` to `StatefulWidget` with static `onboardingNotifier` (`ValueNotifier<bool>`)
- Composed `reevaluateListenable` via `Listenable.merge` combining auth stream + onboarding notifier
- Created stub pages for `OnboardingPage` and `RiveDemoPage` annotated with `@RoutePage()` for code generation
- Regenerated `router.gr.dart` with all 4 routes

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed avoid_positional_boolean_parameters lint**
- **Found during:** Task 2
- **Issue:** `OnboardingGuard(this._hasSeenOnboarding)` triggered `avoid_positional_boolean_parameters` info lint
- **Fix:** Changed to named parameter constructor: `OnboardingGuard({required bool hasSeenOnboarding})`
- **Files modified:** lib/core/router/guards/onboarding_guard.dart, lib/main.dart
- **Commit:** cdc64e2

**2. [Rule 1 - Bug] Fixed unnecessary_ignore lint**
- **Found during:** Task 2
- **Issue:** `// ignore: use_setters_to_change_properties` was not needed since the lint rule `use_setters_to_change_properties` is not active in this project's lint config
- **Fix:** Removed the ignore comment
- **Files modified:** lib/core/router/guards/onboarding_guard.dart
- **Commit:** cdc64e2

**3. [Rule 1 - Bug] Fixed comment_references lint warnings**
- **Found during:** Task 2
- **Issue:** Doc comments referenced `[PreferencesService]` and `[OnboardingCubit]` which are not in scope
- **Fix:** Changed to backtick references instead of bracket references
- **Files modified:** lib/core/preferences/preferences_keys.dart, lib/app.dart
- **Commit:** cdc64e2

## Known Stubs

| File | Line | Description | Resolution |
|------|------|-------------|------------|
| lib/features/onboarding/presentation/onboarding_page.dart | 9 | Stub page with placeholder text | Plan 02 replaces with full onboarding implementation |
| lib/features/rive_demo/presentation/rive_demo_page.dart | 9 | Stub page with placeholder text | Plan 03 replaces with full RIVE demo implementation |
| assets/rive/demo.riv | - | Empty file, not a valid .riv binary | Plan 03 must provide a real .riv file |
| assets/images/onboarding/slide_*.webp | - | 1x1 transparent pixel placeholders | Replaced per-app post-bootstrap |

## Verification Results

- `fvm flutter pub get` exits 0
- `dart run build_runner build --delete-conflicting-outputs` exits 0
- `fvm flutter analyze` exits 0 (1 pre-existing info in startup_service.dart:108, not from this plan)
- `router.gr.dart` contains `OnboardingRoute` and `RiveDemoRoute`
- All 4 routes present: `/`, `/onboarding`, `/rive-demo`, `/login`
- Only `OnboardingGuard` in global guards list
- `AuthGuard` only on `/login` route

## Self-Check: PASSED

All 10 key files verified present. Both task commits (406b23c, cdc64e2) verified in git log.
