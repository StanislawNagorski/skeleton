---
phase: 04-firebase-wiring-auth-providers
reviewed: 2026-04-17T12:00:00Z
depth: standard
files_reviewed: 9
files_reviewed_list:
  - README.md
  - lib/core/auth/fake_auth_service.dart
  - lib/core/auth/firebase_auth_service.dart
  - lib/core/firebase/firebase_module.dart
  - lib/core/injectable/injection.config.dart
  - lib/core/injectable/injection.dart
  - lib/firebase_options.dart
  - lib/startup_service.dart
  - pubspec.yaml
findings:
  critical: 1
  warning: 5
  info: 3
  total: 9
status: issues_found
---

# Phase 4: Code Review Report

**Reviewed:** 2026-04-17T12:00:00Z
**Depth:** standard
**Files Reviewed:** 9
**Status:** issues_found

## Summary

Phase 4 introduces Firebase initialization with a dev/prod DI split, auth service abstraction (FakeAuthService + FirebaseAuthService), Firebase module registration (Analytics, Performance, Firestore), Crashlytics wiring, and App Check activation. The architecture is well-structured with a clean sealed AuthResult type and proper environment gating. Key concerns: one potential null-pointer crash in the Google Sign-In flow, a resource leak in the isolate error listener, missing `@disposeMethod` on FakeAuthService's StreamController, and the Firestore settings side-effect inside a DI getter.

## Critical Issues

### CR-01: Null-pointer crash when Google Sign-In returns null idToken

**File:** `lib/core/auth/firebase_auth_service.dart:111`
**Issue:** `account.authentication.idToken` can be `null` if the OAuth flow succeeds but the server does not return an ID token (e.g., misconfigured OAuth scopes, or the user grants only basic profile). Passing `null` to `GoogleAuthProvider.credential(idToken: null)` will cause a runtime crash or an opaque Firebase error. The `google_sign_in` 7.x `authenticate()` API can also throw or return an account whose `authentication.idToken` is null in edge cases.
**Fix:**
```dart
final idToken = account.authentication.idToken;
if (idToken == null) {
  return const AuthFailure(AuthError('Google Sign-In succeeded but no ID token was returned.'));
}

final credential = GoogleAuthProvider.credential(idToken: idToken);
```

## Warnings

### WR-01: FakeAuthService StreamController never disposed by get_it

**File:** `lib/core/auth/fake_auth_service.dart:93`
**Issue:** `FakeAuthService.dispose()` exists but is not annotated with `@disposeMethod`. Compare with `FirebaseAuthService` (line 244) which has the annotation. The generated `injection.config.dart` confirms: FakeAuthService registration (line 54-57) has no `dispose:` parameter, while FirebaseAuthService (line 73-77) does. This means `getIt.reset()` during test teardown will not close the broadcast StreamController, causing a resource leak.
**Fix:** Add `@disposeMethod` annotation:
```dart
@disposeMethod
Future<void> dispose() async {
  await _controller.close();
}
```
Then regenerate `injection.config.dart`.

### WR-02: RawReceivePort in Crashlytics isolate listener is never closed

**File:** `lib/startup_service.dart:79-90`
**Issue:** The `RawReceivePort` created for the isolate error listener is never stored or closed. It lives for the entire app lifetime, which is acceptable for a mobile app. However, the port's callback marks every isolate error as `fatal: true`, which will terminate the app via Crashlytics. Spawned-isolate errors are often recoverable (e.g., a failed background task) and should not always be fatal.
**Fix:** Consider `fatal: false` for isolate errors, or store the port for testability:
```dart
Isolate.current.addErrorListener(
  RawReceivePort((dynamic pair) async {
    final errorAndStack = pair as List<dynamic>;
    await FirebaseCrashlytics.instance.recordError(
      errorAndStack[0],
      StackTrace.fromString(errorAndStack[1] as String),
      fatal: false, // Isolate errors are often recoverable
    );
  }).sendPort,
);
```

### WR-03: Firestore settings mutation inside a DI getter (side effect in accessor)

