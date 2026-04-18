# Phase 4: Firebase Wiring + Auth Providers - Research

**Researched:** 2026-04-17
**Domain:** FlutterFire BoM 4.12.0, Firebase Auth with Google/Apple/Email providers, Crashlytics, App Check, injectable environment switching
**Confidence:** HIGH

## Summary

Phase 4 wires end-to-end Firebase into a skeleton that already has a clean `AuthService` contract (Phase 3), `FakeAuthService` dev placeholder, injectable DI, and auto_route guards. The work divides into three areas: (1) Firebase core initialization with graceful fallback when no config files are present, (2) `FirebaseAuthService` implementing the locked `AuthService` contract with Email, Google, and Apple providers, and (3) Crashlytics error hooks, App Check release-only activation, and DI registration for Analytics/Performance/Firestore.

The FlutterFire BoM 4.12.0 version matrix has been verified on pub.dev -- all seven packages published within the last week (2026-04-13). The existing `startup_service.dart` already has Crashlytics + App Check stubs that need restructuring (not writing from scratch). The `injectable` generated code already accepts an `environment` parameter in `$initGetIt` but `configureDependenciesApp()` doesn't pass one yet -- this is the exact integration point for D-01/D-02 environment switching.

**Primary recommendation:** Implement Firebase init with try/catch fallback in `StartUpService`, then `FirebaseAuthService` as `@LazySingleton(as: AuthService, env: [Environment.prod])` alongside the existing `FakeAuthService` as `@LazySingleton(as: AuthService, env: [Environment.dev])`, passing the environment string from startup to `configureDependenciesApp(environment)`.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** The skeleton boots with `flutter run` even when no Firebase config files are present. `StartUpService` tries `Firebase.initializeApp` -- if it succeeds, the `'prod'` DI environment is used (registering `FirebaseAuthService`); if it fails (no config), the `'dev'` environment is used (registering `FakeAuthService`). This preserves the DX promise: `clone -> flutter run` works immediately.
- **D-02:** DI switching uses injectable's `@Environment` annotations. `FakeAuthService` is `@Environment('dev')`, `FirebaseAuthService` is `@Environment('prod')`. `configureDependencies()` receives the environment string determined by `StartUpService` based on Firebase availability. Custom-backend apps add their own impl under a new environment.
- **D-03:** `Firebase.initializeApp` lives in `StartUpService.initServices()`, before DI registration. Full sequence: `WidgetsFlutterBinding.ensureInitialized()` -> try `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` -> if success: wire Crashlytics hooks + activate App Check -> `configureDependencies(env)`. Single file owns all startup logic.
- **D-04:** Ship full Dart code for Google + Apple sign-in in `FirebaseAuthService`. All native config (Info.plist URL schemes, reversed client ID, Xcode Sign in with Apple entitlement, build.gradle OAuth entries) is documented as a README checklist for post-bootstrap, not pre-wired in skeleton native files. Keeps the skeleton clean -- no placeholder client IDs that break builds.
- **D-05:** Google Sign-In `serverClientId` on Android (required by `google_sign_in` 7.x) is read from `DefaultFirebaseOptions` at runtime. After `flutterfire configure` generates `firebase_options.dart`, the Web client ID is already there. Zero manual config for Google Sign-In on Android.
- **D-06:** Apple Sign-In Xcode entitlement (`Sign in with Apple` capability) is documented only, not pre-enabled. Avoids entitlement/bundle-ID mismatches after bootstrap renames the bundle ID. README documents: enable capability in Xcode for your target.
- **D-07:** Crashlytics collection disabled in debug builds: `setCrashlyticsCollectionEnabled(kReleaseMode)`. Debug crashes stay local (console only). No dashboard noise from dev sessions.
- **D-08:** Full error handler trio wired: `FlutterError.onError` -> `recordFlutterFatalError`, `PlatformDispatcher.instance.onError` -> `recordError(fatal: true)`, and `Isolate.current.addErrorListener` -> forward to Crashlytics. The isolate listener catches errors in spawned isolates that downstream apps (image processing, Drift heavy queries) will use.
- **D-09:** Apple provider is `AppleProvider.appAttest` (not `deviceCheck`). Stronger attestation, Apple's recommended path. Skeleton floor is iOS 15, so no compatibility concern (appAttest requires iOS 14+).
- **D-10:** Dev builds skip App Check entirely -- `if (kReleaseMode) { FirebaseAppCheck.instance.activate(...) }`. No debug provider activation, no debug-token registration friction. Firebase endpoints are unprotected in dev, which is acceptable for development. Android uses `AndroidProvider.playIntegrity` in release.

### Claude's Discretion
- Firebase package version bumps to BoM 4.12.0 matrix -- exact version pins for `firebase_auth`, `google_sign_in`, `sign_in_with_apple` and related packages
- `FirebaseAuthService` internal implementation details: error mapping from `FirebaseAuthException` codes to `AuthError`, stream subscription management, provider-specific sign-in flow details
- Whether to refine `AuthError` into granular subtypes (`AuthInvalidCredentials`, `AuthUserNotFound`, etc.) or keep as single type with message strings (Phase 3 D-12 left this open)
- `cloud_firestore` offline persistence configuration details
- `FirebaseAnalytics` and `FirebasePerformance` DI registration approach (lazy singleton vs module)
- README section structure for the post-bootstrap Firebase + sign-in provider setup checklist

