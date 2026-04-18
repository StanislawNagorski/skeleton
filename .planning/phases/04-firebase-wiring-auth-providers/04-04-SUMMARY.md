---
phase: "04"
plan: "04"
subsystem: "docs"
tags: [firebase-setup, readme, auth-providers, dx-promise]
dependency_graph:
  requires: [04-02, 04-03]
  provides: [firebase-setup-docs]
  affects: [README.md]
tech_stack:
  added: []
  patterns: []
key_files:
  created: []
  modified:
    - README.md
decisions:
  - "Appended Firebase Setup section after existing content, before Changelog"
  - "Documented serverClientId as auto-detected (zero manual config per D-05)"
  - "Added Apple email/name first-sign-in warning from Pitfall 2"
metrics:
  duration: "65s"
  completed: "2026-04-17T16:37:37Z"
  tasks_completed: 1
  tasks_total: 1
  files_modified: 1
---

# Phase 4 Plan 04: Firebase Setup Documentation Summary

Post-bootstrap Firebase setup guide added to README covering flutterfire configure, SHA-1 fingerprint registration, Google Sign-In serverClientId auto-detection, Apple Sign-In Xcode capability, App Check release-only activation, Crashlytics error handler trio, and dev-mode FakeAuthService fallback.

## Completed Tasks

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add Firebase setup documentation to README | d6b717a | README.md |

## Implementation Details

### Task 1: Firebase Setup Documentation

Added a `## Firebase Setup` section to README.md with seven subsections:

1. **Prerequisites** -- Firebase project + FlutterFire CLI
2. **Generate Firebase Options** -- `flutterfire configure` replacing the stub
3. **Google Sign-In Setup** -- Android SHA-1 (debug + release), serverClientId auto-detection, iOS reversed client ID in Info.plist
4. **Apple Sign-In Setup** -- Xcode capability, Services ID, first-sign-in data warning
5. **App Check** -- Release-only with Play Integrity (Android) and App Attest (iOS)
6. **Crashlytics** -- Three error handlers documented (FlutterError, PlatformDispatcher, Isolate)
7. **Dev Mode** -- FakeAuthService fallback, no Firebase deps, DX promise preserved

All existing README content preserved (package name change instructions, architecture, packages, changelog).

## Deviations from Plan

None -- plan executed exactly as written.

## Known Stubs

None -- this plan is documentation-only.

## Self-Check: PASSED
