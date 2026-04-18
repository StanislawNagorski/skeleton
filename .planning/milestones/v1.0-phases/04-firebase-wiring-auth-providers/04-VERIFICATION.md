---
phase: 04-firebase-wiring-auth-providers
verified: 2026-04-17T18:55:00Z
status: human_needed
score: 5/5
overrides_applied: 0
human_verification:
  - test: "Run `flutterfire configure` against a throwaway Firebase project, then `flutter run` -- Firebase.initializeApp should complete cleanly"
    expected: "App starts, logs show prod environment, Crashlytics and App Check hooks activate"
    why_human: "Requires a real Firebase project and device/emulator to verify end-to-end Firebase initialization"
  - test: "Force a Dart error in release mode and check the Crashlytics console"
    expected: "Error surfaces in Crashlytics dashboard within minutes"
    why_human: "Requires a release build deployed to a device with Firebase configured"
  - test: "Exercise signInWithEmail, signUpWithEmail, signInWithGoogle, signInWithApple, signOut, sendPasswordReset against a real Firebase project"
    expected: "All auth flows complete, authStateChanges emits AuthUser on sign-in and null on sign-out"
    why_human: "Requires real Firebase Auth project with providers enabled, device with Google/Apple accounts"
  - test: "Build release APK and verify App Check activates with Play Integrity; build release iOS and verify App Attest activates"
    expected: "App Check attestation completes, no debug-token prompts in dev builds"
    why_human: "Requires release builds on real devices with Play Console / App Store enrollment"
  - test: "Verify Android and iOS builds launch without pod/gradle errors after flutterfire configure"
    expected: "Both platforms build and launch cleanly"
    why_human: "Requires full native build chain on macOS with Xcode + Android SDK"
---

# Phase 4: Firebase Wiring + Auth Providers Verification Report

**Phase Goal:** End-to-end FlutterFire BoM 4.12.0 wiring (Core, Auth, Firestore, Crashlytics, Analytics, Performance, App Check) with native Email/Google/Apple providers functioning against a single Firebase project
**Verified:** 2026-04-17T18:55:00Z
**Status:** human_needed
**Re-verification:** No -- initial verification

## Goal Achievement

### Observable Truths

Truths derived from ROADMAP.md Success Criteria merged with PLAN frontmatter must-haves.

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | After `flutterfire configure`, app starts with `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` completing ahead of DI registration | VERIFIED (code) | `lib/startup_service.dart:30-31` calls `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` before `configureDependenciesApp(environment: environment)` at line 46. `lib/main.dart:11` calls `StartUpService.initServices()` before any DI access. |
| 2 | Crashlytics error handler trio installed: `FlutterError.onError`, `PlatformDispatcher.instance.onError`, and isolate error listener; collection disabled in debug | VERIFIED (code) | `lib/startup_service.dart:65-66` (FlutterError.onError), `:70-74` (PlatformDispatcher.instance.onError), `:79-90` (Isolate.current.addErrorListener). `setCrashlyticsCollectionEnabled(kReleaseMode)` at line 62. |
| 3 | AuthService methods (signInWithEmail, signUpWithEmail, signInWithGoogle, signInWithApple, signOut, sendPasswordReset) each implement a real Firebase Auth flow; authStateChanges emits AuthUser/null | VERIFIED (code) | `lib/core/auth/firebase_auth_service.dart` (249 lines) implements all 8 contract methods: `signInWithEmailAndPassword` (L56-57), `createUserWithEmailAndPassword` (L71-72), Google 7.x `initialize()+authenticate()` flow (L102-116), Apple SHA-256 nonce flow (L138-155), `signOut` (L172-174), `sendPasswordResetEmail` (L183). `authStateChanges` wired via `FirebaseAuth.instance.authStateChanges().map(_mapUser).listen` (L29-32). |
| 4 | App Check activates only in release builds; dev builds skip entirely with no debug-token friction | VERIFIED (code) | `lib/startup_service.dart:99` -- `if (!kReleaseMode) return;` skips App Check in non-release. Lines 101-105 activate with `AppleAppAttestProvider()` and `AndroidPlayIntegrityProvider()`. |
| 5 | FirebaseAnalytics and FirebasePerformance registered in DI, cloud_firestore has offline persistence enabled | VERIFIED (code) | `lib/core/firebase/firebase_module.dart` registers all three as `@lazySingleton` + `@Environment(Environment.prod)`. Firestore getter sets `persistenceEnabled: true` (L38-41). `injection.config.dart` confirms `registerFor: {_prod}` on lines 58-69 for all three services. |