### Deferred Ideas (OUT OF SCOPE)
- `@Environment('prod')` / `@Environment('test')` split for test harness -- wire when Phase 6 adds reference tests
- Granular auth failure subtypes (`AuthInvalidCredentials`, `AuthUserNotFound`, etc.) -- Claude's discretion based on Firebase error codes encountered during implementation
- `OnboardingGuard` wiring on the router -> Phase 5 (onboarding feature)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| FIRE-01 | FlutterFire BoM 4.12.0 matrix pinned in pubspec | Version matrix verified on pub.dev (all 7 packages confirmed); pubspec needs version bumps from current old versions |
| FIRE-02 | `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` called before DI | StartUpService stub exists with commented code; D-03 sequence documented; injectable `$initGetIt` already accepts environment param |
| FIRE-03 | Global error hooks send fatal Dart errors to Crashlytics; collection disabled in debug | Existing `_configureCrashlytics()` stub covers FlutterError + PlatformDispatcher; isolate listener pattern documented in STACK.md |
| FIRE-04 | `FirebaseAnalytics.instance` exposed as injected service | DI registration via injectable module or lazy singleton; no events wired (out of scope per requirements) |
| FIRE-05 | `FirebasePerformance.instance` automatic tracing enabled | Same DI pattern as analytics; automatic tracing is default -- no manual traces needed |
| FIRE-06 | App Check activated only in `kReleaseMode` -- playIntegrity on Android, appAttest on iOS | Existing stub uses deviceCheck; must change to appAttest per D-09; skip entirely in debug per D-10 |
| FIRE-07 | `cloud_firestore` initialized with offline persistence enabled | Default behavior in FlutterFire -- persistence is ON by default on mobile; explicit settings for clarity |
| AUTH-01 | `FirebaseAuthService` subscribes to `authStateChanges()` and re-emits mapped `AuthUser` | `AuthService` contract locked; `FirebaseAuth.instance.authStateChanges()` maps `User` -> `AuthUser` |
| AUTH-02 | Email + Password sign-in and registration via `AuthService` methods | `signInWithEmailAndPassword` / `createUserWithEmailAndPassword` from firebase_auth; wrap in try/catch -> `AuthResult` |
| AUTH-03 | Google Sign-In wired end-to-end with `serverClientId` | google_sign_in 7.x API: `initialize()` + `authenticate()` + `GoogleAuthProvider.credential()` -> `signInWithCredential()` |
| AUTH-04 | Apple Sign-In wired with `sign_in_with_apple` | `SignInWithApple.getAppleIDCredential()` with nonce -> `OAuthProvider("apple.com").credential()` -> `signInWithCredential()` |
| AUTH-05 | README documents SHA-1 workflow, Apple capability, reversed client ID | Phase 4 adds a README section (or separate FIREBASE_SETUP.md); native files not pre-configured |
| AUTH-06 | `signOut()` signs out of all active providers, stream emits null | `FirebaseAuth.instance.signOut()` + `GoogleSignIn.instance.signOut()` |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Firebase initialization | App startup (Dart) | -- | `Firebase.initializeApp` runs in Dart before DI; no native code changes |
| DI environment switching | App startup (Dart) | -- | `StartUpService` determines environment, passes to injectable |
| FirebaseAuthService | Domain/Core (Dart) | Native (iOS/Android config) | Dart code is the impl; native config (google-services.json, GoogleService-Info.plist) is post-bootstrap |
| Google Sign-In flow | Domain/Core (Dart) | Native (iOS URL schemes, Android SHA-1) | `google_sign_in` 7.x handles native bridging; skeleton ships Dart code only |
| Apple Sign-In flow | Domain/Core (Dart) | Native (iOS entitlement) | `sign_in_with_apple` handles bridging; entitlement is post-bootstrap |
| Crashlytics error hooks | App startup (Dart) | -- | Three error listeners wired in startup, all Dart-side |
| App Check activation | App startup (Dart) | Native (Play Integrity / App Attest) | Dart activation code; native attestation providers handled by Firebase SDK |
| Analytics / Performance DI | Core DI (Dart) | -- | Lazy singleton registration only |
| Firestore initialization | Core DI (Dart) | -- | Default settings with offline persistence |
| README documentation | Documentation | -- | Post-bootstrap setup checklist |

## Standard Stack

### Core (new packages for this phase)

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `firebase_auth` | `^6.4.0` | Firebase Authentication SDK | BoM 4.12.0 match; required for auth state + credential sign-in [VERIFIED: pub.dev] |
| `google_sign_in` | `^7.2.0` | Native Google Sign-In | Stream-based 7.x API; singleton pattern with `initialize()` + `authenticate()` [VERIFIED: pub.dev] |
| `sign_in_with_apple` | `^7.0.1` | Native Apple Sign-In | Stable; 8.0.0-spm prerelease skipped (CocoaPods this cycle) [VERIFIED: pub.dev] |
| `crypto` | `^3.0.6` | SHA-256 hashing for Apple nonce | Required by Apple Sign-In nonce flow [VERIFIED: FlutterFire docs] |

