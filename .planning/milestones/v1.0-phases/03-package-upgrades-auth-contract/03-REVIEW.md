---
phase: 03-package-upgrades-auth-contract
reviewed: 2026-04-17T12:00:00Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - lib/app.dart
  - lib/core/auth/auth_result.dart
  - lib/core/auth/auth_service.dart
  - lib/core/auth/auth_user.dart
  - lib/core/auth/fake_auth_service.dart
  - lib/core/errors/failures.dart
  - lib/core/router/guards/auth_guard.dart
  - lib/core/router/router.dart
  - lib/features/login/presentation/login_page.dart
  - lib/main.dart
  - pubspec.yaml
findings:
  critical: 0
  warning: 3
  info: 3
  total: 6
status: issues_found
---

# Phase 3: Code Review Report

**Reviewed:** 2026-04-17T12:00:00Z
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found

## Summary

The Phase 3 changeset introduces a clean authentication contract layer (`AuthService`, `AuthResult`, `AuthUser`, `AuthGuard`) using Dart 3 sealed classes to replace the legacy `dartz` `Either` pattern for auth flows, a `FakeAuthService` test double, router-level auth guarding, and significant `pubspec.yaml` upgrades (Drift, `flutter_bloc` 9, `auto_route` 11, `very_good_analysis`). The architecture is well-structured and follows the project's existing conventions. Three warnings relate to a resource leak in `FakeAuthService`, a semantically incorrect `sendPasswordReset` return value, and a missing `dispose` annotation. Three info items cover `AuthUser` equality, removed dependencies referenced elsewhere, and unused declared dependencies.

## Warnings

### WR-01: FakeAuthService StreamController never disposed by get_it

**File:** `lib/core/auth/fake_auth_service.dart:16-17`
**Issue:** `FakeAuthService` is registered as `@LazySingleton` and owns a `StreamController.broadcast()`. The `dispose()` method exists (line 93) but `get_it` will not call it automatically because `@disposeMethod` is not annotated. In long-running app sessions or hot-restart cycles during development, the controller is never closed, which is a resource leak. More critically, during test teardown via `getIt.reset()`, the controller will not be closed unless `@disposeMethod` is added.
**Fix:**
```dart
@disposeMethod
Future<void> dispose() async {
  await _controller.close();
}
```

### WR-02: sendPasswordReset returns AuthSuccess with a fake user -- semantically incorrect

**File:** `lib/core/auth/fake_auth_service.dart:78-88`
**Issue:** `sendPasswordReset` returns `AuthSuccess(AuthUser(...))` which implies a user was signed in. A password-reset email operation does not authenticate the user. This sets a misleading contract that consuming code may rely on -- e.g., a cubit might switch the app to an authenticated state after a password reset. The `AuthResult` sealed class conflates "operation succeeded" with "user authenticated." For the fake implementation this is a logic error; the real Firebase implementation would not return a user from this operation.
**Fix:** Consider either (a) changing `sendPasswordReset` return type to `Future<void>` or a simpler result type (since it cannot return a user), or (b) introducing a non-user-carrying success variant like `AuthOperationSuccess` to the sealed hierarchy. At minimum, the fake should not return an `AuthSuccess` with a user object:
```dart
// Option A: Change return type on AuthService contract
Future<void> sendPasswordReset({required String email});

// Option B: Add a non-auth success variant
final class AuthOperationSuccess extends AuthResult {
  const AuthOperationSuccess();
}
```

### WR-03: AuthUser lacks equality override -- auth state reevaluation may over-fire

**File:** `lib/core/auth/auth_user.dart:5-34`
**Issue:** `AuthUser` is used in `authStateChanges` stream which feeds `ReevaluateListenable.stream()` in `app.dart:24`. Without `==` and `hashCode` overrides, two `AuthUser` instances with identical fields are not equal. This means stream-based deduplication (e.g., `Stream.distinct()`) and any equality checks in guards or state management will always evaluate as different, potentially causing unnecessary route reevaluations on every emission. This is not a crash but can cause unexpected UI rebuilds and navigation flickers.
**Fix:** Add `Equatable` mixin (already available via `flutter_bloc` transitive dependency) or manually override `==` and `hashCode`:
```dart
@override
bool operator ==(Object other) =>
    identical(this, other) ||
    other is AuthUser &&
        uid == other.uid &&
        email == other.email &&
        displayName == other.displayName &&
        photoUrl == other.photoUrl &&
        emailVerified == other.emailVerified;

@override
int get hashCode => Object.hash(uid, email, displayName, photoUrl, emailVerified);
```

## Info

### IN-01: Removed dependencies still declared or referenced elsewhere

**File:** `pubspec.yaml`
**Issue:** The project constraints doc mentions `dartz`, `objectbox`, `http`, `uuid`, `collection`, and `path_provider` as dependencies, but they are no longer in `pubspec.yaml`. If any existing feature code (e.g., `counter_repository.dart`) still imports `dartz` or `objectbox`, the app will not compile. This is expected for a phased migration but worth verifying that all imports have been updated or that those files are scheduled for removal.
**Fix:** Verify with `grep -r "import.*dartz\|import.*objectbox\|import.*path_provider" lib/` that no stale imports remain. If they do, update them in the current or next phase.

### IN-02: Unused declared dependencies in pubspec.yaml

**File:** `pubspec.yaml:11-19`
**Issue:** Several Firebase packages (`cloud_firestore`, `firebase_analytics`, `firebase_app_check`, `firebase_core`, `firebase_crashlytics`, `firebase_performance`) and `flutter_secure_storage`, `shared_preferences` are declared but not imported anywhere in `lib/` source code. While some are scaffolded for future phases, they inflate the app binary size and slow `pub get` / native builds.
**Fix:** No immediate action needed if these are intentionally scaffolded for Phase 5. Consider adding a comment in `pubspec.yaml` grouping them (e.g., `# Phase 5: Firebase`) to signal intent.

### IN-03: LoginPage is a minimal placeholder with no auth interaction

**File:** `lib/features/login/presentation/login_page.dart:9-18`
**Issue:** The login page has no way to trigger authentication (no button, no form). While documented as a placeholder, a user cloning the skeleton and running it will be stuck on this screen with no way to proceed past the auth guard. A minimal "Sign in as test user" button wired to `FakeAuthService.signInWithEmail` would make the skeleton immediately runnable.
**Fix:** Consider adding a minimal sign-in button for development:
```dart
ElevatedButton(
  onPressed: () => getIt<AuthService>().signInWithEmail(
    email: 'test@example.com',
    password: 'test',
  ),
  child: const Text('Sign in (dev)'),
)
```

---

_Reviewed: 2026-04-17T12:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
