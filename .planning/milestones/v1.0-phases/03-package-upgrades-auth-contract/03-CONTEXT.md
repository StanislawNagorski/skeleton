# Phase 3: Package Upgrades + Auth Contract - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

Bump `flutter_bloc` 8→9 and `auto_route` 9→11 (with `auto_route_generator` 10.5.0), lock the abstract `AuthService` contract (+ `AuthUser` entity + sealed `AuthResult`) in `lib/core/auth/`, ship a `FakeAuthService` impl for DI and tests, wire an `AuthGuard` on the router via the new `guards` override + `reevaluateListenable`, and add an `AuthError` subtype to the `AppFailure` hierarchy. This phase does **not** touch Firebase dependencies, flavors, onboarding, or RIVE — those are owned by Phases 4–6.

</domain>

<decisions>
## Implementation Decisions

### AuthService contract shape
- **D-01:** Separate `sealed class AuthResult` with `AuthSuccess(AuthUser)` / `AuthFailure(AppFailure)` / `AuthCancelled()`. Not a reuse of `Result<T>` — auth operations have a distinct "cancelled" state that doesn't map to success/failure.
- **D-02:** Separate methods for sign-in vs sign-up: `signInWithEmail()` + `signUpWithEmail()`. Maps 1:1 to Firebase Auth's API. No mode-flag indirection.
- **D-03:** `sendPasswordReset({required String email})` lives on `AuthService` — keeps all auth operations on one interface.
- **D-04:** `AuthUser` exposes the full set: `uid`, `email` (String?), `displayName` (String?), `photoUrl` (String?), `emailVerified` (bool). Pure Dart entity, zero `firebase_auth` imports.
- **D-05:** Full contract surface:
  - `Stream<AuthUser?> get authStateChanges`
  - `AuthUser? get currentUser`
  - `Future<AuthResult> signInWithEmail({required String email, required String password})`
  - `Future<AuthResult> signUpWithEmail({required String email, required String password})`
  - `Future<AuthResult> signInWithGoogle()`
  - `Future<AuthResult> signInWithApple()`
  - `Future<void> signOut()`
  - `Future<AuthResult> sendPasswordReset({required String email})`

### AuthService impl timing
- **D-06:** Phase 3 ships abstract `AuthService` + a `FakeAuthService` (in-memory, no Firebase imports) registered as `@LazySingleton(as: AuthService)`. Phase 5 adds `FirebaseAuthService` with real Firebase wiring.
- **D-07:** `FakeAuthService` is **kept permanently** as a test double. Phase 5 adds `@Environment('prod')` on `FirebaseAuthService` and `@Environment('test')` on `FakeAuthService` for DI environment switching.

### auto_route 11 guard wiring
- **D-08:** `AppRouter` takes `AuthService` as a constructor param **now in Phase 3**. Guards wired immediately against `FakeAuthService`.
- **D-09:** Router-level `guards` override returns `[AuthGuard(_authService)]`. `AuthGuard` extends `AutoRouteGuard`, checks `_authService.currentUser != null`, redirects to `LoginRoute` if unauthenticated.
- **D-10:** `LoginRoute` is an empty placeholder page (`lib/features/login/presentation/login_page.dart`) that says "Login screen — built per app". Downstream apps replace it.
- **D-11:** `reevaluateListenable: ReevaluateListenable.stream(authService.authStateChanges)` wired in `app.dart`'s `MaterialApp.router` — guards auto-re-run on every auth state flip.

### AppFailure extensions
- **D-12:** Single new subtype: `final class AuthError extends AppFailure`. Specific sub-cases (wrong-password, user-not-found) are message strings within `AuthError`. Phase 5 can refine with granular subtypes if needed.

### Claude's Discretion
- `flutter_bloc` 9 migration details — the existing `HomeCubit` uses `Cubit` (not `Bloc`), so migration should be trivial; Claude handles the specific API changes
- Whether to add `bloc_test ^10.0.0` to dev_dependencies now or defer to Phase 7 (tests)
- `auto_route` 11 migration specifics: `pushNamed` → `pushPath`, `pop` → `maybePop` if applicable to existing code
- `FakeAuthService` internal behavior details (delay simulation, configurable success/failure modes)
- Whether `LoginRoute` placeholder needs its own cubit or is a simple `StatelessWidget`
- `AuthUser` `copyWith` method inclusion

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Package upgrade specifics
- `.planning/research/STACK.md` §State Management (flutter_bloc 9) — version pin (`^9.1.1`), migration cost assessment, `mounted` safeguard in `BlocListener`
- `.planning/research/STACK.md` §Routing (auto_route 11) — version pins (`^11.1.0` + `^10.5.0` generator), breaking changes from 9→11, guard API changes
- `.planning/research/PITFALLS.md` §5 — auto_route runtime-generator major asymmetry warning