### Already in pubspec (version bumps)

| Library | Current | Target | Purpose |
|---------|---------|--------|---------|
| `firebase_core` | `^3.10.0` | `^4.7.0` | BoM 4.12.0 [VERIFIED: pub.dev] |
| `cloud_firestore` | `^5.6.1` | `^6.3.0` | BoM 4.12.0 [VERIFIED: pub.dev] |
| `firebase_crashlytics` | `^4.3.0` | `^5.2.0` | BoM 4.12.0 [VERIFIED: pub.dev] |
| `firebase_analytics` | `^11.4.0` | `^12.3.0` | BoM 4.12.0 [VERIFIED: pub.dev] |
| `firebase_performance` | `^0.10.1` | `^0.11.3` | BoM 4.12.0 [VERIFIED: pub.dev] |
| `firebase_app_check` | `^0.3.2` | `^0.4.3` | BoM 4.12.0 [VERIFIED: pub.dev] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `google_sign_in` 7.x | `googleapis_auth` | Lower-level; no native UI sheet; more manual work |
| `sign_in_with_apple` 7.0.1 | `sign_in_with_apple` 8.0.0-spm | SPM prerelease; skeleton stays CocoaPods |
| `crypto` for nonce | `dart:convert` + manual SHA-256 | `crypto` is the standard; no benefit from hand-rolling |
| Injectable `@Environment` | Manual `if/else` in DI | Breaks the codegen pattern; environment annotations are idiomatic injectable |

**Installation:**
```bash
flutter pub add firebase_auth:^6.4.0 google_sign_in:^7.2.0 sign_in_with_apple:^7.0.1 crypto:^3.0.6
```

**Version bumps (upgrade existing):**
```bash
# Update pubspec.yaml version constraints manually, then:
flutter pub get
```

## Architecture Patterns

### System Architecture Diagram

```
[App Launch]
    |
    v
[main.dart] -- WidgetsFlutterBinding.ensureInitialized()
    |
    v
[StartUpService.initServices()]
    |
    +--try--> [Firebase.initializeApp(DefaultFirebaseOptions.currentPlatform)]
    |             |
    |         success?
    |          /     \
    |        YES      NO (no config files)
    |         |        |
    |         v        v
    |    env='prod'  env='dev'
    |         |        |
    |         +--+-----+
    |            |
    |    [if prod: _configureCrashlytics()]
    |    [if prod: _configureAppCheck() (kReleaseMode only)]
    |            |
    |            v
    |    [configureDependenciesApp(env)]
    |         |                    |
    |    env='prod'           env='dev'
    |         |                    |
    |    registers:           registers:
    |    FirebaseAuthService   FakeAuthService
    |    FirebaseAnalytics     (no Firebase deps)
    |    FirebasePerformance
    |    FirebaseFirestore
    |         |                    |
    |         +--------+-----------+
    |                  |
    v                  v
[getIt<AuthService>()] -- resolves correct impl
    |
    v
[AppRouter(authService)] -- AuthGuard checks currentUser
    |
    v
[MaterialApp.router] -- reevaluateListenable: authService.authStateChanges
```

### Auth Flow (FirebaseAuthService)

```
[User taps "Sign in with Google"]
    |
    v
[FirebaseAuthService.signInWithGoogle()]
    |
    v
[GoogleSignIn.instance.initialize(serverClientId: webClientId)]
    |
    v
[GoogleSignIn.instance.authenticate()]
    |                      |
    success            user cancels
    |                      |
    v                      v
[GoogleAuthProvider.credential(   [return AuthCancelled()]
   accessToken, idToken)]
    |
    v
[FirebaseAuth.instance.signInWithCredential(credential)]
    |
    v
[authStateChanges emits User]
    |
    v
[_mapFirebaseUser(user) -> AuthUser]
    |
    v
[return AuthSuccess(authUser)]
```

### Recommended Project Structure

```
lib/
  core/
    auth/
      auth_service.dart           # Abstract contract (exists, Phase 3)
      auth_result.dart            # Sealed AuthResult (exists, Phase 3)
      auth_user.dart              # Pure Dart entity (exists, Phase 3)
      fake_auth_service.dart      # @Environment('dev') (exists, Phase 3 -- add annotation)
      firebase_auth_service.dart  # @Environment('prod') (NEW -- Phase 4)
    firebase/
      firebase_module.dart        # Injectable module for Analytics, Performance, Firestore (NEW)
    injectable/
      injection.dart              # Updated: configureDependenciesApp(String environment)
      injection.config.dart       # Regenerated with environment-aware registrations
  startup_service.dart            # Restructured: Firebase init + env detection + Crashlytics + App Check
```

### Pattern 1: Injectable Environment Switching

**What:** Use `@Environment` annotations to register different `AuthService` implementations based on Firebase availability.
**When to use:** When the same abstract type has different implementations for different runtime contexts.

