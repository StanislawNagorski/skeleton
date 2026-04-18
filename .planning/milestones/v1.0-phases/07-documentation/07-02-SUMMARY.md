---
phase: 07-documentation
plan: 02
subsystem: documentation
tags: [docs, runbook, playbook, upgrade, rebase]
dependency_graph:
  requires: []
  provides: [rebase-runbook, upgrade-playbook]
  affects: []
tech_stack:
  added: []
  patterns: [step-by-step-runbook, checklist-playbook]
key_files:
  created:
    - docs/rebase-runbook.md
    - docs/upgrade-playbook.md
  modified: []
decisions:
  - "Runbook includes condensed quick-reference checklist at the end for experienced users"
  - "Upgrade playbook includes current code snippets from the skeleton for context during migration"
metrics:
  duration: 217s
  completed: "2026-04-18T08:12:04Z"
  tasks: 2
  files: 2
---

# Phase 7 Plan 2: Rebase Runbook and Upgrade Playbook Summary

Repeatable rebase runbook (12 steps with commands, verification, and failure modes) and four-section upgrade playbook covering FlutterFire BoM, App Check, auto_route guards, and Drift schema migrations -- all with runtime verification, not just compile-time checks.

## Commits

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Create the rebase runbook | 3dff7b9 | docs/rebase-runbook.md |
| 2 | Create the upgrade playbook | 700c912 | docs/upgrade-playbook.md |

## What Was Built

### docs/rebase-runbook.md (276 lines)

A 12-step numbered procedure for rebasing the skeleton onto a new Flutter major release. Each step includes the exact command to run, what to verify after, and what can go wrong. Includes:

- Pre-rebase safety (snapshot branch)
- FVM pin bump and fresh scaffold generation
- Native directory swap with iOS Podfile floor adjustment
- L10n generation path change handling
- Release signing scaffold re-application
- Full verification suite (analyze, test, build APK, build iOS)
- Version matrix from the 3.41.5 rebase as reference
- Lessons learned section capturing five non-obvious issues
- Condensed quick-reference checklist for experienced users

### docs/upgrade-playbook.md (281 lines)

Four self-contained checklists, each covering a specific upgrade scenario:

1. **FlutterFire BoM Bump** -- upgrade all Firebase packages as a group, with runtime verification (auth flows, Crashlytics crash test, Analytics session events)
2. **App Check Verification** -- release-only activation, physical device testing, enforcement validation
3. **auto_route Guard Migration** -- documents current guard architecture (global OnboardingGuard, per-route AuthGuard, reevaluateListenable wiring), migration steps for new major versions
4. **Drift Schema Migration** -- adding tables/columns, migration strategy with onUpgrade, upgrade install testing on existing data

## Deviations from Plan

None -- plan executed exactly as written.

## Self-Check: PASSED