**Score:** 5/5 truths verified (code-level)

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `pubspec.yaml` | BoM 4.12.0 version pins for all 7 Firebase packages + auth deps | VERIFIED | `firebase_core: ^4.7.0`, `firebase_auth: ^6.4.0`, `cloud_firestore: ^6.3.0`, `firebase_crashlytics: ^5.2.0`, `firebase_analytics: ^12.3.0`, `firebase_performance: ^0.11.3`, `firebase_app_check: ^0.4.3`, `google_sign_in: ^7.2.0`, `sign_in_with_apple: ^7.0.1`, `crypto: ^3.0.6` -- all present |
| `lib/firebase_options.dart` | Stub that throws UnsupportedError for fresh-clone compat | VERIFIED | 18 lines, `DefaultFirebaseOptions.currentPlatform` throws `UnsupportedError` |
| `lib/core/injectable/injection.dart` | Environment-parameterized DI initialization | VERIFIED | `configureDependenciesApp({String environment = 'dev'})` forwards to `$initGetIt(getIt, environment: environment)` |
| `lib/core/auth/fake_auth_service.dart` | Dev-environment-annotated fake auth service | VERIFIED | `@LazySingleton(as: AuthService, env: [Environment.dev])` at line 14 |
| `lib/startup_service.dart` | Firebase init with graceful fallback, Crashlytics hooks, App Check activation | VERIFIED | 107 lines, try/catch around Firebase.initializeApp, catches Object (not Exception) for UnsupportedError, three Crashlytics handlers, release-only App Check |
| `lib/core/firebase/firebase_module.dart` | Injectable module for Analytics, Performance, and Firestore DI registration | VERIFIED | 42 lines, `@module` abstract class with three `@lazySingleton` + `@Environment(Environment.prod)` getters |
| `lib/core/auth/firebase_auth_service.dart` | Production AuthService implementation backed by Firebase Auth | VERIFIED | 249 lines, `@LazySingleton(as: AuthService, env: [Environment.prod])`, implements all 8 AuthService methods, `@disposeMethod` on dispose |
| `lib/core/injectable/injection.config.dart` | Generated DI with environment-conditional registrations | VERIFIED | Shows `FakeAuthService` with `registerFor: {_dev}` and `FirebaseAuthService` with `registerFor: {_prod}` + dispose. `_$FirebaseModule` class generated. |
| `README.md` | Post-bootstrap Firebase + auth provider setup documentation | VERIFIED | `## Firebase Setup` section at line 170 with 7 subsections: Prerequisites, Generate Firebase Options, Google Sign-In (SHA-1 + serverClientId + reversed client ID), Apple Sign-In (Xcode capability + Services ID), App Check, Crashlytics, Dev Mode |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|-----|--------|---------|
| `injection.dart` | `injection.config.dart` | `$initGetIt(getIt, environment: environment)` | WIRED | Line 24 passes environment parameter |
| `startup_service.dart` | `injection.dart` | `configureDependenciesApp(environment: environment)` | WIRED | Line 46 calls with environment derived from Firebase init result |
| `startup_service.dart` | `firebase_options.dart` | `DefaultFirebaseOptions.currentPlatform` | WIRED | Line 31 uses `DefaultFirebaseOptions.currentPlatform` in Firebase.initializeApp options |
| `firebase_module.dart` | `injection.config.dart` | Injectable codegen picks up @module | WIRED | `_$FirebaseModule` class generated at line 92 of injection.config.dart |
| `firebase_auth_service.dart` | `auth_service.dart` | `implements AuthService` | WIRED | Line 27: `class FirebaseAuthService implements AuthService` |
| `firebase_auth_service.dart` | `auth_result.dart` | Returns AuthSuccess/AuthFailure/AuthCancelled | WIRED | All method returns use sealed AuthResult subtypes |
| `firebase_auth_service.dart` | `auth_user.dart` | `_mapUser` converts firebase_auth User to AuthUser | WIRED | `_mapUser` at lines 202-210 maps User fields to AuthUser constructor |
| `firebase_auth_service.dart` | `failures.dart` | `AuthError` wraps FirebaseAuthException messages | WIRED | `AuthError(_mapAuthErrorCode(e.code))` used in all catch clauses |
| `README.md` | `firebase_options.dart` | Documents flutterfire configure as stub replacement | WIRED | Line 186-191: `flutterfire configure --project=YOUR_PROJECT_ID` documented |

### Data-Flow Trace (Level 4)

Not applicable for this phase. Artifacts are infrastructure services (auth, Firebase init, DI modules) rather than components rendering dynamic data. Data flows through these services at runtime, verified via code-level contract analysis above.

### Behavioral Spot-Checks

Step 7b: SKIPPED (no runnable entry points -- Firebase services require a configured Firebase project and device/emulator to execute).