```dart
// Source: injectable package docs + existing skeleton DI pattern

// injection.dart -- accept environment parameter
@InjectableInit(
  initializerName: r'$initGetIt',
  preferRelativeImports: true,
  asExtension: false,
)
Future<void> configureDependenciesApp({String environment = 'dev'}) async =>
    $initGetIt(getIt, environment: environment);

// fake_auth_service.dart -- add @Environment annotation
@LazySingleton(as: AuthService, env: [Environment.dev])
class FakeAuthService implements AuthService { ... }

// firebase_auth_service.dart -- prod environment
@LazySingleton(as: AuthService, env: [Environment.prod])
class FirebaseAuthService implements AuthService { ... }
```

[VERIFIED: injectable package supports `env` parameter in `@LazySingleton` and `@Injectable`; `$initGetIt` already generated with `environment` parameter]

### Pattern 2: Firebase Init with Graceful Fallback

**What:** Try Firebase init; catch and fall back to dev mode.
**When to use:** Always -- this is the skeleton's core DX pattern.

```dart
// Source: CONTEXT.md D-01, D-03

static Future<void> initServices() async {
  WidgetsFlutterBinding.ensureInitialized();

  String environment = 'dev';
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    environment = 'prod';
    _configureCrashlytics();
    await _configureAppCheck();
  } on Exception catch (e) {
    // No Firebase config -- running in dev mode.
    Logger().w('Firebase not configured: $e. Running in dev mode.');
  }

  await configureDependenciesApp(environment: environment);
}
```

### Pattern 3: FirebaseAuthService Stream Mapping

**What:** Map `FirebaseAuth.authStateChanges()` to the skeleton's `AuthUser` type.
**When to use:** The core subscription pattern for AUTH-01.

```dart
// Source: firebase_auth API + existing AuthService contract

@LazySingleton(as: AuthService, env: [Environment.prod])
class FirebaseAuthService implements AuthService {
  FirebaseAuthService() {
    _subscription = FirebaseAuth.instance
        .authStateChanges()
        .map(_mapUser)
        .listen(_controller.add);
  }

  final _controller = StreamController<AuthUser?>.broadcast();
  late final StreamSubscription<AuthUser?> _subscription;

  @override
  Stream<AuthUser?> get authStateChanges => _controller.stream;

  @override
  AuthUser? get currentUser => _mapUser(FirebaseAuth.instance.currentUser);

  AuthUser? _mapUser(User? user) {
    if (user == null) return null;
    return AuthUser(
      uid: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      emailVerified: user.emailVerified,
    );
  }

  Future<void> dispose() async {
    await _subscription.cancel();
    await _controller.close();
  }
}
```

### Pattern 4: Google Sign-In (7.x API)

**What:** Full Google Sign-In flow with firebase_auth credential exchange.
**When to use:** AUTH-03 implementation.

```dart
// Source: google_sign_in 7.x pub.dev docs + FlutterFire social auth docs
// IMPORTANT: google_sign_in 7.x is singleton-based with initialize() + authenticate()

@override
Future<AuthResult> signInWithGoogle() async {
  try {
    final googleSignIn = GoogleSignIn.instance;

    // Initialize with serverClientId (Web client ID from Google Cloud Console)
    // See Assumptions Log A1 for serverClientId sourcing
    await googleSignIn.initialize(
      serverClientId: _serverClientId, // Web OAuth client ID
    );

    final googleUser = await googleSignIn.authenticate();

    // Get auth tokens
    final googleAuth = await googleUser.authorizationClient
        .authorizationForScopes([]);

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth?.accessToken,
      idToken: googleAuth?.idToken,
    );

    final userCredential = await FirebaseAuth.instance
        .signInWithCredential(credential);

    return AuthSuccess(_mapUser(userCredential.user)!);
  } on Exception catch (e) {
    if (_isUserCancellation(e)) return const AuthCancelled();
    return AuthFailure(AuthError(e.toString()));
  }
}
```

### Pattern 5: Apple Sign-In with Nonce

**What:** Apple Sign-In with SHA-256 nonce for replay attack prevention.
**When to use:** AUTH-04 implementation.

```dart
// Source: FlutterFire social auth docs + sign_in_with_apple package

import 'package:crypto/crypto.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

@override
Future<AuthResult> signInWithApple() async {
  try {
    final rawNonce = generateNonce();
    final nonce = sha256.convert(utf8.encode(rawNonce)).toString();

    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
      nonce: nonce,
    );

    final oauthCredential = OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      rawNonce: rawNonce,
    );

    final userCredential = await FirebaseAuth.instance
        .signInWithCredential(oauthCredential);

    return AuthSuccess(_mapUser(userCredential.user)!);
  } on SignInWithAppleAuthorizationException catch (e) {
    if (e.code == AuthorizationErrorCode.canceled) {
      return const AuthCancelled();
    }
    return AuthFailure(AuthError(e.toString()));
  } on Exception catch (e) {
    return AuthFailure(AuthError(e.toString()));
  }
}
```

### Pattern 6: Injectable Module for Firebase Services

**What:** Register Firebase singleton instances via an injectable module.
**When to use:** FIRE-04, FIRE-05, FIRE-07 -- registering Firebase services that are accessed as singletons.

