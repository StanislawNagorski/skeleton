---
phase: 3
slug: package-upgrades-auth-contract
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-17
---

# Phase 3 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (SDK) + bloc_test ^10.0.0 |
| **Config file** | `pubspec.yaml` (dev_dependencies) |
| **Quick run command** | `flutter test --no-pub` |
| **Full suite command** | `flutter test && flutter analyze` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test --no-pub`
- **After every plan wave:** Run `flutter test && flutter analyze`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 30 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 3-01-01 | 01 | 1 | CORE-03 | — | N/A | build | `flutter analyze` | ✅ | ⬜ pending |
| 3-01-02 | 01 | 1 | CORE-03 | — | N/A | build | `flutter test --no-pub` | ✅ | ⬜ pending |
| 3-02-01 | 02 | 1 | CORE-04 | — | N/A | build | `flutter analyze` | ✅ | ⬜ pending |
| 3-03-01 | 03 | 2 | CORE-05 | — | N/A | unit | `flutter test test/core/auth/` | ❌ W0 | ⬜ pending |
| 3-03-02 | 03 | 2 | CORE-05 | — | AuthUser has zero firebase_auth imports | unit | `flutter test test/core/auth/` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/core/auth/auth_service_test.dart` — stubs for CORE-05
- [ ] `bloc_test: ^10.0.0` added to dev_dependencies — if not already present

*Existing flutter_test infrastructure covers CORE-03 and CORE-04 requirements.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| None | — | — | — |

*All phase behaviors have automated verification.*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 30s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
