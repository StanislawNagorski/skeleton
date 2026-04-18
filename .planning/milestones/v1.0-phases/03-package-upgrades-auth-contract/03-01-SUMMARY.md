---
phase: 03-package-upgrades-auth-contract
plan: 01
status: complete
started: 2026-04-17
completed: 2026-04-17
---

## Summary

Bumped flutter_bloc to v9.1.1, created the AuthService contract layer with 4 files under `lib/core/auth/`, and added AuthError to the sealed failure hierarchy.

## What Was Built

- **flutter_bloc ^9.1.1** — bumped from ^8.1.6; Cubit API unchanged, no code modifications needed
- **bloc_test ^10.0.0** — added to dev_dependencies for future test support
- **AuthUser** (`lib/core/auth/auth_user.dart`) — pure Dart entity with uid, email, displayName, photoUrl, emailVerified + copyWith
- **AuthResult** (`lib/core/auth/auth_result.dart`) — sealed class with AuthSuccess, AuthFailure, AuthCancelled variants
- **AuthService** (`lib/core/auth/auth_service.dart`) — abstract contract with 8 methods (authStateChanges, currentUser, signInWithEmail, signUpWithEmail, signInWithGoogle, signInWithApple, signOut, sendPasswordReset)
- **FakeAuthService** (`lib/core/auth/fake_auth_service.dart`) — in-memory implementation with broadcast StreamController, registered as @LazySingleton(as: AuthService)
- **AuthError** (`lib/core/errors/failures.dart`) — new subtype in sealed AppFailure hierarchy

## Key Files

### Created
- `lib/core/auth/auth_user.dart`
- `lib/core/auth/auth_result.dart`
- `lib/core/auth/auth_service.dart`
- `lib/core/auth/fake_auth_service.dart`

### Modified
- `pubspec.yaml` — flutter_bloc bump + bloc_test addition
- `pubspec.lock` — resolved dependencies
- `lib/core/errors/failures.dart` — AuthError subtype added
- `lib/core/injectable/injection.config.dart` — regenerated with FakeAuthService

## Deviations

- `[AuthService]` doc reference in auth_user.dart changed to backtick-quoted `AuthService` to avoid analyze warning (file created before auth_service.dart existed). Same for `[FakeAuthService]` in auth_service.dart.
- `dispose()` in FakeAuthService changed from `void` to `Future<void> async` to properly await `_controller.close()`.

## Self-Check: PASSED

- flutter_bloc ^9.1.1 in pubspec.yaml ✓
- bloc_test ^10.0.0 in dev_dependencies ✓
- All 4 auth files exist with correct contents ✓
- AuthError in failures.dart ✓
- FakeAuthService in injection.config.dart ✓
- `fvm flutter analyze lib/core/auth/` — no issues ✓
- Zero firebase imports in auth contract ✓
