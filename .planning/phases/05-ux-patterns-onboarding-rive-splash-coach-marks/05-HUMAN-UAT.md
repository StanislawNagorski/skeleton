---
status: partial
phase: 05-ux-patterns-onboarding-rive-splash-coach-marks
source: [05-VERIFICATION.md]
started: 2026-04-18T12:00:00.000Z
updated: 2026-04-18T12:00:00.000Z
---

## Current Test

[awaiting human testing]

## Tests

### 1. First launch onboarding flow
expected: 3-slide PageView with dots, skip/next buttons, get-started on last slide, then navigates to Home
result: [pending]

### 2. Subsequent launch skip
expected: App goes straight to Home (no onboarding shown)
result: [pending]

### 3. Coach mark tour on first Home visit
expected: Two-target overlay highlights counter display then FAB with tooltips; does not re-show on subsequent visits
result: [pending]

### 4. RIVE demo page
expected: Navigation from Home via button, animation canvas loads .riv asset, toggle switch sends boolean input to state machine
result: [pending]

### 5. Auth guard per-route
expected: Home is public (no auth redirect), AuthGuard only on /login route
result: [pending]

## Summary

total: 5
passed: 0
issues: 0
pending: 5
skipped: 0
blocked: 0

## Gaps