**File:** `lib/core/firebase/firebase_module.dart:38-41`
**Issue:** The `firestore` getter uses the cascade operator to set `settings` on `FirebaseFirestore.instance` every time the getter is called. While `@lazySingleton` ensures it runs once in production, the pattern of mutating global state inside a DI accessor is fragile -- if the DI scope is reset (e.g., in integration tests) the settings are re-applied to a potentially already-configured instance. More importantly, `Settings(persistenceEnabled: true)` may overwrite other settings that were configured elsewhere.
**Fix:** Move the settings configuration to `StartUpService` after Firebase init, or use a factory method:
```dart
@lazySingleton
@Environment(Environment.prod)
FirebaseFirestore get firestore {
  final instance = FirebaseFirestore.instance;
  instance.settings = const Settings(persistenceEnabled: true);
  return instance;
}
```
This is functionally the same but documenting it as intentional; alternatively, configure settings in `StartUpService._configureFirestore()` for clarity.

### WR-04: signOut calls GoogleSignIn.instance.signOut() unconditionally

**File:** `lib/core/auth/firebase_auth_service.dart:173`
**Issue:** `signOut()` always calls `GoogleSignIn.instance.signOut()` even if the user signed in via email or Apple. If `GoogleSignIn` was never initialized (the user never called `signInWithGoogle()`), calling `signOut()` on an uninitialized instance may throw depending on the google_sign_in 7.x lifecycle. The `_googleSignInInitialized` flag exists but is not checked here.
**Fix:**
```dart
@override
Future<void> signOut() async {
  if (_googleSignInInitialized) {
    await GoogleSignIn.instance.signOut();
  }
  await FirebaseAuth.instance.signOut();
}
```

### WR-05: sendPasswordReset returns fabricated AuthUser with uid set to email

**File:** `lib/core/auth/firebase_auth_service.dart:186-192`
**Issue:** `sendPasswordReset` returns `AuthSuccess` with an `AuthUser` whose `uid` is the raw email string. This violates the contract where `uid` should be a Firebase UID. Callers consuming `AuthSuccess.user.uid` will get an email address instead of a UID, which could cause data corruption if used as a database key or user identifier downstream.
**Fix:** Since `sendPasswordResetEmail` does not return a user, return a different result type or a minimal success indicator:
```dart
// Option A: Return success without a user (requires adding a no-user success variant)
// Option B: Return current user if signed in, or a sentinel
return const AuthSuccess(AuthUser(
  uid: '',
  email: null,
  displayName: null,
  photoUrl: null,
  emailVerified: false,
));
```
The cleanest fix is to change `sendPasswordReset` to return `Future<AuthResult>` where `AuthSuccess` carries no meaningful user data, or introduce a `PasswordResetSent` result subclass.

## Info

### IN-01: FakeAuthService.signInWithGoogle and signInWithApple always return AuthCancelled

**File:** `lib/core/auth/fake_auth_service.dart:62-69`
**Issue:** In dev mode, Google and Apple sign-in always return `AuthCancelled`, making it impossible to test the success path of social sign-in flows without Firebase. Consider accepting a constructor parameter or a flag to control behavior.
**Fix:** Add a configurable behavior or return `AuthSuccess` with a fake social user for dev testing.

### IN-02: README typo "fallow" instead of "follow"

**File:** `README.md:45`
**Issue:** Line 45 reads `fallow: https://firebase.google.com/...` -- should be `follow`.
**Fix:** Replace `fallow` with `follow`.

### IN-03: AuthUser.copyWith cannot null-out optional fields

**File:** `lib/core/auth/auth_user.dart:20-33`
**Issue:** The `copyWith` pattern uses `??` which means once `displayName` or `photoUrl` is set, it cannot be reset to `null`. This is a common Dart copyWith limitation but worth noting since Apple Sign-In returns name only on first login -- subsequent updates may need to clear these fields.
**Fix:** Use a sentinel pattern or `freezed`-style copyWith to support nullable field clearing.

---

_Reviewed: 2026-04-17T12:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
