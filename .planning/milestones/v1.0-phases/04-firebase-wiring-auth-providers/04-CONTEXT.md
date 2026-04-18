# Phase 4: Firebase Wiring + Auth Providers - Context

**Gathered:** 2026-04-17
**Status:** Ready for planning

<domain>
## Phase Boundary

End-to-end FlutterFire BoM 4.12.0 wiring (Core, Auth, Firestore, Crashlytics, Analytics, Performance, App Check) with `FirebaseAuthService` implementing the `AuthService` contract locked in Phase 3. Native Email/Google/Apple sign-in providers function against a single Firebase project configured post-clone via `flutterfire configure`. The skeleton remains bootable without Firebase — `FakeAuthService` stays as the fallback when no config files are present. This phase does **not** touch onboarding, RIVE, coach marks, bootstrap script, or tests — those are owned by Phases 5–7.

</domain>

<decisions>
## Implementation Decisions

### Startup sequence & DI switchover
- **D-01:** The skeleton boots with `flutter run` even when no Firebase config files are present. `StartUpService` tries `Firebase.initializeApp` — if it succeeds, the `'prod'` DI environment is used (registering `FirebaseAuthService`); if it fails (no config), the `'dev'` environment is used (registering `FakeAuthService`). This preserves the DX promise: `clone → flutter run` works immediately.
- **D-02:** DI switching uses injectable's `@Environment` annotations. `FakeAuthService` is `@Environment('dev')`, `FirebaseAuthService` is `@Environment('prod')`. `configureDependencies()` receives the environment string determined by `StartUpService` based on Firebase availability. Custom-backend apps add their own impl under a new environment.
- **D-03:** `Firebase.initializeApp` lives in `StartUpService.initServices()`, before DI registration. Full sequence: `WidgetsFlutterBinding.ensureInitialized()` → try `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` → if success: wire Crashlytics hooks + activate App Check → `configureDependencies(env)`. Single file owns all startup logic.

### Google & Apple Sign-In native setup
- **D-04:** Ship full Dart code for Google + Apple sign-in in `FirebaseAuthService`. All native config (Info.plist URL schemes, reversed client ID, Xcode Sign in with Apple entitlement, build.gradle OAuth entries) is **documented as a README checklist** for post-bootstrap, not pre-wired in skeleton native files. Keeps the skeleton clean — no placeholder client IDs that break builds.
- **D-05:** Google Sign-In `serverClientId` on Android (required by `google_sign_in` 7.x) is read from `DefaultFirebaseOptions` at runtime. After `flutterfire configure` generates `firebase_options.dart`, the Web client ID is already there. Zero manual config for Google Sign-In on Android.
- **D-06:** Apple Sign-In Xcode entitlement (`Sign in with Apple` capability) is documented only, not pre-enabled. Avoids entitlement/bundle-ID mismatches after bootstrap renames the bundle ID. README documents: enable capability in Xcode for your target.

### Crashlytics & error handler wiring
- **D-07:** Crashlytics collection disabled in debug builds: `setCrashlyticsCollectionEnabled(kReleaseMode)`. Debug crashes stay local (console only). No dashboard noise from dev sessions.
- **D-08:** Full error handler trio wired: `FlutterError.onError` → `recordFlutterFatalError`, `PlatformDispatcher.instance.onError` → `recordError(fatal: true)`, and `Isolate.current.addErrorListener` → forward to Crashlytics. The isolate listener catches errors in spawned isolates that downstream apps (image processing, Drift heavy queries) will use.

### App Check activation strategy
- **D-09:** Apple provider is `AppleProvider.appAttest` (not `deviceCheck`). Stronger attestation, Apple's recommended path. Skeleton floor is iOS 15, so no compatibility concern (appAttest requires iOS 14+).
- **D-10:** Dev builds skip App Check entirely — `if (kReleaseMode) { FirebaseAppCheck.instance.activate(...) }`. No debug provider activation, no debug-token registration friction. Firebase endpoints are unprotected in dev, which is acceptable for development. Android uses `AndroidProvider.playIntegrity` in release.

### Claude's Discretion
- Firebase package version bumps to BoM 4.12.0 matrix — exact version pins for `firebase_auth`, `google_sign_in`, `sign_in_with_apple` and related packages
- `FirebaseAuthService` internal implementation details: error mapping from `FirebaseAuthException` codes to `AuthError`, stream subscription management, provider-specific sign-in flow details
- Whether to refine `AuthError` into granular subtypes (`AuthInvalidCredentials`, `AuthUserNotFound`, etc.) or keep as single type with message strings (Phase 3 D-12 left this open)
- `cloud_firestore` offline persistence configuration details
- `FirebaseAnalytics` and `FirebasePerformance` DI registration approach (lazy singleton vs module)
- README section structure for the post-bootstrap Firebase + sign-in provider setup checklist

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Firebase & FlutterFire
- `.planning/research/STACK.md` §FlutterFire — BoM 4.12.0 version matrix, package pins
- `.planning/research/PITFALLS.md` §Firebase-flavor coupling — config file network, SHA-1 fingerprint requirements, `sign_in_failed` silent failure
- `.planning/research/PITFALLS.md` §google_sign_in 7.x — `serverClientId` breaking change on Android

