# Roadmap: Skeleton — Flutter Mobile App Starter (2026 Refresh)

**Milestone:** 2026 Refresh
**Created:** 2026-04-16
**Granularity:** standard
**Mode:** yolo + parallelization

## Overview

Rebase the Skeleton onto Flutter 3.41.5's native scaffolding, then progressively re-apply every production-grade pattern downstream apps inherit: strict lints + sealed `Result`/`Failure`, Drift-backed local persistence, the three structural package upgrades (`flutter_bloc` 9, `auto_route` 11, and the `AuthService` contract), full Firebase + Auth provider wiring (Email, Google, Apple, App Check release-only), a RIVE splash + onboarding + coach-mark trio, then the bootstrap script + i18n cleanup + reference tests, and finally a rewritten README + repeatable-rebase runbook. After this milestone ships, `git clone → bootstrap → flutterfire configure → flutter run` lands a Firebase-connected, Clean-Architected iOS + Android app in under 30 minutes.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Native Rebase** — Regenerate `android/` + `ios/` from Flutter 3.41.5 `flutter create`, trim to mobile-only, preserve `lib/`, unblock everything else
- [ ] **Phase 2: Lints, Error Handling, Local Data Layer** — Adopt `very_good_analysis`, replace `dartz` with sealed `Result`/`Failure`, swap ObjectBox → Drift, port the counter example
- [ ] **Phase 3: Package Upgrades + Auth Contract** — Bump `flutter_bloc` 8→9 and `auto_route` 9→11, lock the `AuthService` abstract contract
- [ ] **Phase 4: Firebase Wiring + Auth Providers** — Full FlutterFire BoM 4.12.0 stack, native Email/Google/Apple sign-in, App Check release-only, Crashlytics error hooks
- [x] **Phase 5: UX Patterns (Onboarding + RIVE Splash + Coach Marks)** — `RiveNative.init()`, RIVE 0.14 animated splash, 3-slide onboarding + guard, `CoachMarkService` + FAB demo
- [x] **Phase 6: Bootstrap + i18n Cleanup + Tests** — `tool/bootstrap.dart` rename script, PL→EN ARB template switch, counter cubit + repository reference tests (completed 2026-04-18)
- [ ] **Phase 7: Documentation** — README rewrite, rebase runbook, upgrade playbook

## Phase Details

### Phase 1: Native Rebase
**Goal**: Regenerated Android + iOS native scaffolding on Flutter 3.41.5's `flutter create` output, with `lib/` preserved verbatim and mobile-only platform surface
**Depends on**: Nothing (first phase)
**Requirements**: INFRA-01, INFRA-02, INFRA-03, INFRA-04
**Success Criteria** (what must be TRUE):
  1. `fvm flutter --version` reports 3.41.5 and `.fvmrc` is pinned to 3.41.5
  2. `fvm flutter run` launches the app on an iOS simulator and an Android emulator from the regenerated scaffolding without errors
  3. `android/`, `ios/` exist; `web/`, `macos/`, `linux/`, `windows/` directories and their plugin registrations are gone; `flutter devices` lists only mobile targets
  4. `android/app/build.gradle` declares a distinct release `signingConfig` (no longer reuses debug keystore) with a gitignored `key.properties` template documented
  5. `pubspec.lock` and `.flutter-plugins-dependencies` are regenerated against Flutter 3.41.5 with AGP 8.11.1 / Kotlin 2.2.20 / Gradle 8.14 / Java 17 / iOS Podfile floor 15 verified in the output
**Plans:** 2 plans
Plans:
- [x] 01-01-PLAN.md — Core rebase: FVM bump, flutter create scaffold, swap native dirs, delete non-mobile platforms, update pubspec environment, regenerate lockfiles
- [x] 01-02-PLAN.md — Release signing scaffolding, README update, rebase manifest, final verification checkpoint

### Phase 2: Lints, Error Handling, Local Data Layer
**Goal**: Strict lints enforced, sealed `Result<T>` + `Failure` hierarchy replaces `dartz`, Drift (with `SharedPreferencesAsync` + `flutter_secure_storage`) fully replaces ObjectBox, counter example ported end-to-end
**Depends on**: Phase 1
**Requirements**: TOOL-03, CORE-01, CORE-02, CORE-06, DATA-01, DATA-02, DATA-03, DATA-04, DATA-05
**Success Criteria** (what must be TRUE):
  1. `fvm flutter analyze` exits 0 under `very_good_analysis` with generated files excluded and errors-not-warnings on key rules
  2. No `dartz` imports remain in `lib/`; every repository/service returns `Result<T>` and every cubit consumes results via exhaustive `switch` pattern matching (no `.fold()` call sites)
  3. ObjectBox is entirely removed (no `objectbox*` dependencies, no `objectbox.g.dart` / `objectbox-model.json`, no `Pods/ObjectBox`); `AppDatabase` (Drift) is registered as a `@lazySingleton` in the DI graph
  4. The counter page loads, increments, and decrements via a Drift-backed reactive stream with the same `repository → service → cubit → UI` flow as the ObjectBox version
  5. `SharedPreferencesAsync` + `flutter_secure_storage` are registered in DI and `http` / `uuid` / `collection` are gone from `pubspec.yaml`