```dart
// Source: injectable pattern for third-party singletons

@module
abstract class FirebaseModule {
  @lazySingleton
  @Environment('prod')
  FirebaseAnalytics get analytics => FirebaseAnalytics.instance;

  @lazySingleton
  @Environment('prod')
  FirebasePerformance get performance => FirebasePerformance.instance;

  @lazySingleton
  @Environment('prod')
  FirebaseFirestore get firestore {
    final instance = FirebaseFirestore.instance;
    instance.settings = const Settings(
      persistenceEnabled: true,
    );
    return instance;
  }
}
```

### Anti-Patterns to Avoid

- **Calling Firebase APIs before `Firebase.initializeApp`:** Any `FirebaseAuth.instance` or `FirebaseFirestore.instance` access before init throws. The try/catch in `StartUpService` must complete before DI resolves any Firebase-dependent service.
- **Activating App Check after Firestore access:** App Check must be activated immediately after `Firebase.initializeApp`, before any DI registration that could trigger Firestore reads. Otherwise, Firestore uses an unattested token.
- **Mixing old google_sign_in API (`GoogleSignIn().signIn()`) with 7.x:** The 7.x API is singleton-based (`GoogleSignIn.instance`); old `new GoogleSignIn()` patterns will not work.
- **Hard-coding OAuth client IDs in Dart code:** Client IDs come from `firebase_options.dart` or are configured per-app post-bootstrap. Skeleton ships zero client IDs.
- **Registering Firebase services in dev environment:** `FirebaseAnalytics.instance` etc. must NOT be registered when Firebase is not initialized. The `@Environment('prod')` annotation prevents this.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Apple Sign-In nonce | Manual random string + SHA-256 | `generateNonce()` from firebase_auth + `crypto` SHA-256 | firebase_auth provides `generateNonce()` that produces cryptographically secure random strings |
| Google credential exchange | Manual HTTP token exchange | `GoogleAuthProvider.credential()` | Handles token format, expiry, refresh internally |
| Auth state change detection | Manual polling or custom streams | `FirebaseAuth.instance.authStateChanges()` | Handles token refresh, provider state, edge cases |
| Error code classification | String matching on exception messages | `FirebaseAuthException.code` switch | Stable string codes (`wrong-password`, `user-not-found`, etc.) |
| Firestore offline persistence | Custom SQLite cache | `Settings(persistenceEnabled: true)` | Built-in with conflict resolution, sync queue |

## Common Pitfalls

### Pitfall 1: google_sign_in 7.x serverClientId Requirement
**What goes wrong:** `GoogleSignInException(code: clientConfigurationError, serverClientId must be provided on Android)` at runtime.
**Why it happens:** `google_sign_in` 7.x requires explicit `serverClientId` (the Web OAuth client ID from Google Cloud Console). It is NOT read automatically from `google-services.json`.
**How to avoid:** Pass the Web client ID to `GoogleSignIn.instance.initialize(serverClientId: ...)`. This is the Web Client ID from Google Cloud Console > APIs & Services > Credentials, NOT the Android client ID.
**Warning signs:** `clientConfigurationError` exception on Android; works on iOS (different flow).

### Pitfall 2: Apple Sign-In First-Time Email/Name Loss
**What goes wrong:** Apple returns the user's email and full name only on the FIRST sign-in. Subsequent sign-ins return null for both fields.
**Why it happens:** Apple's privacy design -- they show the consent screen once.
**How to avoid:** Persist email and display name to Firestore/user profile on the first successful sign-in. The skeleton's `AuthUser` entity captures these, but downstream apps must store them.
**Warning signs:** `AuthUser.email` is null after second Apple sign-in.

### Pitfall 3: App Check Before Firebase Service Access
**What goes wrong:** Firestore/Auth calls succeed without attestation even though App Check is "activated."
**Why it happens:** App Check activation must happen before any Firebase service call. If DI registration triggers a Firestore read (lazy singleton initializer), the unattested token is cached.
**How to avoid:** In `StartUpService`, call `_configureAppCheck()` immediately after `Firebase.initializeApp()`, before `configureDependenciesApp()`.
**Warning signs:** App Check dashboard shows 0 verified requests even in release builds.

### Pitfall 4: Firebase Not Initialized Crash
**What goes wrong:** `FirebaseException: Firebase has not been correctly initialized` crash on launch.
**Why it happens:** `DefaultFirebaseOptions.currentPlatform` throws when `firebase_options.dart` doesn't exist (fresh clone without `flutterfire configure`).
**How to avoid:** The try/catch in `StartUpService` (D-01) catches this and falls back to dev environment. The import of `firebase_options.dart` itself must exist -- use a stub file that throws, or handle the import error.
**Warning signs:** Crash before any UI renders; stacktrace points to `Firebase.initializeApp`.

### Pitfall 5: FlutterFire BoM Version Mismatch
**What goes wrong:** iOS pod resolution failure or Android `Duplicate class` exceptions.
**Why it happens:** Mixing Firebase package versions from different BoM releases.
**How to avoid:** Pin all 7 Firebase packages to the BoM 4.12.0 matrix as a single commit. Never upgrade one without the others.
**Warning signs:** `CocoaPods could not find compatible versions` during `pod install`.

