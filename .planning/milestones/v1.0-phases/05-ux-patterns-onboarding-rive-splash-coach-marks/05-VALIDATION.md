---
phase: 5
slug: ux-patterns-onboarding-rive-splash-coach-marks
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-17
---

# Phase 5 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (SDK) + bloc_test |
| **Config file** | none — existing test infrastructure from Phase 2 |
| **Quick run command** | `fvm flutter test --plain-name` |
| **Full suite command** | `fvm flutter test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `fvm flutter analyze`
- **After every plan wave:** Run `fvm flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 05-01-01 | 01 | 1 | UX-06 | — | N/A | build | `fvm flutter analyze` | ✅ | ⬜ pending |
| 05-01-02 | 01 | 1 | UX-02 | — | N/A | build | `fvm flutter analyze` | ✅ | ⬜ pending |
| 05-01-03 | 01 | 1 | UX-01 | — | N/A | build | `fvm flutter analyze` | ✅ | ⬜ pending |
| 05-01-04 | 01 | 1 | UX-03 | — | N/A | build | `fvm flutter analyze` | ✅ | ⬜ pending |
| 05-02-01 | 02 | 2 | UX-04 | — | N/A | build | `fvm flutter analyze` | ✅ | ⬜ pending |
| 05-02-02 | 02 | 2 | UX-05 | — | N/A | build | `fvm flutter analyze` | ✅ | ⬜ pending |
| 05-03-01 | 03 | 2 | UX-08 | — | N/A | build | `fvm flutter analyze` | ✅ | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

*Existing infrastructure covers all phase requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Onboarding 3-slide flow + skip button navigates to Home | UX-01 | UI interaction, visual PageView | Launch fresh install, verify 3 slides, dots indicator, skip exits to Home |
| Coach mark highlights FAB on first counter visit | UX-05 | Overlay visual verification | Navigate to counter page first time, verify FAB highlighted with description |
| RIVE demo loads .riv asset with state-machine toggle | UX-08 | Visual animation + interaction | Open RIVE Demo page, verify animation loads and toggle changes state |
| Guard ordering: OnboardingGuard before AuthGuard | UX-03 | Route flow requires emulator | Fresh install → verify onboarding before any auth check |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