**Plans:** 2 plans
Plans:
- [x] 02-01-PLAN.md — Lints + sealed Result/AppFailure abstractions + pubspec dependency overhaul
- [x] 02-02-PLAN.md — ObjectBox removal, Drift integration, dartz->Result migration, counter port, preferences + secure storage wrappers

### Phase 3: Package Upgrades + Auth Contract
**Goal**: `flutter_bloc` 9 and `auto_route` 11 compile cleanly, and the abstract `AuthService` contract (+ sealed `AuthResult`) is locked so every downstream consumer can build against it
**Depends on**: Phase 2
**Requirements**: CORE-03, CORE-04, CORE-05
**Success Criteria** (what must be TRUE):
  1. `pubspec.yaml` pins `flutter_bloc ^9.1.1`, `auto_route ^11.1.0`, `auto_route_generator ^10.5.0`, and the project compiles + tests pass
  2. `AppRouter` extends `RootStackRouter` directly (no `$AppRouter`), global guards are wired via the router-level `guards` override, and `pushNamed`/`pop` → `pushPath`/`maybePop` migrations are applied
  3. `lib/core/auth/auth_service.dart` defines the abstract `AuthService` with `Stream<AuthUser?> authStateChanges`, `AuthUser? currentUser`, the six sign-in / sign-out methods, and sealed `AuthResult` (`AuthSuccess` / `AuthFailure` / `AuthCancelled`)
  4. `AuthUser` is a pure Dart entity that imports zero `firebase_auth` symbols
  5. `flutter analyze` + `flutter test` both pass against the new package majors
**Plans:** 2 plans
Plans:
- [x] 03-01-PLAN.md — flutter_bloc 9 bump, AuthService contract (abstract + sealed AuthResult + AuthUser entity + FakeAuthService + AuthError)
- [x] 03-02-PLAN.md — auto_route 11 guard wiring (AuthGuard, LoginRoute placeholder, reevaluateListenable, router/app/main updates)

### Phase 4: Firebase Wiring + Auth Providers
**Goal**: End-to-end FlutterFire BoM 4.12.0 wiring (Core, Auth, Firestore, Crashlytics, Analytics, Performance, App Check) with native Email/Google/Apple providers functioning against a single Firebase project
**Depends on**: Phase 3
**Requirements**: FIRE-01, FIRE-02, FIRE-03, FIRE-04, FIRE-05, FIRE-06, FIRE-07, AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05, AUTH-06
**Success Criteria** (what must be TRUE):
  1. After running `flutterfire configure` against a throwaway `skeleton` project, the app starts up with `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` completing cleanly ahead of DI registration
  2. A forced Dart error in release mode surfaces in the Crashlytics console within minutes, confirming `FlutterError.onError`, `PlatformDispatcher.instance.onError`, and the isolate error listener are all installed
  3. `AuthService.signInWithEmail`, `.registerWithEmail`, `.signInWithGoogle`, `.signInWithApple`, `.signOut`, and `.sendPasswordReset` each complete a real auth flow against Firebase; `authStateChanges` emits `AuthUser` on sign-in and `null` on sign-out
  4. App Check activates only in release builds (`kReleaseMode`): `AndroidProvider.playIntegrity` on Android, `AppleProvider.appAttest` on iOS; dev builds skip activation entirely with no debug-token friction
  5. `FirebaseAnalytics.instance` and `FirebasePerformance.instance` are registered in DI, `cloud_firestore` has offline persistence enabled, and both Android + iOS builds launch without pod/gradle errors
**Plans:** 4 plans
Plans:
- [x] 04-01-PLAN.md — BoM 4.12.0 pubspec bumps, stub firebase_options.dart, DI environment wiring
- [x] 04-02-PLAN.md — StartUpService restructure (Firebase init + Crashlytics + App Check), FirebaseModule for Analytics/Performance/Firestore
- [x] 04-03-PLAN.md — FirebaseAuthService implementation (Email, Google, Apple providers + signOut + passwordReset)
- [x] 04-04-PLAN.md — README Firebase setup documentation (SHA-1, Apple capability, serverClientId, dev mode)
**UI hint**: yes

### Phase 5: UX Patterns (Onboarding + RIVE Splash + Coach Marks)
**Goal**: RIVE 0.14 initialized and driving an animated splash that hands off to the app, a 3-slide onboarding feature gated by an `auto_route` guard, and a `CoachMarkService` wrapper with a live FAB demo on the counter page
**Depends on**: Phase 4
**Requirements**: UX-01, UX-02, UX-03, UX-04, UX-05, UX-06, UX-07, UX-08
**Success Criteria** (what must be TRUE):
  1. On first launch, the user sees a native splash → RIVE animated splash → 3-slide `PageView` onboarding with dots + skip/next buttons, then lands on the home screen; subsequent launches skip onboarding and go straight home
  2. `await RiveNative.init()` is called in each `main_*.dart` before `runApp`, and the splash-to-home handoff happens via `addPostFrameCallback` + `FlutterNativeSplash.remove()` with no visible flicker
  3. `hasSeenOnboarding` is persisted via `SharedPreferencesAsync` through a `core/preferences/` service, and the `OnboardingGuard` redirects first-run users via `auto_route` before `HomeRoute`
  4. On first visit to the counter page, the FAB is highlighted by a `CoachMarkService.showTour('home')` with a short description; on subsequent visits the tour does not re-show (flag persisted per `tourId`)
  5. A dedicated demo screen loads a `.riv` asset with `RiveWidgetBuilder`, exposes a state-machine input toggle, and cleans up the controller in `dispose`