### Pitfall 6: Existing startup_service.dart Uses deviceCheck, Not appAttest
**What goes wrong:** The current stub has `AppleProvider.deviceCheck` but D-09 requires `AppleProvider.appAttest`.
**Why it happens:** The stub was written before the CONTEXT discussion.
**How to avoid:** Replace `deviceCheck` with `appAttest` during the App Check rewrite. Also change the conditional from `kReleaseMode ? realProvider : debugProvider` to `if (kReleaseMode) activate(...)` per D-10 (skip entirely in dev).
**Warning signs:** Code review catches the wrong provider string.

### Pitfall 7: firebase_options.dart Import Unavailable on Fresh Clone
**What goes wrong:** The file `lib/firebase_options.dart` doesn't exist until `flutterfire configure` is run. Importing it statically causes a compile error on fresh clone.
**Why it happens:** The skeleton is Firebase-sterile by design.
**How to avoid:** Either (a) ship a stub `firebase_options.dart` that throws `UnimplementedError` (which the try/catch in startup catches), or (b) use conditional imports. Option (a) is simpler and recommended.
**Warning signs:** `flutter run` fails with "Target of URI doesn't exist: firebase_options.dart".

## Code Examples

### Crashlytics Error Handler Trio (FIRE-03)

```dart
// Source: STACK.md + CONTEXT.md D-07, D-08

import 'dart:isolate';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

static void _configureCrashlytics() {
  // D-07: Disable collection in debug
  FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(kReleaseMode);

  // Handler 1: Flutter framework errors
  FlutterError.onError =
      FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Handler 2: Async Dart errors not caught by Flutter
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Handler 3: Errors in spawned isolates (D-08)
  Isolate.current.addErrorListener(
    RawReceivePort((dynamic pair) async {
      final errorAndStack = pair as List<dynamic>;
      await FirebaseCrashlytics.instance.recordError(
        errorAndStack[0],
        StackTrace.fromString(errorAndStack[1] as String),
        fatal: true,
      );
    }).sendPort,
  );
}
```

### App Check Release-Only Activation (FIRE-06)

```dart
// Source: CONTEXT.md D-09, D-10

static Future<void> _configureAppCheck() async {
  if (!kReleaseMode) return; // D-10: Skip entirely in dev

  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.playIntegrity,
    appleProvider: AppleProvider.appAttest, // D-09: appAttest, not deviceCheck
  );
}
```

### Email Sign-In (AUTH-02)

```dart
// Source: firebase_auth API

@override
Future<AuthResult> signInWithEmail({
  required String email,
  required String password,
}) async {
  try {
    final credential = await FirebaseAuth.instance
        .signInWithEmailAndPassword(email: email, password: password);
    return AuthSuccess(_mapUser(credential.user)!);
  } on FirebaseAuthException catch (e) {
    return AuthFailure(AuthError(_mapAuthErrorCode(e.code)));
  } on Exception catch (e) {
    return AuthFailure(AuthError(e.toString()));
  }
}

/// Maps Firebase error codes to human-readable messages.
String _mapAuthErrorCode(String code) => switch (code) {
  'user-not-found' => 'No account found with this email.',
  'wrong-password' => 'Incorrect password.',
  'invalid-email' => 'Invalid email address.',
  'user-disabled' => 'This account has been disabled.',
  'email-already-in-use' => 'An account already exists with this email.',
  'weak-password' => 'Password is too weak.',
  'too-many-requests' => 'Too many attempts. Try again later.',
  _ => 'Authentication error: $code',
};
```

### Sign Out All Providers (AUTH-06)

```dart
// Source: firebase_auth + google_sign_in APIs

@override
Future<void> signOut() async {
  await GoogleSignIn.instance.signOut();
  await FirebaseAuth.instance.signOut();
  // authStateChanges will emit null via the stream subscription
}
```

### Stub firebase_options.dart (for fresh clone compatibility)

