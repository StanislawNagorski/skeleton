---
phase: 06-bootstrap-i18n-cleanup-tests
plan: 02
subsystem: tooling
tags: [dart-cli, bootstrap, rename, firebase-setup]

# Dependency graph
requires: []
provides:
  - "One-pass bootstrap rename CLI at tool/bootstrap.dart"
  - "Input validation for app name and bundle ID"
  - "Firebase setup checklist printed post-rename"
affects: [07-testing, onboarding]

# Tech tracking
tech-stack:
  added: []
  patterns: [pure-dart-cli-script, input-validation-before-fs-ops]

key-files:
  created:
    - tool/bootstrap.dart
  modified: []

key-decisions:
  - "Pure dart:io only -- no external package dependencies for the bootstrap script"
  - "RegExp validation for name and bundle before any filesystem operations (threat mitigations T-06-02, T-06-03, T-06-04)"
  - "CFBundleName set to snake_case dart package name, CFBundleDisplayName set to PascalCase display name"

patterns-established:
  - "Bootstrap CLI pattern: --name PascalCase --bundle reverse.domain.format"
  - "Snake_case derivation from PascalCase via _toSnakeCase helper"

requirements-completed: [TOOL-01, TOOL-02]

# Metrics
duration: 2min
completed: 2026-04-18
---

# Phase 6 Plan 02: Bootstrap Rename Script Summary

**Pure Dart CLI bootstrap script with 9-step rename (Dart imports, Android, iOS, pubspec, README, Drift DB) and Firebase setup checklist**

## Performance

- **Duration:** 2 min
- **Started:** 2026-04-18T01:26:11Z
- **Completed:** 2026-04-18T01:28:25Z
- **Tasks:** 1
- **Files modified:** 1

## Accomplishments
- Created tool/bootstrap.dart -- 332-line pure Dart CLI with no external dependencies
- 9-step rename covering all skeleton identifiers: Dart package imports, Android build.gradle.kts, AndroidManifest.xml, Kotlin directory move, iOS project.pbxproj (6 occurrences), iOS Info.plist (display name + bundle name), pubspec.yaml, README.md, Drift database name
- Input validation prevents path traversal and invalid identifiers (name: alphanumeric only, bundle: reverse-domain with 3+ segments)
- Post-run Firebase setup checklist covers project creation, app registration, config download, flutterfire configure, SHA-1 fingerprints, and Apple Sign-in setup

## Task Commits

Each task was committed atomically:

1. **Task 1: Create bootstrap rename script** - `65de1a7` (feat)

## Files Created/Modified
- `tool/bootstrap.dart` - One-pass rename CLI: parses --name/--bundle, validates inputs, renames 9 targets, prints Firebase checklist

## Decisions Made
- Used pure dart:io with no external packages per D-03 -- keeps the bootstrap script zero-dependency
- RegExp-based input validation runs before any filesystem operations, satisfying threat mitigations T-06-02 through T-06-04
- CFBundleName uses snake_case (dart package name) while CFBundleDisplayName uses the original PascalCase display name
- Android Kotlin directory physically moved and empty parents cleaned up recursively

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered
None

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- Bootstrap script ready for use and testing
- Script covers all rename targets identified in phase research
- Future plan 06-03 (tests) can add bootstrap integration tests per D-12

---
*Phase: 06-bootstrap-i18n-cleanup-tests*
*Completed: 2026-04-18*
