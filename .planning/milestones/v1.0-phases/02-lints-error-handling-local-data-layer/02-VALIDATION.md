---
phase: 2
slug: lints-error-handling-local-data-layer
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-17
---

# Phase 2 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | `flutter_test` (SDK, already in pubspec) |
| **Config file** | None — `test/` directory does not exist yet |
| **Quick run command** | `fvm flutter analyze` |
| **Full suite command** | `fvm flutter analyze && fvm flutter test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `fvm flutter analyze`
- **After every plan wave:** Run `fvm flutter analyze && fvm flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 02-01-01 | 01 | 1 | TOOL-03 | — | N/A | lint/static | `fvm flutter analyze` | N/A (built-in) | ⬜ pending |
| 02-02-01 | 02 | 2 | CORE-01 | — | N/A | unit | `fvm flutter test test/core/errors/result_test.dart` | ❌ W0 | ⬜ pending |
| 02-02-02 | 02 | 2 | CORE-02 | — | N/A | unit | `fvm flutter test test/features/home_page/` | ❌ W0 | ⬜ pending |
| 02-02-03 | 02 | 2 | CORE-06 | — | N/A | lint/grep | `grep -rn "dartz\|package:http\|package:uuid\|package:collection" lib/` | N/A (shell) | ⬜ pending |
| 02-03-01 | 03 | 3 | DATA-01 | — | N/A | lint/grep | `grep -rn "objectbox" lib/ pubspec.yaml` | N/A (shell) | ⬜ pending |
| 02-03-02 | 03 | 3 | DATA-02 | — | N/A | integration | `fvm flutter test test/core/database/app_database_test.dart` | ❌ W0 | ⬜ pending |
| 02-03-03 | 03 | 3 | DATA-03 | — | N/A | integration | `fvm flutter test test/features/home_page/data/` | ❌ W0 | ⬜ pending |
| 02-03-04 | 03 | 3 | DATA-04 | T-02-01 | Tokens use SecureStorage, not SharedPreferences | unit | `fvm flutter test test/core/preferences/` | ❌ W0 | ⬜ pending |
| 02-03-05 | 03 | 3 | DATA-05 | T-02-01 | EncryptedSharedPreferences + iOS Keychain | unit | `fvm flutter test test/core/secure_storage/` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/` directory — create it
- [ ] `test/core/errors/result_test.dart` — test sealed Result exhaustiveness
- [ ] `test/core/database/app_database_test.dart` — test Drift with `NativeDatabase.memory()`
- [ ] `test/features/home_page/data/local_database/counter_local_database_test.dart` — test Drift queries
- [ ] Note: Full test infrastructure (mocktail, bloc_test) is planned for TOOL-06 in Phase 7. Phase 2 needs only compile-and-analyze validation + minimal Drift integration tests.

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Counter page loads, increments, decrements via Drift | DATA-03 | UI integration — no widget test infra yet | Run app on simulator, tap +/-, verify counter updates and persists across restart |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 15s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