### Requirements Coverage

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| FIRE-01 | 04-01 | FlutterFire BoM 4.12.0 matrix pinned in pubspec | SATISFIED | All 7 Firebase packages at BoM 4.12.0 versions in pubspec.yaml |
| FIRE-02 | 04-02 | `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` called before runApp | SATISFIED | startup_service.dart:30-31 called from main.dart:11 before runApp. Requirement says "each main_*.dart" but single main.dart delegates to StartUpService -- intent met. |
| FIRE-03 | 04-02 | Global error hook sends fatal Dart errors to Crashlytics; collection disabled in debug | SATISFIED | All three handlers installed: FlutterError.onError (L65-66), PlatformDispatcher (L70-74), Isolate (L79-90). `setCrashlyticsCollectionEnabled(kReleaseMode)` at L62. |
| FIRE-04 | 04-02 | `FirebaseAnalytics.instance` exposed as injected service | SATISFIED | firebase_module.dart L19-21 registers as prod-only lazySingleton |
| FIRE-05 | 04-02 | `FirebasePerformance.instance` automatic tracing enabled | SATISFIED | firebase_module.dart L28-30 registers as prod-only lazySingleton |
| FIRE-06 | 04-02 | App Check activated only in kReleaseMode with playIntegrity/appAttest | SATISFIED | startup_service.dart L99 `if (!kReleaseMode) return;`, L103-104 typed providers |
| FIRE-07 | 04-02 | cloud_firestore with offline persistence enabled | SATISFIED | firebase_module.dart L37-41 sets `persistenceEnabled: true` |
| AUTH-01 | 04-03 | firebase_auth wired; AuthServiceImpl subscribes to authStateChanges | SATISFIED | firebase_auth_service.dart L29-32 subscribes and maps stream |
| AUTH-02 | 04-03 | Email + Password provider via signInWithEmail/signUpWithEmail | SATISFIED | firebase_auth_service.dart L51-79 |
| AUTH-03 | 04-03 | Google Sign-In wired end-to-end | SATISFIED | firebase_auth_service.dart L95-127 with google_sign_in 7.x singleton API |
| AUTH-04 | 04-03 | Apple Sign-In wired with SHA-256 nonce | SATISFIED | firebase_auth_service.dart L136-166 with _generateNonce + sha256.convert |
| AUTH-05 | 04-04 | README documents SHA-1 workflow, Apple capability, reversed client ID | SATISFIED | README.md lines 170-274 cover all AUTH-05 checklist items |
| AUTH-06 | 04-03 | signOut signs out all providers, stream emits null | SATISFIED | firebase_auth_service.dart L172-174 signs out Google + Firebase |

All 13 requirements (FIRE-01 through FIRE-07, AUTH-01 through AUTH-06) are **SATISFIED**.

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| None | - | - | - | No TODOs, FIXMEs, placeholders, empty returns, or hardcoded empty data found in any phase 4 artifact |

### Human Verification Required

All 5 truths are verified at the code level -- the implementations exist, are substantive, and are wired. However, the ROADMAP success criteria explicitly describe runtime behaviors that require a real Firebase project:

### 1. Firebase End-to-End Init

**Test:** Run `flutterfire configure --project=YOUR_PROJECT_ID` against a throwaway Firebase project, then `flutter run` on both iOS simulator and Android emulator.
**Expected:** App starts in prod mode, logs show `environment = 'prod'`, no Firebase initialization errors.
**Why human:** Requires a real Firebase project, FlutterFire CLI, and device/emulator.

### 2. Crashlytics Error Surfacing

**Test:** In release mode, force a Dart error (e.g., throw in a button handler). Check Crashlytics console.
**Expected:** Error appears in the Crashlytics dashboard within minutes.
**Why human:** Requires a release build deployed to a device with Firebase configured and Crashlytics console access.

### 3. Auth Provider End-to-End Flows

**Test:** Exercise all six auth methods (signInWithEmail, signUpWithEmail, signInWithGoogle, signInWithApple, signOut, sendPasswordReset) against a real Firebase project.
**Expected:** All flows complete, authStateChanges stream emits AuthUser on sign-in and null on sign-out. Google and Apple sign-in dialogs appear and complete the full OAuth flow.
**Why human:** Requires Firebase Auth project with Email, Google, and Apple providers enabled. Google requires SHA-1 registration. Apple requires Xcode capability and real iOS device.

### 4. App Check Release Activation

**Test:** Build a release APK/IPA, launch on device, verify App Check attestation completes.
**Expected:** App Check activates silently in release. Dev builds show no App Check activity.
**Why human:** Requires release build infrastructure, Play Console enrollment (Android), App Store provisioning (iOS).

### 5. Cross-Platform Build Verification

**Test:** Run `flutter build apk` and `flutter build ios` after `flutterfire configure`.
**Expected:** Both platforms build without pod/gradle version conflict errors.
**Why human:** Requires full native build chain on macOS with Xcode 16+ and Android SDK.

### Gaps Summary

No code-level gaps found. All 13 requirements are implemented and wired. All artifacts exist, are substantive (no stubs or placeholders), and are connected via verified key links. The DI generated code confirms environment-conditional registration for both FakeAuthService (dev) and FirebaseAuthService (prod).

The phase status is `human_needed` because the ROADMAP success criteria describe runtime behaviors (real Firebase init, Crashlytics dashboard verification, live auth flows, release-build App Check) that cannot be verified through static code analysis alone. The code-level verification is complete and passes all checks.

---

_Verified: 2026-04-17T18:55:00Z_
_Verifier: Claude (gsd-verifier)_