### AuthService contract and architecture
- `.planning/research/ARCHITECTURE.md` §Auth Abstraction (AuthService sealed results + streams) — full contract definition, `AuthUser` domain type, sealed `AuthResult`, `FirebaseAuthService` pattern, `reevaluateListenable` wiring
- `.planning/research/ARCHITECTURE.md` §Directory tree — `lib/core/auth/` structure: `auth_service.dart`, `firebase_auth_service.dart`, `auth_user.dart`, `auth_result.dart`
- `.planning/research/ARCHITECTURE.md` §Routing & Navigation — `AuthGuard` pattern, `reevaluateListenable` stream adapter, guard override on `RootStackRouter`

### DI patterns
- `.planning/research/ARCHITECTURE.md` §Scoping table — `@lazySingleton` for services, `@injectable` factory for cubits, `@Environment` for test/prod switching

### Phase requirements and success criteria
- `.planning/REQUIREMENTS.md` §Core Dart Abstractions (CORE-03, CORE-04, CORE-05)
- `.planning/ROADMAP.md` §Phase 3 Success Criteria 1–5

### Existing code to modify
- `lib/core/router/router.dart` — current `AppRouter` (no constructor params, no guards)
- `lib/core/errors/failures.dart` — current sealed `AppFailure` hierarchy (add `AuthError`)
- `lib/app.dart` — current `MaterialApp.router` setup (add `reevaluateListenable`)
- `lib/main.dart` — `AppRouter()` instantiation (add `AuthService` param)
- `pubspec.yaml` — `flutter_bloc` + `auto_route` + `auto_route_generator` version bumps

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **Sealed `Result<T>` + `AppFailure`** (Phase 2): `AuthResult` follows the same sealed-class pattern but is a separate type. `AuthFailure` wraps `AppFailure` to reuse the failure hierarchy.
- **`@lazySingleton` DI pattern** (Phase 2): `FakeAuthService` follows the same annotation pattern as `PreferencesService`, `SecureStorageService`, `AppDatabase`.
- **`AppRouterObserver`**: already in `router.dart`, preserved — just add guards alongside it.

### Established Patterns
- **Abstract class + Impl**: `AuthService` / `FakeAuthService` follows the same convention as `CounterRepository` / `CounterRepositoryImpl`.
- **`part`/`part of` for cubit + state**: unchanged by bloc 9 upgrade.
- **`switch` exhaustive pattern matching**: established in Phase 2 for `Result<T>`, now applied to `AuthResult` in downstream cubits.

### Integration Points
- **Phase 4 inherits**: `AuthService` contract + `FakeAuthService` in DI. Flavor entrypoints (`main_dev.dart`, `main_prod.dart`) will construct `AppRouter(getIt<AuthService>())`.
- **Phase 5 inherits**: Abstract `AuthService` contract to implement with `FirebaseAuthService`. `FakeAuthService` stays as `@Environment('test')`. `AuthGuard` and `reevaluateListenable` already wired — just swap the DI registration.
- **Phase 6 inherits**: `OnboardingGuard` added to router `guards` list alongside `AuthGuard`. `PreferencesService` (from Phase 2) used for the `hasSeenOnboarding` flag.

</code_context>

<specifics>
## Specific Ideas

- **FakeAuthService as permanent fixture**: the skeleton's DX promise means `flutter run` works without Firebase configured. `FakeAuthService` makes that possible even after auth guards are wired. It also serves as the test double for Phase 7's reference tests.
- **LoginRoute placeholder is intentional**: the skeleton explicitly does NOT ship login UI (out of scope). But the guard needs somewhere to redirect. A minimal placeholder page makes the routing testable and gives downstream apps a clear "replace this" anchor.
- **`reevaluateListenable` is the key auto_route 11 feature**: this single wiring point means guards re-run on logout (even if the user is deep in a guarded route stack), which is the behavior every real app needs.

</specifics>

<deferred>
## Deferred Ideas

- `OnboardingGuard` wiring on the router → Phase 6 (onboarding feature)
- `@Environment('prod')` / `@Environment('test')` DI split → Phase 5 (when `FirebaseAuthService` lands)
- Granular auth failure subtypes (`AuthInvalidCredentials`, `AuthUserNotFound`, etc.) → Phase 5 if Firebase error codes warrant it
- `bloc_test ^10.0.0` for bloc 9 → Phase 7 (tests) unless Claude adds it earlier at discretion

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-package-upgrades-auth-contract*
*Context gathered: 2026-04-17*
