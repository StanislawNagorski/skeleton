# Phase 3: Package Upgrades + Auth Contract - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-04-17
**Phase:** 03-package-upgrades-auth-contract
**Areas discussed:** AuthService contract shape, AuthService impl timing, auto_route 11 guard wiring, AppFailure extensions

---

## AuthService contract shape

### Auth result typing

| Option | Description | Selected |
|--------|-------------|----------|
| Separate sealed AuthResult | AuthSuccess(AuthUser) / AuthFailure(AppFailure) / AuthCancelled — dedicated type for auth operations | ✓ |
| Reuse Result<AuthUser> | Use existing Result<T> from Phase 2. AuthCancelled becomes an AppFailure subtype | |

**User's choice:** Separate sealed AuthResult
**Notes:** Distinct "cancelled" state that doesn't map cleanly to success/failure justifies a separate type.

### Sign-up vs sign-in

| Option | Description | Selected |
|--------|-------------|----------|
| Separate methods | signInWithEmail() + signUpWithEmail() — maps 1:1 to Firebase Auth API | ✓ |
| Combined with mode param | authenticateWithEmail(email, password, {mode: AuthMode.signIn}) | |

**User's choice:** Separate methods
**Notes:** None

### Password reset placement

| Option | Description | Selected |
|--------|-------------|----------|
| On AuthService | sendPasswordReset({required String email}) on the main interface | ✓ |
| Separate PasswordService | Dedicated service for password-related ops | |

**User's choice:** On AuthService
**Notes:** None

### AuthUser fields

| Option | Description | Selected |
|--------|-------------|----------|
| Full set | uid, email, displayName, photoUrl, emailVerified | ✓ |
| Minimal (uid + email) | Strict minimum, apps extend as needed | |

**User's choice:** Full set
**Notes:** None

---

## AuthService impl timing

### What ships in Phase 3

| Option | Description | Selected |
|--------|-------------|----------|
| Abstract only + fake impl | AuthService abstract + FakeAuthService (in-memory, no Firebase imports) registered in DI | ✓ |
| Abstract + FirebaseAuthService stub | Real firebase_auth imports but unimplemented method bodies | |
| Abstract contract only | No implementation, DI deferred to Phase 5 | |

**User's choice:** Abstract only + fake impl
**Notes:** None

### FakeAuthService lifespan

| Option | Description | Selected |
|--------|-------------|----------|
| Keep for tests | Stays permanently as @Environment('test') double | ✓ |
| Temporary, replace in Phase 5 | Deleted when FirebaseAuthService lands, tests use mocktail | |

**User's choice:** Keep for tests
**Notes:** None

---

## auto_route 11 guard wiring

### Router DI timing

| Option | Description | Selected |
|--------|-------------|----------|
| Inject now in Phase 3 | AppRouter(AuthService) — guards wired against FakeAuthService immediately | ✓ |
| Defer to Phase 5 | Phase 3 only bumps version, no guards | |

**User's choice:** Inject now in Phase 3
**Notes:** None

### reevaluateListenable wiring

| Option | Description | Selected |
|--------|-------------|----------|
| In app.dart via stream | ReevaluateListenable.stream(authService.authStateChanges) — idiomatic auto_route 11 | ✓ |
| Manual re-evaluation | Guards check on each navigation only | |

**User's choice:** In app.dart via stream
**Notes:** None

### AuthGuard redirect target

| Option | Description | Selected |
|--------|-------------|----------|
| To a LoginRoute placeholder | Empty page saying "Login screen — built per app" | ✓ |
| You decide | Claude picks the redirect target | |

**User's choice:** LoginRoute placeholder
**Notes:** None

---

## AppFailure extensions

### Auth failure subtypes

| Option | Description | Selected |
|--------|-------------|----------|
| AuthError only | Single new subtype, specific cases as message strings | ✓ |
| Granular auth failures | AuthError + AuthNetworkError + AuthInvalidCredentials + AuthUserNotFound | |
| No new AppFailure subtypes | AuthFailure in AuthResult wraps a plain String instead | |

**User's choice:** AuthError only
**Notes:** Phase 5 can refine with granular subtypes if Firebase error codes warrant it.

---

## Claude's Discretion

- flutter_bloc 9 migration details (trivial for Cubit-only codebase)
- Whether to add bloc_test ^10.0.0 now or defer to Phase 7
- auto_route 11 specific API migrations (pushNamed → pushPath, etc.)
- FakeAuthService internal behavior details
- LoginRoute placeholder complexity (StatelessWidget vs cubit)
- AuthUser copyWith method inclusion

## Deferred Ideas

- OnboardingGuard → Phase 6
- @Environment DI split → Phase 5
- Granular auth failures → Phase 5 if needed
- bloc_test → Phase 7 (or earlier at Claude's discretion)
