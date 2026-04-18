---
phase: 06-bootstrap-i18n-cleanup-tests
plan: 03
subsystem: tooling
tags: [e2e-test, bootstrap, dart-test, process-spawn]

# Dependency graph
requires:
  - "tool/bootstrap.dart from plan 02"
provides:
  - "End-to-end test coverage for the bootstrap rename script"
  - "Input validation test coverage for bootstrap CLI"
affects: [ci-pipeline]

# Tech tracking
tech-stack:
  added: []
  patterns: [process-spawn-e2e-test, temp-dir-isolation]

key-files:
  created:
    - test/tool/bootstrap_test.dart
  modified: []

key-decisions:
  - "dart pub get required before dart analyze in renamed temp copy (package_config.json must reflect new package name)"
  - "Input validation tests use minimal temp dir with just the bootstrap script (no full project copy needed since validation runs before filesystem ops)"
  - "Full lib/ scan for package:skeleton/ remnants in addition to spot-checking key files"

patterns-established:
  - "Process.run-based E2E test pattern for CLI tools in tool/"
  - "Temp directory isolation with recursive copy skipping build artifacts"

requirements-completed: [TOOL-07]

# Metrics
duration: 140s
completed: 2026-04-18
---

# Phase 6 Plan 03: Bootstrap Script E2E Tests Summary

**End-to-end test that copies the project to a temp dir, runs the bootstrap rename, verifies all 9 rename targets, checks dart analyze passes, and validates input rejection**

## Performance

- **Duration:** 140s
- **Started:** 2026-04-18T01:30:30Z
- **Completed:** 2026-04-18T01:32:50Z
- **Tasks:** 1
- **Files created:** 1

## Accomplishments
- Created test/tool/bootstrap_test.dart with 15 tests covering the full bootstrap lifecycle
- E2E rename test: copies project to temp dir, runs `dart run tool/bootstrap.dart --name TestApp --bundle com.test.myapp`, verifies exit 0
- Rename target assertions: pubspec.yaml name change, Android build.gradle.kts namespace, iOS project.pbxproj bundle ID, Info.plist display name, README title, Drift database name, Kotlin directory move
- Import sweep: verifies no `package:skeleton/` imports remain in any non-generated `.dart` file under lib/
- Analyze gate: runs `dart pub get` + `dart analyze lib/` on the renamed project to catch broken imports
- Input validation: 4 tests covering empty name, name with slashes, invalid bundle format, and missing arguments

## Task Commits

Each task was committed atomically:

1. **Task 1: Bootstrap script end-to-end test** - `98e2787` (test)

## Files Created/Modified
- `test/tool/bootstrap_test.dart` - 15 E2E tests for bootstrap rename script: successful rename verification, dart analyze pass, input validation rejection

## Decisions Made
- Added `dart pub get` step before `dart analyze` in the test -- after renaming the Dart package from `skeleton` to `test_app`, the `.dart_tool/package_config.json` must be regenerated so the analyzer can resolve the new `package:test_app/` imports (Rule 3: blocking issue fix)
- Input validation tests create a minimal temp dir with only the bootstrap script rather than copying the full project, since validation occurs before any filesystem operations
- Full scan of all `.dart` files under lib/ for `package:skeleton/` remnants, not just spot checks, to catch regressions comprehensively

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Added dart pub get before dart analyze in E2E test**
- **Found during:** Task 1 verification
- **Issue:** `dart analyze` failed because the renamed project's `package_config.json` still referenced `skeleton` -- the test skips `.dart_tool/` during copy, so the analyzer couldn't resolve `package:test_app/` imports
- **Fix:** Added `dart pub get` step in the analyze test group to regenerate package config after rename
- **Files modified:** test/tool/bootstrap_test.dart
- **Commit:** 98e2787

## Issues Encountered
None beyond the deviation above.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Phase 6 is complete (all 3 plans done)
- Bootstrap script and its E2E test suite are ready
- Phase 7 (Documentation) can proceed

## Self-Check: PASSED

- [x] test/tool/bootstrap_test.dart exists
- [x] Commit 98e2787 exists in git log

---
*Phase: 06-bootstrap-i18n-cleanup-tests*
*Completed: 2026-04-18*