### AuthService contract (locked in Phase 3)
- `lib/core/auth/auth_service.dart` — abstract contract: `Stream<AuthUser?>`, 6 sign-in/sign-out methods
- `lib/core/auth/auth_result.dart` — sealed `AuthResult` (`AuthSuccess` / `AuthFailure` / `AuthCancelled`)
- `lib/core/auth/auth_user.dart` — pure Dart `AuthUser` entity (zero Firebase imports)
- `lib/core/auth/fake_auth_service.dart` — in-memory dev placeholder, stays permanently
- `lib/core/errors/failures.dart` — sealed `AppFailure` hierarchy including `AuthError`
- `.planning/phases/03-package-upgrades-auth-contract/03-CONTEXT.md` — Phase 3 decisions D-01 through D-12

### Startup & DI
- `lib/startup_service.dart` — current stub with commented Firebase init + Crashlytics + App Check
- `lib/main.dart` — current entrypoint: `StartUpService.initServices()` → `getIt<AuthService>()` → `AppRouter(authService)`
- `lib/core/injectable/injection.dart` — `configureDependenciesApp()` + `getIt` instance
- `lib/core/injectable/injection.config.dart` — generated DI registrations

### Router & guards
- `lib/core/router/router.dart` — `AppRouter(AuthService)` with `guards` override
- `lib/core/router/guards/auth_guard.dart` — `AuthGuard` checking `currentUser != null`
- `lib/app.dart` — `MaterialApp.router` with `reevaluateListenable: ReevaluateListenable.stream(authService.authStateChanges)`

### Phase requirements and success criteria
- `.planning/REQUIREMENTS.md` §Firebase Integration (FIRE-01 through FIRE-07)
- `.planning/REQUIREMENTS.md` §Firebase Auth (AUTH-01 through AUTH-06)
- `.planning/ROADMAP.md` §Phase 4 Success Criteria 1–5

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- **`AuthService` abstract contract** (Phase 3): `FirebaseAuthService` implements this 1:1. No contract changes needed.
- **`FakeAuthService`** (Phase 3): Stays as `@Environment('dev')`. Already implements the full contract with in-memory behavior.
- **Sealed `AuthResult`** (Phase 3): `AuthSuccess` / `AuthFailure` / `AuthCancelled` — `FirebaseAuthService` returns these directly.
- **`AuthError extends AppFailure`** (Phase 3): Used in `AuthFailure(AuthError(...))` for Firebase error mapping.
- **`PreferencesService`** (Phase 2): Available if any Firebase feature needs simple key-value persistence.

### Established Patterns
- **Abstract class + `@Environment` DI**: The `FakeAuthService` → `FirebaseAuthService` swap follows the same pattern established for all service abstractions.
- **`StartUpService` as init orchestrator**: Already owns Firebase + DI init sequence. Phase 4 un-comments and restructures the existing stubs.
- **Sealed pattern matching**: Cubits consuming `AuthResult` via `switch` — established in Phase 2 for `Result<T>`.

### Integration Points
- **`main.dart`**: `StartUpService.initServices()` already called. Phase 4 makes Firebase init real inside it. `getIt<AuthService>()` resolves to `FirebaseAuthService` or `FakeAuthService` based on environment.
- **`AppRouter(authService)`**: Already wired. `AuthGuard` + `reevaluateListenable` work with any `AuthService` impl.
- **`pubspec.yaml`**: Firebase packages already declared but at old versions. Phase 4 bumps to BoM 4.12.0 and adds `firebase_auth`, `google_sign_in`, `sign_in_with_apple`.

</code_context>

<specifics>
## Specific Ideas

- **"What if I have an app with a custom backend and no Firebase?"** — The `AuthService` contract is the stable boundary. `FakeAuthService` is a dev placeholder, never production. Custom-backend apps write their own `CustomBackendAuthService implements AuthService`, register under a new `@Environment`, and optionally strip Firebase packages. The skeleton doesn't need to ship a custom-backend template — that's per-app work.
- **`serverClientId` from `DefaultFirebaseOptions`** — No manual OAuth client ID configuration. `flutterfire configure` generates the file, `FirebaseAuthService` reads it at runtime. This is the zero-friction path for Google Sign-In on Android.

</specifics>

<deferred>
## Deferred Ideas

- `@Environment('prod')` / `@Environment('test')` split for test harness — wire when Phase 6 adds reference tests
- Granular auth failure subtypes (`AuthInvalidCredentials`, `AuthUserNotFound`, etc.) — Claude's discretion based on Firebase error codes encountered during implementation
- `OnboardingGuard` wiring on the router → Phase 5 (onboarding feature)

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-firebase-wiring-auth-providers*
*Context gathered: 2026-04-17*
