---
phase: 03-package-upgrades-auth-contract
plan: 02
status: complete
started: 2026-04-17
completed: 2026-04-17
---

## Summary

Wired auto_route 11 guard system against the AuthService contract — AuthGuard redirects unauthenticated users to LoginRoute, reevaluateListenable re-runs guards on auth state changes, and main.dart resolves AuthService from DI.

## What Was Built

- **AuthGuard** (`lib/core/router/guards/auth_guard.dart`) — extends AutoRouteGuard, checks `currentUser != null`, calls `resolver.redirectUntil(LoginRoute())` when unauthenticated
- **LoginPage** (`lib/features/login/presentation/login_page.dart`) — minimal @RoutePage() placeholder as guard redirect target
- **AppRouter updated** (`lib/core/router/router.dart`) — accepts AuthService constructor param, `guards` override returns [AuthGuard], LoginRoute added to routes
- **MyApp updated** (`lib/app.dart`) — `reevaluateListenable: ReevaluateListenable.stream(authService.authStateChanges)` wired into router config
- **main.dart updated** — resolves `getIt<AuthService>()` and passes to both AppRouter and MyApp
- **Generated code** — router.gr.dart regenerated with LoginRoute, injection.config.dart unchanged (FakeAuthService already registered in Plan 01)

## Key Files

### Created
- `lib/core/router/guards/auth_guard.dart`
- `lib/features/login/presentation/login_page.dart`

### Modified
- `lib/core/router/router.dart`
- `lib/core/router/router.gr.dart`
- `lib/app.dart`
- `lib/main.dart`

## Deviations

- Used `resolver.redirectUntil()` instead of `resolver.redirect()` — auto_route 11 renamed the method for temporary redirect-until-resolved semantics.
- `[AuthGuard]` doc reference in login_page.dart changed to backtick-quoted to avoid analyze warning (different package boundary).

## Self-Check: PASSED

- AppRouter takes AuthService constructor param ✓
- guards override returns [AuthGuard] ✓
- LoginRoute at /login in router ✓
- reevaluateListenable.stream wired in app.dart ✓
- getIt<AuthService>() in main.dart ✓
- LoginRoute in router.gr.dart ✓
- `fvm flutter analyze` — no issues ✓
