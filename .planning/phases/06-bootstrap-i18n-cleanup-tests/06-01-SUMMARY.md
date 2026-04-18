---
phase: 06-bootstrap-i18n-cleanup-tests
plan: 01
subsystem: localization, testing
tags: [l10n, arb, bloc_test, mocktail, drift, testing]
dependency_graph:
  requires: []
  provides: [en-arb-template, cubit-test-template, repository-test-template, mocktail-dev-dep]
  affects: [l10n.yaml, .gitignore, pubspec.yaml, test/]
tech_stack:
  added: [mocktail ^1.0.5]
  patterns: [bloc_test + mocktail cubit testing, Drift NativeDatabase.memory repository testing, captureAny for non-Equatable models]
key_files:
  created:
    - test/features/home_page/home_cubit_test.dart
    - test/features/home_page/counter_repository_test.dart
  modified:
    - l10n.yaml
    - .gitignore
    - pubspec.yaml
    - pubspec.lock
decisions:
  - "Used captureAny instead of exact CounterModel matching in verify() because CounterModel does not override == (not Equatable)"
  - "ARB files confirmed in sync (22 keys each) -- no reconciliation changes needed"
metrics:
  duration: 180s
  completed: 2026-04-18T01:28:36Z
  tasks: 3
  files: 6
---

# Phase 6 Plan 1: ARB Template Switch + Reference Tests Summary

EN-template ARB switch with untranslated-messages tracking, plus bloc_test + mocktail cubit tests and Drift NativeDatabase.memory repository tests as copy-paste templates for all future features.

## Tasks Completed

| Task | Name | Commit | Key Files |
|------|------|--------|-----------|
| 1 | ARB template switch and dependency setup | 91279d1 | l10n.yaml, .gitignore, pubspec.yaml |
| 2 | Counter cubit test (bloc_test + mocktail template) | 352cbed | test/features/home_page/home_cubit_test.dart |
| 3 | Counter repository test (Drift NativeDatabase.memory template) | cb66c6f | test/features/home_page/counter_repository_test.dart |

## What Was Built

### Task 1: ARB Template Switch
- Changed `l10n.yaml` template from `app_pl.arb` to `app_en.arb` (EN is now the localization source of truth)
- Added `untranslated-messages-file: untranslated_messages.txt` to `l10n.yaml`
- Added `untranslated_messages.txt` to `.gitignore`
- Promoted `mocktail: ^1.0.5` to direct dev dependency in `pubspec.yaml`
- Verified both ARB files have identical key sets (22 keys each)

### Task 2: HomeCubit Test Template (6 tests)
- Initial state verification (status=empty, counter.value=0)
- `init()` with existing counter emits success state
- `init()` with no counter creates default, subscribes to watch, emits success
- `increment()` calls setCounter with value + 1
- `decrement()` calls setCounter with value - 1
- Watch stream Failure emits error status

### Task 3: CounterRepository Test Template (4 tests)
- `getCounter` returns `Failure(LocalDataNotFound)` when empty
- `setCounter` then `getCounter` returns `Success` with correct value
- `setCounter` upserts (second call overwrites first)
- `watchCounter` emits updated values reactively after writes

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed addTeardownReportingErrors API**
- **Found during:** Task 2
- **Issue:** `addTeardownReportingErrors` is not available in this Flutter SDK version
- **Fix:** Replaced with `addTearDown`
- **Files modified:** test/features/home_page/home_cubit_test.dart

**2. [Rule 1 - Bug] Fixed mocktail verify with non-Equatable CounterModel**
- **Found during:** Task 2
- **Issue:** `verify(() => service.setCounter(counter: CounterModel(value: 6)))` fails because `CounterModel` does not override `==`
- **Fix:** Used `captureAny(named: 'counter')` pattern to capture the argument and assert on `.value` directly
- **Files modified:** test/features/home_page/home_cubit_test.dart

## Verification

```
fvm flutter test --no-pub
00:00 +10: All tests passed!
```

All 10 tests pass (6 cubit + 4 repository).

## Self-Check: PASSED
