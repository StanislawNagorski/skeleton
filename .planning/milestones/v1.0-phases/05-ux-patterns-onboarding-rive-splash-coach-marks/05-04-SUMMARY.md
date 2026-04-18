---
phase: 05-ux-patterns-onboarding-rive-splash-coach-marks
plan: 04
subsystem: coach-marks, home-page, navigation
tags: [tutorial-coach-mark, coach-mark-service, rive-demo-nav, globalkey, first-visit-tour]
dependency_graph:
  requires: [05-01]
  provides: [CoachMarkService, home-page-coach-marks, rive-demo-navigation]
  affects: [injection.config.dart, home_page.dart]
tech_stack:
  added: []
  patterns: [lazySingleton-coach-mark-service, globalkey-coach-targets, addPostFrameCallback-tour-trigger, cascade-invocation]
key_files:
  created:
    - lib/core/coach_mark/coach_mark_service.dart
  modified:
    - lib/features/home_page/presentation/home_page.dart
    - lib/core/injectable/injection.config.dart
decisions:
  - "Coach mark strings hardcoded in English in initState (context unavailable) -- downstream apps localize via didChangeDependencies"
  - "CoachMarkService is a concrete @lazySingleton (no abstract interface) per PATTERNS.md single-impl guidance"
metrics:
  duration: 218s
  completed: 2026-04-18
  tasks: 2
  files: 3
---

# Phase 5 Plan 04: Coach Marks and RIVE Demo Navigation Summary

CoachMarkService wrapping tutorial_coach_mark with register/showTour/unregister API, preference-backed first-visit persistence, two-target demo tour on home page (counter display + FAB), and OutlinedButton navigating to RiveDemoRoute.

## Task Completion

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | CoachMarkService wrapper | 1cb8f6a | lib/core/coach_mark/coach_mark_service.dart, injection.config.dart |
| 2 | Home page modifications (GlobalKeys, coach mark trigger, RIVE Demo button) | b9ad563 | lib/features/home_page/presentation/home_page.dart |
| - | Lint fixes for coach_mark_service | 3d575e1 | lib/core/coach_mark/coach_mark_service.dart |
| 3 | End-to-end verification (checkpoint:human-verify) | -- | Pending human verification |

## What Was Built

### Task 1: CoachMarkService Wrapper
- Created `lib/core/coach_mark/coach_mark_service.dart` as `@lazySingleton` service
- `register(tourId, key, description, {title})` adds targets to a tour by ID
- `showTour(tourId, context)` checks `tour_{tourId}_seen` preference flag and returns early if already completed
- Tour display wrapped in `addPostFrameCallback` for layout safety (Pitfall 3)
- `onFinish` callback persists `tour_{tourId}_seen = true` via PreferencesService
- Coach mark tooltip uses `surfaceContainerHighest` background with `radiusMedium` corners
- Targets use `ShapeLightFocus.RRect` with `radiusMedium` radius and padding
- `unregister(tourId)` clears targets to prevent stale GlobalKey references
- Registered in DI container via build_runner (injection.config.dart updated)

### Task 2: Home Page Modifications
- Converted `_Page` from `StatelessWidget` to `StatefulWidget` for lifecycle management
- Added `GlobalKey _counterKey` on counter display Text widget
- Added `GlobalKey _fabKey` on increment FloatingActionButton
- `initState` registers two coach mark targets with cascade syntax
- `initState` triggers `showTour('home', context)` via `addPostFrameCallback`
- `dispose` calls `unregister('home')` for cleanup
- Added `OutlinedButton.icon` with `Icons.animation` navigating to `RiveDemoRoute`
- Button uses `context.localizations.homePage_riveDemoButton` localized label

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed cascade_invocations lint**
- **Found during:** Task 2
- **Issue:** Two consecutive `_coachMarkService.register()` calls triggered `cascade_invocations` info lint
- **Fix:** Refactored to cascade syntax (`..register()`)
- **Files modified:** lib/features/home_page/presentation/home_page.dart
- **Commit:** b9ad563

**2. [Rule 1 - Bug] Fixed multiple lint warnings in coach_mark_service**
- **Found during:** Post-Task 2 verification
- **Issue:** `use_if_null_to_convert_nulls_to_bools`, `avoid_redundant_argument_values` (ContentAlign.bottom, Colors.black defaults), `directives_ordering`, `lines_longer_than_80_chars`, `comment_references`
- **Fix:** Applied if-null operator, removed redundant defaults, sorted imports, wrapped long lines, used backtick for non-scope references
- **Files modified:** lib/core/coach_mark/coach_mark_service.dart
- **Commit:** 3d575e1

## Known Stubs

None -- all code in this plan is functional, not placeholder.

## Verification Results

- `fvm flutter analyze` exits 0 on all plan files (coach_mark_service.dart, home_page.dart)
- `injection.config.dart` contains `CoachMarkService` lazySingleton registration
- Home page has GlobalKeys on counter text (`_counterKey`) and FAB (`_fabKey`)
- Coach mark tour registered with 2 targets for tour ID 'home'
- RIVE Demo button present with `RiveDemoRoute` navigation
- Task 3 (checkpoint:human-verify) pending -- requires on-device verification

## Self-Check: PASSED
