---
phase: "04"
plan: "03"
subsystem: "auth"
tags: [firebase-auth, google-sign-in, apple-sign-in, email-auth, di-environment]
dependency_graph:
  requires: [04-01]
  provides: [firebase-auth-service, prod-auth-di-registration]
  affects: [injection.config.dart, auth-service-resolution]
tech_stack:
  added: [google_sign_in-7.x-singleton-api, crypto-sha256-nonce]
  patterns: [firebase-auth-state-stream-mapping, environment-conditional-di, sealed-auth-result-returns]
key_files:
  created:
    - lib/core/auth/firebase_auth_service.dart
  modified:
    - lib/core/injectable/injection.config.dart
decisions:
  - "Used google_sign_in 7.x singleton API: initialize() + authenticate() returning GoogleSignInAccount with .authentication.idToken for Firebase credential exchange"
  - "Implemented nonce generation manually (Random.secure + charset) since firebase_auth does not export generateNonce()"
  - "Google Sign-In initialize() called without explicit serverClientId -- auto-detected from google-services.json on Android and GoogleService-Info.plist on iOS per D-05"
  - "Kept AuthError as single type with descriptive message strings rather than granular subtypes (Claude's discretion per CONTEXT.md)"
metrics:
  duration: "2m 20s"
  completed: "2026-04-17T16:32:32Z"
  tasks_completed: 1
  tasks_total: 1
  files_created: 1
  files_modified: 1
---

# Phase 4 Plan 03: FirebaseAuthService Implementation Summary

Production AuthService backed by Firebase Auth with Email/Password, Google Sign-In (7.x API), and Apple Sign-In (SHA-256 nonce), registered as prod-environment DI lazy singleton.

## Completed Tasks

| # | Task | Commit | Key Files |
|---|------|--------|-----------|
| 1 | Implement FirebaseAuthService with all auth providers | `0fae06a` | `lib/core/auth/firebase_auth_service.dart`, `lib/core/injectable/injection.config.dart` |

## Implementation Details

### FirebaseAuthService (249 lines)

Implements all 8 `AuthService` contract methods:

1. **authStateChanges** -- Subscribes to `FirebaseAuth.instance.authStateChanges()`, maps `User` to `AuthUser` via `_mapUser`, emits on broadcast `StreamController`
2. **currentUser** -- Maps `FirebaseAuth.instance.currentUser` to `AuthUser`
3. **signInWithEmail** -- `signInWithEmailAndPassword` with `FirebaseAuthException` error mapping
4. **signUpWithEmail** -- `createUserWithEmailAndPassword` with `FirebaseAuthException` error mapping
5. **signInWithGoogle** -- google_sign_in 7.x: `initialize()` (once per session) + `authenticate()` + `account.authentication.idToken` + `GoogleAuthProvider.credential(idToken:)` + `signInWithCredential`
6. **signInWithApple** -- SHA-256 nonce via `crypto` package + `SignInWithApple.getAppleIDCredential` + `OAuthProvider('apple.com').credential` + `signInWithCredential`
7. **signOut** -- `GoogleSignIn.instance.signOut()` + `FirebaseAuth.instance.signOut()` (stream auto-emits null)
8. **sendPasswordReset** -- `sendPasswordResetEmail` (Firebase prevents user enumeration by sending regardless)

### google_sign_in 7.x API Adaptation

The RESEARCH.md flagged Assumptions A1/A2 as medium/high risk. After looking up the actual 7.x API via Context7:

- **API difference from plan:** `authenticate()` returns `Future<GoogleSignInAccount>` directly (not void + stream). The `GoogleSignInAccount` has `.authentication.idToken` for Firebase credential creation.
- **serverClientId:** `initialize()` called without explicit `serverClientId` -- on Android, the google_sign_in_android plugin auto-reads the Web client ID from `google-services.json`. On iOS, it uses `GoogleService-Info.plist`. This aligns with D-05 (zero manual config after `flutterfire configure`).
- **Cancellation:** Caught via `GoogleSignInException` with `GoogleSignInExceptionCode.canceled` -- returns `AuthCancelled()`.

### DI Registration

Generated `injection.config.dart` now registers:
- `FakeAuthService` as `AuthService` for `{_dev}` environment
- `FirebaseAuthService` as `AuthService` for `{_prod}` environment with `dispose: (i) => i.dispose()`

### Threat Mitigations

| Threat | Mitigation |
|--------|-----------|
| T-04-07 (Apple replay) | SHA-256 nonce generated per sign-in via `Random.secure()` + `crypto` SHA-256 |
| T-04-09 (Firebase error info disclosure) | `_mapAuthErrorCode` maps codes to generic user-facing messages |
| T-04-12 (Password reset enumeration) | Firebase sends reset email regardless of account existence |

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] google_sign_in 7.x API differs from RESEARCH.md pattern**
- **Found during:** Task 1
- **Issue:** RESEARCH.md Pattern 4 used `googleUser.authorizationClient.authorizationForScopes([])` to get tokens. The actual 7.x API returns `GoogleSignInAccount` from `authenticate()` with `.authentication.idToken` directly.
- **Fix:** Used actual 7.x API: `authenticate()` returns account, `account.authentication.idToken` provides the idToken for `GoogleAuthProvider.credential()`. No accessToken needed for Firebase credential exchange.
- **Files modified:** `lib/core/auth/firebase_auth_service.dart`
- **Commit:** `0fae06a`

**2. [Rule 3 - Blocking] generateNonce() not exported from firebase_auth**
- **Found during:** Task 1
- **Issue:** Plan noted `generateNonce()` may not be available from firebase_auth. Confirmed: it is not exported.
- **Fix:** Implemented `_generateNonce()` manually using `Random.secure()` with alphanumeric charset, producing a cryptographically secure random string for Apple Sign-In nonce.
- **Files modified:** `lib/core/auth/firebase_auth_service.dart`
- **Commit:** `0fae06a`

## Self-Check: PASSED

- [x] `lib/core/auth/firebase_auth_service.dart` exists (249 lines)
- [x] Commit `0fae06a` exists in git log
- [x] `injection.config.dart` contains `FirebaseAuthService` registration
- [x] `fvm flutter analyze --no-fatal-infos` passes (0 errors, 0 warnings)
