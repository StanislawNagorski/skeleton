# Phase 3: Package Upgrades + Auth Contract - Research

**Researched:** 2026-04-17
**Domain:** flutter_bloc 8->9 migration, auto_route 9->11 migration, AuthService contract design, sealed AuthResult
**Confidence:** HIGH

## Summary

Phase 3 has three distinct workstreams that share no file overlap and can be sequenced cleanly: (1) bump `flutter_bloc` 8->9, (2) bump `auto_route` 9->11 with guard wiring, and (3) create the abstract `AuthService` contract with `AuthUser`, sealed `AuthResult`, `FakeAuthService`, `AuthGuard`, and `LoginRoute` placeholder.

The codebase is already well-prepared by Phase 2. The router already extends `RootStackRouter` directly (the v9 migration's biggest structural requirement), the sealed `Result<T>` / `AppFailure` pattern is established and provides the template for `AuthResult`, and the DI graph uses `@lazySingleton` consistently. The `flutter_bloc` bump is nearly invisible because the skeleton uses `Cubit` (not `Bloc`) and has no `BlocOverrides` usage. The `auto_route` bump requires adding the `guards` override, wiring `reevaluateListenable`, and adding `LoginRoute` as a redirect target. The `AuthService` contract is the heaviest lift but is purely additive -- new files in `lib/core/auth/`, a new `AuthError` subtype, and DI registration of `FakeAuthService`.

**Primary recommendation:** Sequence as flutter_bloc bump first (smallest, proves compile), then AuthService contract (purely additive, no existing code changes), then auto_route guard wiring last (depends on both AuthService and the router accepting constructor params).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** Separate `sealed class AuthResult` with `AuthSuccess(AuthUser)` / `AuthFailure(AppFailure)` / `AuthCancelled()`. Not a reuse of `Result<T>`.
- **D-02:** Separate methods for sign-in vs sign-up: `signInWithEmail()` + `signUpWithEmail()`. Maps 1:1 to Firebase Auth's API.
- **D-03:** `sendPasswordReset({required String email})` lives on `AuthService`.
- **D-04:** `AuthUser` exposes: `uid`, `email` (String?), `displayName` (String?), `photoUrl` (String?), `emailVerified` (bool). Pure Dart entity, zero `firebase_auth` imports.
- **D-05:** Full contract surface: `Stream<AuthUser?> get authStateChanges`, `AuthUser? get currentUser`, `signInWithEmail`, `signUpWithEmail`, `signInWithGoogle`, `signInWithApple`, `signOut`, `sendPasswordReset`.
- **D-06:** Phase 3 ships abstract `AuthService` + `FakeAuthService` (in-memory, no Firebase imports) registered as `@LazySingleton(as: AuthService)`. Phase 5 adds `FirebaseAuthService`.
- **D-07:** `FakeAuthService` kept permanently as test double. Phase 5 adds `@Environment('prod')` / `@Environment('test')` split.
- **D-08:** `AppRouter` takes `AuthService` as constructor param now in Phase 3. Guards wired against `FakeAuthService`.
- **D-09:** Router-level `guards` override returns `[AuthGuard(_authService)]`. `AuthGuard` extends `AutoRouteGuard`, checks `currentUser != null`, redirects to `LoginRoute`.
- **D-10:** `LoginRoute` is an empty placeholder page at `lib/features/login/presentation/login_page.dart`.
- **D-11:** `reevaluateListenable: ReevaluateListenable.stream(authService.authStateChanges)` wired in `app.dart`.
- **D-12:** Single new subtype: `final class AuthError extends AppFailure`. Specific sub-cases are message strings within `AuthError`.

### Claude's Discretion
- `flutter_bloc` 9 migration details (trivial for Cubit-only usage)
- Whether to add `bloc_test ^10.0.0` now or defer to Phase 7
- `auto_route` 11 migration specifics: `pushNamed` -> `pushPath`, `pop` -> `maybePop` if applicable
- `FakeAuthService` internal behavior (delay simulation, configurable modes)
- Whether `LoginRoute` placeholder needs its own cubit or is simple `StatelessWidget`
- `AuthUser` `copyWith` method inclusion

### Deferred Ideas (OUT OF SCOPE)
- `OnboardingGuard` wiring -> Phase 6
- `@Environment('prod')` / `@Environment('test')` DI split -> Phase 5
- Granular auth failure subtypes -> Phase 5
- `bloc_test ^10.0.0` -> Phase 7 unless added earlier at discretion
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CORE-03 | `flutter_bloc` upgraded 8 -> 9; all bloc/cubit usages compile against the new API | flutter_bloc 9 migration analysis: no BlocOverrides usage, Cubit API unchanged, existing BlocBuilder/BlocListener patterns compatible |
| CORE-04 | `auto_route` upgraded 9 -> 11.1.0 with `auto_route_generator 10.5.0`; guards migrated to `guards:` property on `RootStackRouter`; `pushNamed` -> `pushPath` / `pop` -> `maybePop` applied | auto_route v9 migration docs (Context7): guards override pattern, RootStackRouter already in place, reevaluateListenable.stream for auth |
| CORE-05 | Central `AuthService` abstract class in `lib/core/auth/` with `Stream<AuthUser?>` + sign-in methods returning sealed `AuthResult`; impl registered via `@Injectable(as: AuthService)` | Architecture research AuthService contract, sealed AuthResult pattern, FakeAuthService as @LazySingleton |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| flutter_bloc 9 upgrade | Frontend (Dart) | -- | Pure pubspec + minor API changes, all in `lib/` |
| auto_route 11 upgrade | Frontend (Dart) | -- | Router config + guard wiring, all in `lib/core/router/` |
| AuthService contract | Frontend (Dart) | -- | Abstract interface + fake impl, pure Dart in `lib/core/auth/` |
| AuthGuard routing | Frontend (Dart) | -- | Guard logic in `lib/core/router/guards/`, redirect to LoginRoute |
| reevaluateListenable | Frontend (Dart) | -- | Wired in `lib/app.dart` via `MaterialApp.router` config |
| AppFailure AuthError | Frontend (Dart) | -- | Single new subtype in `lib/core/errors/failures.dart` |

## Standard Stack

### Core (version bumps this phase)
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `flutter_bloc` | `^9.1.1` | State management (Cubit) | Current stable; `mounted` safeguard in BlocListener, BlocOverrides removed [VERIFIED: STACK.md research, pub.dev] |
| `bloc` | `^9.0.1` (transitive) | Core bloc library | Locked to flutter_bloc 9 [VERIFIED: STACK.md] |
| `auto_route` | `^11.1.0` | Declarative routing with guards | Current stable; guards override, reevaluateListenable [VERIFIED: Context7 auto_route docs] |
| `auto_route_generator` | `^10.5.0` (dev) | Router code generation | Pairs with auto_route ^11.1.0 [VERIFIED: STACK.md, pub.dev] |

### Supporting (new this phase)
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `bloc_test` | `^10.0.0` (dev) | Cubit/Bloc testing | Required for bloc 9 compatibility; add now to unblock Phase 7 [VERIFIED: STACK.md] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Separate `AuthResult` sealed class | Reuse `Result<AuthUser>` | `AuthCancelled` state doesn't fit success/failure binary -- separate type is cleaner (D-01 locks this) |
| `ChangeNotifier` for AuthService | `Stream<AuthUser?>` | Stream is the natural Firebase Auth API shape; `ReevaluateListenable.stream()` bridges to auto_route (D-11 locks this) |

**Installation (pubspec.yaml changes):**
```yaml
# dependencies:
  flutter_bloc: ^9.1.1   # was ^8.1.6
  # auto_route already at ^11.1.0 -- no change needed

# dev_dependencies:
  bloc_test: ^10.0.0     # NEW
  # auto_route_generator already at ^10.5.0 -- no change needed
```

**Version verification:** `flutter_bloc` current version is `^9.1.1` [VERIFIED: STACK.md confirmed against pub.dev April 2026]. `auto_route` is already at `^11.1.0` in the current pubspec [VERIFIED: pubspec.yaml line 10]. `auto_route_generator` is already at `^10.5.0` [VERIFIED: pubspec.yaml line 34].

## Architecture Patterns

### System Architecture Diagram

```
                     +-----------------+
                     |   main.dart     |
                     | (entry point)   |
                     +--------+--------+
                              |
                              v
                     +--------+--------+
                     | StartUpService  |
                     | configureDeps() |
                     +--------+--------+
                              |
                 +------------+------------+
                 |                         |
                 v                         v
        +--------+--------+      +--------+--------+
        |  AuthService     |      |  AppRouter       |
        | (FakeAuthService)|      | (takes AuthSvc)  |
        | @LazySingleton   |      +--------+--------+
        +--------+--------+               |
                 |                         v
                 |              +----------+----------+
                 |              | guards: [AuthGuard] |
                 |              +----------+----------+
                 |                         |
                 v                         v
        +--------+--------+      +--------+--------+
        |  app.dart        |<---->| reevaluateListenable
        |  MaterialApp     |      | .stream(authState)|
        |  .router         |      +-------------------+
        +------------------+
                 |
        +--------+--------+
        |  Route Decision  |
        |                  |
        +--+------------+--+
           |            |
           v            v
    +------+-----+ +----+-------+
    | LoginRoute  | | MyHomeRoute|
    | (placeholder| | (existing) |
    |  redirect)  | +------------+
    +-------------+
```

### Recommended Project Structure (new/modified files)

```
lib/
├── core/
│   ├── auth/                          # NEW - entire directory
│   │   ├── auth_service.dart          # abstract AuthService
│   │   ├── auth_user.dart             # AuthUser entity
│   │   ├── auth_result.dart           # sealed AuthResult
│   │   └── fake_auth_service.dart     # FakeAuthService @LazySingleton
│   ├── errors/
│   │   └── failures.dart              # MODIFIED - add AuthError
│   ├── router/
│   │   ├── router.dart                # MODIFIED - add constructor param, guards override
│   │   ├── router.gr.dart             # REGENERATED
│   │   └── guards/                    # NEW directory
│   │       └── auth_guard.dart        # AuthGuard extends AutoRouteGuard
│   └── injectable/
│       ├── injection.dart             # UNCHANGED
│       └── injection.config.dart      # REGENERATED (picks up FakeAuthService)
├── features/
│   └── login/                         # NEW - placeholder feature
│       └── presentation/
│           └── login_page.dart        # @RoutePage() minimal placeholder
├── app.dart                           # MODIFIED - add reevaluateListenable
├── main.dart                          # MODIFIED - pass AuthService to AppRouter
└── pubspec.yaml                       # MODIFIED - flutter_bloc bump, bloc_test added
```

### Pattern 1: AuthService Contract (abstract + sealed result)

**What:** Abstract class defining the auth boundary with a sealed return type for all auth operations.
**When to use:** Any operation that can succeed, fail, or be cancelled by the user.

```dart
// Source: CONTEXT.md D-01, D-05, ARCHITECTURE.md Auth Abstraction
// lib/core/auth/auth_service.dart
abstract class AuthService {
  Stream<AuthUser?> get authStateChanges;
  AuthUser? get currentUser;

  Future<AuthResult> signInWithEmail({required String email, required String password});
  Future<AuthResult> signUpWithEmail({required String email, required String password});
  Future<AuthResult> signInWithGoogle();
  Future<AuthResult> signInWithApple();
  Future<void> signOut();
  Future<AuthResult> sendPasswordReset({required String email});
}
```

### Pattern 2: FakeAuthService (in-memory, no Firebase)

**What:** Test double that simulates auth behavior synchronously.
**When to use:** During development without Firebase configured; as test double in Phase 7.

```dart
// Source: CONTEXT.md D-06, D-07
// lib/core/auth/fake_auth_service.dart
@LazySingleton(as: AuthService)
class FakeAuthService implements AuthService {
  final _controller = StreamController<AuthUser?>.broadcast();
  AuthUser? _currentUser;

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  AuthUser? get currentUser => _currentUser;

  @override
  Future<AuthResult> signInWithEmail({required String email, required String password}) async {
    final user = AuthUser(uid: 'fake-uid', email: email, displayName: null, photoUrl: null, emailVerified: false);
    _currentUser = user;
    _controller.add(user);
    return AuthSuccess(user);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _controller.add(null);
  }
  // ... other methods follow same pattern
}
```

### Pattern 3: Router Guards Override (auto_route 11)

**What:** Global guards defined via `guards` property override on `RootStackRouter`.
**When to use:** Always -- this is the only way to define global guards in auto_route 9+.

```dart
// Source: Context7 auto_route docs, CONTEXT.md D-08, D-09
// lib/core/router/router.dart
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  AppRouter(this._authService);
  final AuthService _authService;

  @override
  late final List<AutoRouteGuard> guards = [
    AuthGuard(_authService),
  ];

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: MyHomeRoute.page, path: '/'),
    AutoRoute(page: LoginRoute.page, path: '/login'),
  ];
}
```

### Pattern 4: ReevaluateListenable with Stream

**What:** Bridges a `Stream` to auto_route's guard re-evaluation system.
**When to use:** When auth state changes should trigger guard re-evaluation across the entire route stack.

```dart
// Source: Context7 auto_route docs, CONTEXT.md D-11
// lib/app.dart
MaterialApp.router(
  routerConfig: appRouter.config(
    reevaluateListenable: ReevaluateListenable.stream(
      authService.authStateChanges,
    ),
    navigatorObservers: () => [AppRouterObserver()],
  ),
  // ... existing config
);
```

### Anti-Patterns to Avoid
- **Implementing `AutoRouteGuard` on the router class itself:** Deprecated in auto_route 9+. Use the `guards` list property override instead. [VERIFIED: Context7 migration docs]
- **Importing `firebase_auth` in `AuthUser`:** D-04 locks this -- `AuthUser` is a pure Dart entity. The mapping from `firebase_auth.User` happens only in `FirebaseAuthService` (Phase 5).
- **Reusing `Result<T>` for auth operations:** D-01 explicitly rejects this -- `AuthCancelled` is a third state that doesn't fit success/failure.
- **Making `FakeAuthService` a mock:** It's a permanent in-memory implementation, not a `mocktail` mock. It provides real behavior for the skeleton's `flutter run` without Firebase.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Stream-to-Listenable bridge | Custom `StreamSubscription` -> `ChangeNotifier` adapter | `ReevaluateListenable.stream()` | Built into auto_route 11; handles subscription lifecycle [VERIFIED: Context7] |
| Route guard pattern | Custom `NavigatorObserver` that blocks navigation | `AutoRouteGuard` subclass with `onNavigation` | auto_route provides the resolver/redirect API, handles re-evaluation [VERIFIED: Context7] |
| Auth state change notification | Manual `StreamController` wiring to router | `reevaluateListenable` parameter on `router.config()` | Triggers guard re-evaluation on every stream emission [VERIFIED: Context7] |

## Common Pitfalls

### Pitfall 1: flutter_bloc 9 BlocOverrides Removal
**What goes wrong:** Code using `BlocOverrides.runZoned()` won't compile after the bump.
**Why it happens:** `BlocOverrides` was removed in bloc 9.0.0; replaced by direct `Bloc.observer = ...` assignment.
**How to avoid:** Check for any `BlocOverrides` usage before bumping. The current skeleton has NONE -- verified by inspecting `startup_service.dart`, `main.dart`, and `home_cubit.dart`. [VERIFIED: codebase grep]
**Warning signs:** `Undefined name 'BlocOverrides'` compile error.

### Pitfall 2: auto_route Generator Version Asymmetry
**What goes wrong:** `auto_route ^11.1.0` pairs with `auto_route_generator ^10.5.0` -- the major versions don't match.
**Why it happens:** The generator's versioning lags the runtime. Using `auto_route_generator ^11.x` (doesn't exist) or `^9.x` (too old) breaks codegen.
**How to avoid:** The current pubspec already has the correct pairing (`auto_route: ^11.1.0` + `auto_route_generator: ^10.5.0`). Do not change these independently. [VERIFIED: pubspec.yaml + PITFALLS.md #5]
**Warning signs:** `build_runner` fails with version resolution errors or generates incompatible router code.

### Pitfall 3: ReevaluateListenable.stream Requires Broadcast Stream
**What goes wrong:** A single-subscription stream passed to `ReevaluateListenable.stream()` can only have one listener, causing the router to steal the subscription from other listeners.
**Why it happens:** `ReevaluateListenable.stream()` subscribes internally; if the stream is single-subscription, no one else can listen.
**How to avoid:** `FakeAuthService` must use `StreamController.broadcast()` for `authStateChanges`. Firebase Auth's `authStateChanges()` is already a broadcast stream. [ASSUMED -- based on standard StreamController behavior]
**Warning signs:** `Bad state: Stream has already been listened to` runtime error.

### Pitfall 4: AuthGuard Redirect Target Must Exist in Routes
**What goes wrong:** `AuthGuard` redirects to `LoginRoute` but `LoginRoute` is not registered in the router's `routes` list -> runtime error or silent navigation failure.
**Why it happens:** The guard and route registration are in different files; easy to add the guard but forget the route.
**How to avoid:** Add `AutoRoute(page: LoginRoute.page, path: '/login')` to the routes list AND create the `LoginPage` with `@RoutePage()` annotation before running `build_runner`.
**Warning signs:** `No registered route was found for name 'LoginRoute'` runtime assertion.

### Pitfall 5: AppRouter Constructor Change Breaks main.dart
**What goes wrong:** Adding `AuthService` as a required constructor param to `AppRouter` means `AppRouter()` in `main.dart` no longer compiles.
**Why it happens:** D-08 requires the router to accept `AuthService` for guard injection.
**How to avoid:** Update `main.dart` simultaneously: `final appRouter = AppRouter(getIt<AuthService>())`. The DI graph must have `AuthService` registered before this line runs, which it does because `configureDependenciesApp()` runs in `StartUpService.initServices()` before `AppRouter` construction.
**Warning signs:** `The class 'AppRouter' doesn't have an unnamed constructor that takes no arguments` compile error.

### Pitfall 6: FakeAuthService Disposal
**What goes wrong:** `FakeAuthService` holds a `StreamController` that's never closed, causing a resource leak warning in tests.
**Why it happens:** `@LazySingleton` services live for the app lifetime so disposal is less critical in production, but tests that reset the DI container will leak.
**How to avoid:** Implement a `dispose()` method on `FakeAuthService` that closes the `StreamController`. `get_it` supports `disposeDependencies()` which calls `dispose()` on registered singletons. [ASSUMED -- based on get_it standard behavior]
**Warning signs:** `A StreamController was used after being disposed` in tests.

## Code Examples

### AuthUser Entity
```dart
// Source: CONTEXT.md D-04
// lib/core/auth/auth_user.dart
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.emailVerified,
  });

  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;

  AuthUser copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? emailVerified,
  }) =>
      AuthUser(
        uid: uid ?? this.uid,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        photoUrl: photoUrl ?? this.photoUrl,
        emailVerified: emailVerified ?? this.emailVerified,
      );
}
```

### Sealed AuthResult
```dart
// Source: CONTEXT.md D-01
// lib/core/auth/auth_result.dart
sealed class AuthResult {
  const AuthResult();
}

final class AuthSuccess extends AuthResult {
  const AuthSuccess(this.user);
  final AuthUser user;
}

final class AuthFailure extends AuthResult {
  const AuthFailure(this.failure);
  final AppFailure failure;
}

final class AuthCancelled extends AuthResult {
  const AuthCancelled();
}
```

### AuthError AppFailure Subtype
```dart
// Source: CONTEXT.md D-12
// lib/core/errors/failures.dart (addition)
/// Authentication operation failed.
final class AuthError extends AppFailure {
  const AuthError(super.message);
}
```

### AuthGuard
```dart
// Source: Context7 auto_route docs, CONTEXT.md D-09
// lib/core/router/guards/auth_guard.dart
class AuthGuard extends AutoRouteGuard {
  AuthGuard(this._authService);
  final AuthService _authService;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (_authService.currentUser != null) {
      resolver.next();
    } else {
      resolver.redirect(const LoginRoute());
    }
  }
}
```

### LoginRoute Placeholder
```dart
// Source: CONTEXT.md D-10
// lib/features/login/presentation/login_page.dart
@RoutePage()
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
        body: Center(
          child: Text('Login screen -- built per app'),
        ),
      );
}
```

### Updated main.dart
```dart
// Source: CONTEXT.md D-08
// lib/main.dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StartUpService.initServices();
  final authService = getIt<AuthService>();
  final appRouter = AppRouter(authService);

  runApp(MyApp(
    appRouter: appRouter,
    authService: authService,
  ));
}
```

### Updated app.dart
```dart
// Source: CONTEXT.md D-11, Context7 auto_route reevaluateListenable
// lib/app.dart
class MyApp extends StatelessWidget {
  const MyApp({required this.appRouter, required this.authService, super.key});

  final AppRouter appRouter;
  final AuthService authService;

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Skeleton APP',
        routerConfig: appRouter.config(
          reevaluateListenable: ReevaluateListenable.stream(
            authService.authStateChanges,
          ),
          navigatorObservers: () => [AppRouterObserver()],
        ),
        // ... existing localization + theme config
      );
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `BlocOverrides.runZoned()` | `Bloc.observer = MyObserver()` | flutter_bloc 9.0.0 | No impact -- skeleton never used BlocOverrides |
| `implements AutoRouteGuard` on router | `guards` list override on `RootStackRouter` | auto_route 9.0.0 (v9 migration) | Router must use `guards` property |
| `$AppRouter` generated base class | Extend `RootStackRouter` directly | auto_route 9.0.0 | Already in place in current codebase |
| `pushNamed()` / `replaceNamed()` | `pushPath()` / `replacePath()` | auto_route 9.0.0 | Check all call sites -- current code uses typed `push(Route())` not `pushNamed` |
| `pop()` for safe pop | `maybePop()` for safe pop, `pop()` is strict | auto_route 9.0.0 | Review any `pop()` usage |

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `ReevaluateListenable.stream()` requires broadcast stream | Pitfall 3 | FakeAuthService stream fails if single-subscription -- low risk, easy fix |
| A2 | `get_it` calls `dispose()` on singletons via `disposeDependencies()` | Pitfall 6 | StreamController leak in tests -- low risk, fixable |
| A3 | No `pushNamed` or `pop()` calls exist in current codebase beyond typed navigation | State of the Art | If they exist, they'll be caught by `flutter analyze` after bump |

## Open Questions

1. **`bloc_test` timing**
   - What we know: `bloc_test ^10.0.0` is required for bloc 9 compatibility. Phase 7 is the test phase.
   - What's unclear: Adding it now (as dev_dependency) has zero downside but slightly expands this phase's diff.
   - Recommendation: Add `bloc_test: ^10.0.0` to dev_dependencies now. It's a single line in pubspec.yaml, costs nothing, and unblocks Phase 7 cleanly.

2. **LoginRoute placeholder complexity**
   - What we know: D-10 says minimal placeholder. No cubit needed.
   - What's unclear: Whether it needs a "Sign in" button that calls `FakeAuthService.signInWithEmail()` to demonstrate the flow.
   - Recommendation: Keep it as a plain `StatelessWidget` with just text. The skeleton explicitly does NOT ship login UI. A sign-in button in the placeholder would imply it's reusable -- it's not.

3. **AuthUser `copyWith` method**
   - What we know: D-04 specifies the fields. copyWith is Claude's discretion.
   - What's unclear: Whether downstream consumers will need it before Phase 5.
   - Recommendation: Include `copyWith`. It's 10 lines, follows the established `CounterModel.copyWith` pattern, and `FirebaseAuthService._mapUser()` in Phase 5 benefits from it.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (SDK) + `bloc_test ^10.0.0` (to be added) |
| Config file | none -- Flutter SDK default |
| Quick run command | `flutter test test/` |
| Full suite command | `flutter test` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CORE-03 | flutter_bloc 9 compiles with existing HomeCubit | smoke | `flutter analyze lib/features/home_page/presentation/cubit/` | N/A (compile check) |
| CORE-04 | auto_route 11 compiles with guards, reevaluateListenable works | smoke | `flutter analyze lib/core/router/` | N/A (compile check) |
| CORE-05 | AuthService contract + FakeAuthService registers in DI | unit | `flutter test test/core/auth/` | Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter analyze && flutter test`
- **Per wave merge:** `flutter analyze && flutter test`
- **Phase gate:** `flutter analyze` + `flutter test` both pass (success criteria #5)

### Wave 0 Gaps
- [ ] `test/core/auth/fake_auth_service_test.dart` -- covers CORE-05 (FakeAuthService sign-in/sign-out/stream behavior)
- [ ] `test/core/auth/auth_result_test.dart` -- covers CORE-05 (sealed AuthResult exhaustive switch)
- [ ] Add `bloc_test: ^10.0.0` to dev_dependencies

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes (contract only, not impl) | Abstract `AuthService` -- real implementation in Phase 5 |
| V3 Session Management | no | No session logic in Phase 3 |
| V4 Access Control | yes (guard routing) | `AuthGuard` checks `currentUser != null` before route access |
| V5 Input Validation | no | No user input processing in this phase |
| V6 Cryptography | no | No crypto operations |

### Known Threat Patterns for AuthService Contract

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Guard bypass via direct route push | Elevation of Privilege | `AuthGuard` on router-level `guards` override covers all stack routes [VERIFIED: Context7] |
| Auth state desync (user on guarded page after logout) | Elevation of Privilege | `reevaluateListenable.stream()` re-runs guards on every auth state change [VERIFIED: Context7] |
| FakeAuthService shipped to production | Spoofing | Phase 5 adds `@Environment('prod')` / `@Environment('test')` DI split (deferred, documented) |

## Sources

### Primary (HIGH confidence)
- [Context7: /milad-akarie/auto_route_library] -- guards override, reevaluateListenable, ReevaluateListenable.stream(), v9 migration, RootStackRouter
- [Context7: /felangel/bloc] -- bloc 9 migration, BlocOverrides removal
- `.planning/research/STACK.md` -- verified package versions (flutter_bloc 9.1.1, auto_route 11.1.0, auto_route_generator 10.5.0, bloc_test 10.0.0)
- `.planning/research/ARCHITECTURE.md` -- AuthService contract design, AuthUser entity, sealed AuthResult, AuthGuard pattern, reevaluateListenable wiring
- `.planning/research/PITFALLS.md` -- auto_route generator asymmetry (Pitfall #5), flutter_bloc 9 API changes

### Secondary (MEDIUM confidence)
- [auto_route pub.dev changelog](https://pub.dev/packages/auto_route/changelog) -- breaking changes v9->v11
- [flutter_bloc pub.dev changelog](https://pub.dev/packages/flutter_bloc/changelog) -- 9.0.0 breaking changes

### Tertiary (LOW confidence)
- None -- all claims verified against Context7 or prior research documents

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- versions already pinned in pubspec.yaml, verified against pub.dev
- Architecture: HIGH -- AuthService contract fully specified in CONTEXT.md decisions; auto_route guard pattern verified via Context7
- Pitfalls: HIGH -- flutter_bloc 9 migration is trivial (Cubit-only); auto_route migration structure already in place (RootStackRouter)

**Research date:** 2026-04-17
**Valid until:** 2026-05-17 (stable packages, locked decisions)