**Plans**: 4 plans
Plans:
- [x] 05-01-PLAN.md — Foundation: RIVE init, OnboardingGuard, router refactor, ARBs, assets, preference keys
- [x] 05-02-PLAN.md — 3-slide onboarding PageView with cubit, dot indicator, skip/next/get-started
- [x] 05-03-PLAN.md — RIVE demo page with RiveWidgetBuilder, state-machine toggle, proper disposal
- [x] 05-04-PLAN.md — CoachMarkService wrapper + two-target home page tour (counter + FAB)
**UI hint**: yes

### Phase 6: Bootstrap + i18n Cleanup + Tests
**Goal**: One-pass `dart run tool/bootstrap.dart` rename script, PL→EN ARB template switch with drift reconciled, and reference tests for the counter feature that establish the copy-paste pattern for downstream work
**Depends on**: Phase 5
**Requirements**: TOOL-01, TOOL-02, TOOL-04, TOOL-05, TOOL-06, TOOL-07
**Success Criteria** (what must be TRUE):
  1. Running `dart run tool/bootstrap.dart --name MyApp --bundle com.example.myapp` against a fresh clone renames Dart package, iOS + Android bundle ids, Info.plist display name, Android namespace + applicationId, pubspec name + description, and README title in a single pass; a post-bootstrap `fvm flutter build apk` succeeds on the renamed copy
  2. The bootstrap script prints a post-run checklist covering Firebase project creation, `flutterfire configure` invocation, and SHA-1 registration steps
  3. `l10n.yaml` uses `template-arb-file: app_en.arb`, the PL/EN drift is reconciled (no missing keys in either file), and `untranslated-messages-file` is configured and gitignored
  4. `test/features/home_page/` contains a `HomeCubit` test using `bloc_test` + `mocktail` and a Drift repository test using `NativeDatabase.memory()`; `fvm flutter test` exits 0
  5. `test/tool/bootstrap_test.dart` runs the rename script against a fixture copy and asserts `flutter analyze` passes and an APK builds on the renamed output
**Plans:** 3/3 plans complete
Plans:
- [x] 06-01-PLAN.md — ARB template switch (PL->EN), mocktail dep, counter cubit + repository reference tests
- [x] 06-02-PLAN.md — Bootstrap rename script (tool/bootstrap.dart) with input validation and Firebase checklist
- [x] 06-03-PLAN.md — Bootstrap script end-to-end tests (fixture copy + rename + analyze verification)

### Phase 7: Documentation
**Goal**: README rewritten around the bootstrap + FlutterFire flow, rebase procedure captured as a repeatable runbook, and an upgrade playbook for the next FlutterFire BoM / Flutter major
**Depends on**: Phase 6
**Requirements**: DOCS-01, DOCS-02, DOCS-03
**Success Criteria** (what must be TRUE):
  1. A new developer can follow `README.md` end-to-end from `git clone` to a running Firebase-connected build in under 30 minutes on a clean machine
  2. README documents the bootstrap flow, FlutterFire setup, SHA-1 registration, Apple capability + Services ID steps, the `AuthService` contract, and the Firebase-sterile stance
  3. A rebase runbook (in `docs/` or `.planning/`) captures every step of the native rebase procedure in enough detail for the next Flutter major to be replayed without rewriting
  4. An upgrade playbook covers bumping the FlutterFire BoM, verifying App Check still activates in release, migrating `auto_route` guards if the API shifts again, and verifying Drift migrations still run
**Plans**: TBD

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4 → 5 → 6 → 7

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Native Rebase | 2/2 | Complete | 2026-04-16 |
| 2. Lints, Error Handling, Local Data Layer | 0/2 | Planning complete | - |
| 3. Package Upgrades + Auth Contract | 0/2 | Planning complete | - |
| 4. Firebase Wiring + Auth Providers | 0/4 | Planning complete | - |
| 5. UX Patterns (Onboarding + RIVE Splash + Coach Marks) | 4/4 | Complete | 2026-04-18 |
| 6. Bootstrap + i18n Cleanup + Tests | 3/3 | Complete   | 2026-04-18 |
| 7. Documentation | 0/TBD | Not started | - |

---

*Roadmap created: 2026-04-16 from PROJECT.md + REQUIREMENTS.md + research/ (SUMMARY, STACK, ARCHITECTURE, PITFALLS, FEATURES)*