```dart
// lib/firebase_options.dart
// GENERATED BY FlutterFire CLI -- overwritten by `flutterfire configure`.
// This stub allows `flutter run` without Firebase configured.

import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform =>
      throw UnsupportedError(
        'No Firebase configuration found. '
        'Run `flutterfire configure` to generate firebase_options.dart.',
      );
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `GoogleSignIn().signIn()` | `GoogleSignIn.instance.initialize()` + `.authenticate()` | google_sign_in 7.0.0 (2025) | Singleton pattern; serverClientId required on Android |
| `AppleProvider.deviceCheck` | `AppleProvider.appAttest` | Firebase App Check evolution | Stronger attestation; iOS 14+ required (skeleton floor is 15) |
| Manual Firebase init per platform | `flutterfire configure` CLI | FlutterFire CLI 1.x | Generates `firebase_options.dart` with all platform configs |
| `firebase_core` 3.x | `firebase_core` 4.7.0 (BoM 4.12.0) | 2026-04-13 | Major version; all Firebase packages must match |
| Mix-and-match Firebase versions | BoM-locked version matrix | FlutterFire BoM concept | All packages upgraded as a set |

**Deprecated/outdated:**
- `GoogleSignIn().signIn()` -- replaced by singleton pattern in 7.x
- `BlocOverrides` -- removed in flutter_bloc 9 (already handled in Phase 3)
- `FirebaseCrashlytics.instance.recordFlutterError` -- renamed to `recordFlutterFatalError` in 5.x

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `serverClientId` (Web OAuth client ID) can be sourced from `DefaultFirebaseOptions` at runtime via the `androidClientId` field | Standard Stack / AUTH-03 | HIGH -- `FirebaseOptions` has `androidClientId` and `iosClientId` but NO `webClientId` field. Research confirms these are OAuth client IDs, but the Web client ID may NOT be automatically populated by `flutterfire configure`. The implementation may need to accept `serverClientId` as a constructor parameter or read it from a separate config. D-05 in CONTEXT.md assumes zero manual config, which may not hold. |
| A2 | `google_sign_in` 7.x `authenticate()` returns an object with `authorizationClient` that can produce `accessToken` and `idToken` for Firebase credential | Code Examples / Pattern 4 | MEDIUM -- The exact token retrieval API in 7.x may differ from the documented pattern. The FlutterFire social auth docs still show the pre-7.x pattern (`googleUser.authentication`). Implementation should verify the actual 7.x token flow. |
| A3 | `generateNonce()` is exported from `firebase_auth` package | Pattern 5 | LOW -- If not, generate a cryptographically random string manually (trivial). |
| A4 | `firebase_crashlytics` 5.2.0 `recordFlutterFatalError` is a static getter usable as `FlutterError.onError` callback | Code Examples | LOW -- Pattern unchanged since 4.x; confirmed in existing stub. |
| A5 | `Isolate.current.addErrorListener` with `RawReceivePort` works in Flutter's main isolate | Code Examples / FIRE-03 | LOW -- Documented in STACK.md and multiple Flutter error handling guides. |

## Open Questions

1. **serverClientId sourcing for Google Sign-In on Android**
   - What we know: `FirebaseOptions` has `androidClientId` and `iosClientId` but NO `webClientId`. `google_sign_in` 7.x requires the Web OAuth client ID as `serverClientId`.
   - What's unclear: Whether `flutterfire configure` populates `androidClientId` with the Web client ID (unlikely given the name), or if the Web client ID must be obtained separately.
   - Recommendation: Ship `FirebaseAuthService` with a `serverClientId` parameter. The README post-bootstrap checklist documents where to find it (Google Cloud Console > APIs & Services > Credentials > Web client). This is one manual step per project, not per developer. If D-05's "zero manual config" assumption proves correct at implementation time, the parameter can be sourced from `DefaultFirebaseOptions`.

2. **google_sign_in 7.x token retrieval exact API**
   - What we know: 7.x uses `authenticate()` returning `GoogleSignInAccount`, which has an `authorizationClient`.
   - What's unclear: The exact method chain to get `accessToken` and `idToken` for `GoogleAuthProvider.credential()`.
   - Recommendation: At implementation time, check the `GoogleSignInAccount` class API directly. The FlutterFire docs still show the pre-7.x pattern, so the implementer must adapt.

3. **AuthError granularity**
   - What we know: Phase 3 shipped `AuthError extends AppFailure` as a single type with message string. CONTEXT.md leaves granular subtypes as Claude's discretion.
   - Recommendation: Keep `AuthError` as a single type with descriptive message strings from `_mapAuthErrorCode()`. Granular subtypes add complexity without clear consumer benefit in a skeleton. If a downstream app needs `AuthInvalidCredentials` vs `AuthUserNotFound`, they subclass then.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | flutter_test + bloc_test 10.0.0 + mocktail |
| Config file | none -- uses flutter_test defaults |
| Quick run command | `flutter test test/core/auth/` |
| Full suite command | `flutter test` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| FIRE-02 | Firebase init succeeds with config, falls back without | unit (mocked) | `flutter test test/startup_service_test.dart -x` | No -- Wave 0 |
| FIRE-03 | Crashlytics handlers installed in prod env | unit | `flutter test test/startup_service_test.dart -x` | No -- Wave 0 |
| AUTH-01 | authStateChanges emits mapped AuthUser | unit | `flutter test test/core/auth/firebase_auth_service_test.dart -x` | No -- Wave 0 |
| AUTH-02 | Email sign-in returns AuthSuccess/AuthFailure | unit | `flutter test test/core/auth/firebase_auth_service_test.dart -x` | No -- Wave 0 |
| AUTH-03 | Google sign-in completes credential exchange | unit (mocked) | `flutter test test/core/auth/firebase_auth_service_test.dart -x` | No -- Wave 0 |
| AUTH-04 | Apple sign-in with nonce returns AuthSuccess | unit (mocked) | `flutter test test/core/auth/firebase_auth_service_test.dart -x` | No -- Wave 0 |
| AUTH-06 | signOut clears all providers + emits null | unit | `flutter test test/core/auth/firebase_auth_service_test.dart -x` | No -- Wave 0 |
| FIRE-01 | Version pins match BoM 4.12.0 | manual | Verify pubspec.yaml | N/A |
| FIRE-04 | Analytics registered in prod DI | unit | `flutter test test/core/firebase/firebase_module_test.dart -x` | No -- Wave 0 |
| FIRE-06 | App Check skipped in debug, activated in release | unit | `flutter test test/startup_service_test.dart -x` | No -- Wave 0 |
| AUTH-05 | README documents setup steps | manual | Visual review | N/A |

### Sampling Rate
- **Per task commit:** `flutter test test/core/auth/`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/core/auth/firebase_auth_service_test.dart` -- covers AUTH-01 through AUTH-06
- [ ] `test/startup_service_test.dart` -- covers FIRE-02, FIRE-03, FIRE-06
- [ ] `test/core/firebase/firebase_module_test.dart` -- covers FIRE-04, FIRE-05, FIRE-07
- [ ] `mocktail` already in dev_dependencies (added Phase 2)
- [ ] Note: Testing Firebase requires mocking `FirebaseAuth.instance`, `FirebaseCrashlytics.instance`, etc. Consider whether these tests are practical in the skeleton scope or if they are better suited to Phase 6's test infrastructure.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Firebase Auth + google_sign_in + sign_in_with_apple |
| V3 Session Management | yes | Firebase Auth token management (automatic) |
| V4 Access Control | yes | AuthGuard on router (existing); App Check for API access |
| V5 Input Validation | yes | Email validation via Firebase (server-side); client-side is per-app |
| V6 Cryptography | yes | Apple Sign-In nonce via `crypto` SHA-256; Firebase handles token crypto |

