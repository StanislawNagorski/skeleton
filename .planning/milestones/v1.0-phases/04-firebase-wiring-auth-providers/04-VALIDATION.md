---
phase: 4
slug: firebase-wiring-auth-providers
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-04-17
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | flutter_test (SDK) |
| **Config file** | `pubspec.yaml` (flutter_test dev dependency) |
| **Quick run command** | `flutter test --no-pub` |
| **Full suite command** | `flutter test` |
| **Estimated runtime** | ~15 seconds |

---

## Sampling Rate

- **After every task commit:** Run `flutter test --no-pub`
- **After every plan wave:** Run `flutter test`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 15 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 4-01-01 | 01 | 1 | FIRE-01 | T-4-01 / — | Firebase.initializeApp completes before DI | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 4-01-02 | 01 | 1 | FIRE-02 | — | Stub firebase_options.dart throws on fresh clone | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 4-02-01 | 02 | 1 | FIRE-03 | T-4-02 / — | Crashlytics hooks wired in release only | manual | N/A | N/A | ⬜ pending |
| 4-03-01 | 03 | 2 | AUTH-01 | T-4-03 / — | FirebaseAuthService implements AuthService contract | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 4-03-02 | 03 | 2 | AUTH-02 | — | Email sign-in returns AuthResult | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 4-03-03 | 03 | 2 | AUTH-03 | — | Google sign-in returns AuthResult | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 4-03-04 | 03 | 2 | AUTH-04 | — | Apple sign-in returns AuthResult | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 4-04-01 | 04 | 2 | FIRE-04 | T-4-04 / — | App Check release-only activation | unit | `flutter test` | ❌ W0 | ⬜ pending |
| 4-05-01 | 05 | 3 | FIRE-05, FIRE-06, FIRE-07 | — | Analytics, Performance, Firestore registered in DI | unit | `flutter test` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `test/core/auth/firebase_auth_service_test.dart` — stubs for AUTH-01 through AUTH-06
- [ ] `test/core/startup_service_test.dart` — stubs for FIRE-01, FIRE-02
- [ ] `test/core/firebase/app_check_test.dart` — stubs for FIRE-04

*Existing flutter_test infrastructure covers framework needs. No new test framework install required.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Crashlytics error appears in console | FIRE-03 | Requires Firebase project + release build | Force error in release mode, check Crashlytics dashboard within 5 min |
| Google Sign-In completes real OAuth flow | AUTH-03 | Requires configured Firebase project + OAuth consent screen | Run on device with `flutterfire configure` completed, tap Google sign-in |
| Apple Sign-In completes real flow | AUTH-04 | Requires Apple Developer account + entitlement | Run on iOS device with Sign in with Apple capability enabled |
| App Check blocks unauthenticated requests | FIRE-04 | Requires Firebase App Check enforcement enabled | Enable enforcement in Firebase console, verify protected endpoints reject without token |

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