### Known Threat Patterns for FlutterFire Auth

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Replay attack on Apple Sign-In | Spoofing | SHA-256 nonce in Apple credential request |
| Missing SHA-1 fingerprint allows MITM on Google Sign-In | Spoofing | Register all keystores' SHA-1 in Firebase Console |
| App Check bypass in debug leaks to prod | Elevation of Privilege | `kReleaseMode` gate; enforcement in Firebase Console |
| First-time Apple email not persisted | Information Disclosure | Persist email/name on first sign-in |
| Firebase config files committed with secrets | Information Disclosure | .gitignore `google-services.json` and `GoogleService-Info.plist` for prod |
| Debug Crashlytics collection leaks dev data | Information Disclosure | `setCrashlyticsCollectionEnabled(kReleaseMode)` |

## Sources

### Primary (HIGH confidence)
- [pub.dev/firebase_core](https://pub.dev/packages/firebase_core) - Version 4.7.0 confirmed (BoM 4.12.0)
- [pub.dev/firebase_auth](https://pub.dev/packages/firebase_auth) - Version 6.4.0 confirmed
- [pub.dev/cloud_firestore](https://pub.dev/packages/cloud_firestore) - Version 6.3.0 confirmed
- [pub.dev/firebase_crashlytics](https://pub.dev/packages/firebase_crashlytics) - Version 5.2.0 confirmed
- [pub.dev/firebase_analytics](https://pub.dev/packages/firebase_analytics) - Version 12.3.0 confirmed
- [pub.dev/firebase_performance](https://pub.dev/packages/firebase_performance) - Version 0.11.3 confirmed
- [pub.dev/firebase_app_check](https://pub.dev/packages/firebase_app_check) - Version 0.4.3 confirmed
- [pub.dev/google_sign_in](https://pub.dev/packages/google_sign_in) - Version 7.2.0 confirmed; singleton API
- [pub.dev/sign_in_with_apple](https://pub.dev/packages/sign_in_with_apple) - Version 7.0.1 confirmed
- [pub.dev/firebase_core_platform_interface](https://pub.dev/documentation/firebase_core_platform_interface/latest/firebase_core_platform_interface/FirebaseOptions-class.html) - FirebaseOptions field list (no webClientId)
- [FlutterFire social auth docs](https://firebase.flutter.dev/docs/auth/social/) - Google + Apple credential patterns
- [flutter/flutter#172073](https://github.com/flutter/flutter/issues/172073) - serverClientId requirement on Android

### Secondary (MEDIUM confidence)
- [.planning/research/STACK.md](../../research/STACK.md) - FlutterFire BoM matrix, Crashlytics wiring, google_sign_in 7.x notes
- [.planning/research/PITFALLS.md](../../research/PITFALLS.md) - Firebase-flavor coupling, App Check debug config, Apple Sign-In capability

### Tertiary (LOW confidence)
- google_sign_in 7.x exact token retrieval chain via `authorizationClient` -- docs show old API pattern

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All package versions verified on pub.dev within the last week
- Architecture: HIGH - DI environment switching verified in existing codegen; startup pattern extends existing stub
- Pitfalls: HIGH - SHA-1, App Check ordering, Apple first-sign-in data loss all documented in multiple sources
- google_sign_in 7.x integration: MEDIUM - Singleton API confirmed but exact token retrieval for Firebase credential needs implementation-time verification

**Research date:** 2026-04-17
**Valid until:** 2026-05-17 (30 days -- Firebase packages are stable post-BoM release)
