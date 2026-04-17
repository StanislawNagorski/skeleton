# Requirements: Skeleton — Flutter Mobile App Starter (2026 Refresh)

**Defined:** 2026-04-16
**Core Value:** Going from `git clone` to a working, Firebase-connected Flutter app on iOS and Android should take minutes, not hours — with a production-grade Clean Architecture already in place.

## v1 Requirements

Requirements for the 2026 refresh milestone. Each maps to a phase in ROADMAP.md.

### Infrastructure (native scaffolding, FVM, platforms)

- [ ] **INFRA-01**: Android/iOS native scaffolding rebased on Flutter 3.41.5's `flutter create` output (AGP 8.11.1, Kotlin 2.2.20, Gradle 8.14, Java 17, iOS Podfile floor 15) while preserving `lib/`, `pubspec.yaml` (with bumped versions), `assets/`, and project-level configs
- [ ] **INFRA-02**: Platforms trimmed to iOS + Android only — `web/`, `macos/`, `linux/`, `windows/` directories and their plugin registrations removed
- [ ] **INFRA-03**: `.fvmrc` pinned to Flutter 3.41.5; `.flutter-plugins-dependencies` regenerated against the current SDK; `pubspec.lock` refreshed and committed
- [ ] **INFRA-04**: Release signing correctly separated from debug signing in `android/app/build.gradle` (replaces the current TODO that reuses the debug keystore)

### Data Layer (local persistence)

- [ ] **DATA-01**: ObjectBox fully removed — dependency, generated files (`objectbox.g.dart`, `objectbox-model.json`), `lib/core/local_database/object_box.dart`, and pubspec `objectbox:` block
- [ ] **DATA-02**: Drift 2.32.1 + drift_flutter 0.3.0 + sqlite3_flutter_libs integrated with a singleton `AppDatabase` registered in `get_it` via `injectable`
- [ ] **DATA-03**: Counter example ported to Drift — reactive query stream, same `repository → service → cubit → UI` flow, equivalent read/write semantics
- [ ] **DATA-04**: `shared_preferences` integrated using the `SharedPreferencesAsync` API (not the legacy sync `getInstance()` pattern)
- [ ] **DATA-05**: `flutter_secure_storage` integrated for token-class persistence with sane Android encryption scheme default

### Core Dart Abstractions (error handling, state, routing, DI)

- [ ] **CORE-01**: Dart 3 sealed `Result<T>` + sealed `Failure` hierarchy replaces `dartz` `Either<Failure, T>`; `dartz` removed from pubspec
- [ ] **CORE-02**: All repository/service signatures return `Result<T>`; all cubits consume via exhaustive `switch` pattern matching — no `fold()` call sites remain
- [ ] **CORE-03**: `flutter_bloc` upgraded 8 → 9; all bloc/cubit usages compile against the new API
- [ ] **CORE-04**: `auto_route` upgraded 9 → 11.1.0 with `auto_route_generator 10.5.0`; guards migrated from the deprecated implemented-class pattern to the new `guards:` property on `RootStackRouter`; all `pushNamed` → `pushPath` / `pop` → `maybePop` migrations applied
- [ ] **CORE-05**: Central `AuthService` abstract class in `lib/core/auth/` exposes `Stream<AuthUser?>` + sign-in methods returning sealed `AuthResult`; `AuthServiceImpl` registered via `@Injectable(as: AuthService)`
- [ ] **CORE-06**: Unused dependencies removed from pubspec: `http`, `uuid`, `collection`

### Firebase Integration

- [ ] **FIRE-01**: FlutterFire BoM 4.12.0 matrix pinned in pubspec: `firebase_core 4.7.0`, `firebase_auth 6.4.0`, `cloud_firestore 6.3.0`, `firebase_crashlytics 5.2.0`, `firebase_analytics 12.3.0`, `firebase_performance 0.11.3`, `firebase_app_check 0.4.3`
- [ ] **FIRE-02**: `Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` called in each `main_*.dart` before `runApp`, after `WidgetsFlutterBinding.ensureInitialized()` and `RiveNative.init()`
- [ ] **FIRE-03**: Global error hook sends fatal Dart errors to Crashlytics via `PlatformDispatcher.instance.onError` + `Isolate.current.addErrorListener`; collection disabled in debug by default
- [ ] **FIRE-04**: `FirebaseAnalytics.instance` exposed as an injected service — no events wired yet (analytics taxonomy is per-app)
- [ ] **FIRE-05**: `FirebasePerformance.instance` automatic tracing enabled; no manual traces required for the skeleton counter example
- [ ] **FIRE-06**: App Check activated only when `kReleaseMode` is true — `AndroidProvider.playIntegrity` on Android, `AppleProvider.appAttest` on iOS; dev builds skip App Check entirely
- [ ] **FIRE-07**: `cloud_firestore` initialized with default settings and offline persistence enabled — ready for use by downstream apps without additional setup

### Firebase Auth (native provider setup, no UI)

- [ ] **AUTH-01**: `firebase_auth` wired; `AuthServiceImpl` subscribes to `authStateChanges()` and re-emits mapped `AuthUser` values on its public `Stream<AuthUser?>`
- [ ] **AUTH-02**: Email + Password provider callable via `AuthService.signInWithEmail(email, password)` and `AuthService.registerWithEmail(email, password)`, both returning sealed `AuthResult`
- [ ] **AUTH-03**: Google Sign-In (`google_sign_in` 7.x stream API) wired end-to-end — `serverClientId` configured on Android (the Web OAuth client ID), OAuth client IDs registered in each Firebase project per flavor, `AuthService.signInWithGoogle()` completes a real sign-in against Firebase Auth
- [ ] **AUTH-04**: Apple Sign-In (`sign_in_with_apple`) wired — `Sign in with Apple` capability added in Xcode for both schemes, Services ID configured, `AuthService.signInWithApple()` completes a real sign-in against Firebase Auth on iOS
- [ ] **AUTH-05**: README documents the SHA-1 registration workflow (debug + release keystores × dev + prod Firebase projects = four fingerprints), the Apple capability + Services ID steps, and reversed client ID Info.plist entries per flavor
- [ ] **AUTH-06**: `AuthService.signOut()` signs out of all active providers and the user stream emits `null`

### UX Patterns (onboarding, coach marks, RIVE)

- [ ] **UX-01**: Onboarding feature at `lib/features/onboarding/` — 3-slide `PageView` with dots indicator, skip button, and next / "get started" CTA; follows existing Clean-Architecture layering (data / domain / presentation)
- [ ] **UX-02**: `hasSeenOnboarding` flag persisted in `shared_preferences` via the `SharedPreferencesAsync` API; reading / writing abstracted through a `core/preferences/` service
- [ ] **UX-03**: `auto_route` guard redirects first-run users to onboarding; after completion, the flag flips and subsequent launches land directly on `HomeRoute`
- [ ] **UX-04**: `CoachMarkService` wrapper over `tutorial_coach_mark` — API: `register(GlobalKey key, String description, {String? title})` + `showTour(String tourId)`; internally it resolves registered keys to `TargetFocus` and handles "target not yet laid out" via `addPostFrameCallback`
- [ ] **UX-05**: Counter screen demo — on first visit (flag persisted per tourId in `shared_preferences`), the FAB is highlighted by a coach-mark tour with a short description
- [ ] **UX-06**: RIVE 0.14 initialized with `await RiveNative.init()` in the startup service, before `runApp`
- [ ] **UX-07**: RIVE-based animated splash that renders after the native splash; handoff to `HomeRoute` / guarded routes happens via `addPostFrameCallback` + `FlutterNativeSplash.remove()` with no visible flicker on mid-range devices
- [ ] **UX-08**: Example widget on a dedicated demo screen loads a `.riv` asset with `RiveWidgetBuilder`, exposes a state-machine input toggle, and demonstrates the cleanup pattern (`dispose` of the controller)

### Tooling (bootstrap, lints, tests, i18n)

- [ ] **TOOL-01**: `dart run tool/bootstrap.dart --name <AppName> --bundle <com.foo.app>` renames in a single pass: Dart package (`skeleton` → new name), iOS bundle id (+ auto-derived `.dev` variant), Android namespace + applicationId, iOS `Info.plist` display names per scheme, Android `strings.xml` app labels per flavor, launcher-icon YAML pointers, `pubspec.yaml` name + description, `README.md` title
- [ ] **TOOL-02**: Bootstrap script prints a post-bootstrap checklist — create `<name>-dev` and `<name>-prod` Firebase projects, register Android + iOS apps per project with correct bundle ids, download `google-services.json` / `GoogleService-Info.plist` into flavor dirs, run `flutterfire configure --project=<name>-<flavor> --out=lib/firebase_options_<flavor>.dart` twice, register SHA-1 fingerprints
- [ ] **TOOL-03**: `very_good_analysis` replaces `flutter_lints` in `pubspec.yaml` dev_dependencies and `analysis_options.yaml`; analyzer configured with errors-not-warnings for key rules; existing `lib/` code compiles clean under the new rules (fix or `// ignore` with a justifying comment)
- [ ] **TOOL-04**: ARB template switched PL → EN — `l10n.yaml` `template-arb-file: app_en.arb`; existing PL/EN drift reconciled (no missing keys in either file)
- [ ] **TOOL-05**: `l10n.yaml` configured with `untranslated-messages-file: untranslated_messages.txt` so missing translations are visible in build output and gitignored
- [ ] **TOOL-06**: Example test at `test/features/home_page/` covering the counter feature — cubit test using `bloc_test`, repository test using Drift `NativeDatabase.memory()`, data-source fakes via `mocktail`; establishes the copy-paste pattern for all future features
- [ ] **TOOL-07**: Bootstrap script itself has end-to-end tests (run on a fixture rename copy + `flutter analyze` + `flutter build apk --flavor dev` verified)

### Documentation

- [ ] **DOCS-01**: README rewritten to document: bootstrap flow end-to-end, per-flavor FlutterFire setup checklist, SHA-1 registration, architecture conventions (Clean Architecture + Cubit + sealed Result), AuthService contract, and the Firebase-sterile stance of the skeleton
- [ ] **DOCS-02**: Native rebase procedure documented as a repeatable runbook in `.planning/` or `docs/` — step-by-step so the next Flutter major can replay it: temp-dir `flutter create`, filesystem swap of native dirs, pubspec merge, delta review, regeneration commands
- [ ] **DOCS-03**: Upgrade playbook documents how to bump the FlutterFire BoM, validate App Check still activates in release, migrate `auto_route` guards if the API shifts again, and verify the Drift schema still runs migrations

## v2 Requirements

Deferred to future milestones. Tracked but not in current roadmap.

### CI/CD

- **CI-01**: GitHub Actions workflow — lint + test + debug build on PR
- **CI-02**: Fastlane scaffold for iOS/Android release builds
- **CI-03**: Pre-commit hooks via lefthook (format, analyze, scoped tests)

### Additional Firebase

- **FIRE2-01**: Firebase Messaging (FCM) initialization + foreground/background handler scaffold
- **FIRE2-02**: Firebase Remote Config service wrapper

### Additional Platforms

- **PLAT-01**: Web support (re-add with Firebase Hosting target)

## Out of Scope

Explicitly excluded. Documented to prevent scope creep.

| Feature | Reason |
|---------|--------|
| Login UI screen | Login UX varies per target app; only native provider setup is reusable |
| CI/CD workflows (GitHub Actions, fastlane) | Per-project concern; skeleton stays lean (tracked in v2) |
| Pre-commit hooks (lefthook, husky) | Developer-preference, added per-project (tracked in v2) |
| Web / macOS / Linux / Windows | Mobile-first skeleton; other platforms re-added per-project if ever needed |
| Anonymous Firebase Auth | Not required for the target app profile |
| Staging flavor (third environment) | `dev` + `prod` cover current needs; adding `staging` is cheap later, carrying it now is dead weight |
| Analytics event taxonomy / screen-tracking conventions | Too app-specific for a skeleton |
| In-app purchases / subscriptions scaffolding | Added per-app when required |
| Deep linking (dynamic/universal links, Android intent filters) | Per-app; skeleton exposes `auto_route` hooks only |
| Push notification UI and routing logic | Per-app (FCM initialization deferred to v2) |
| Replacing `flutter_bloc` with Riverpod | Proven in skeleton, no compelling 2026 reason to swap |
| Replacing `get_it` + `injectable` | Proven, staying |
| Replacing `auto_route` with `go_router` | `auto_route` stays, bumped to 11 |
| Shared demo Firebase project committed in skeleton | Skeleton is Firebase-sterile; each new app configures its own projects post-bootstrap |
| `flutter_flavorizr` or other flavor generator | Flavors hand-rolled so every file is explicit in `git diff` |
| Dev/prod flavors in skeleton | Dropped from v1 — next apps won't need flavors at start; added per-app when needed |
| Firebase App Check in dev builds | Debug-token distribution friction; App Check only in `kReleaseMode` |
| Continuing PL as ARB template | Non-standard; switched to EN template |
| ObjectBox (retained as alternative) | Replaced by Drift; no dual-database support in skeleton |

## Traceability

Which phase covers which requirement. Populated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| INFRA-01 | Phase 1 | Pending |
| INFRA-02 | Phase 1 | Pending |
| INFRA-03 | Phase 1 | Pending |
| INFRA-04 | Phase 1 | Pending |
| DATA-01 | Phase 2 | Pending |
| DATA-02 | Phase 2 | Pending |
| DATA-03 | Phase 2 | Pending |
| DATA-04 | Phase 2 | Pending |
| DATA-05 | Phase 2 | Pending |
| CORE-01 | Phase 2 | Pending |
| CORE-02 | Phase 2 | Pending |
| CORE-03 | Phase 3 | Pending |
| CORE-04 | Phase 3 | Pending |
| CORE-05 | Phase 3 | Pending |
| CORE-06 | Phase 2 | Pending |
| FIRE-01 | Phase 4 | Pending |
| FIRE-02 | Phase 4 | Pending |
| FIRE-03 | Phase 4 | Pending |
| FIRE-04 | Phase 4 | Pending |
| FIRE-05 | Phase 4 | Pending |
| FIRE-06 | Phase 4 | Pending |
| FIRE-07 | Phase 4 | Pending |
| AUTH-01 | Phase 4 | Pending |
| AUTH-02 | Phase 4 | Pending |
| AUTH-03 | Phase 4 | Pending |
| AUTH-04 | Phase 4 | Pending |
| AUTH-05 | Phase 4 | Pending |
| AUTH-06 | Phase 4 | Pending |
| UX-01 | Phase 5 | Pending |
| UX-02 | Phase 5 | Pending |
| UX-03 | Phase 5 | Pending |
| UX-04 | Phase 5 | Pending |
| UX-05 | Phase 5 | Pending |
| UX-06 | Phase 5 | Pending |
| UX-07 | Phase 5 | Pending |
| UX-08 | Phase 5 | Pending |
| TOOL-01 | Phase 6 | Pending |
| TOOL-02 | Phase 6 | Pending |
| TOOL-03 | Phase 2 | Pending |
| TOOL-04 | Phase 6 | Pending |
| TOOL-05 | Phase 6 | Pending |
| TOOL-06 | Phase 6 | Pending |
| TOOL-07 | Phase 6 | Pending |
| DOCS-01 | Phase 7 | Pending |
| DOCS-02 | Phase 7 | Pending |
| DOCS-03 | Phase 7 | Pending |

**Coverage:**
- v1 requirements: 46 total
- Mapped to phases: 46 ✓
- Unmapped: 0

---
*Requirements defined: 2026-04-16*
*Last updated: 2026-04-17 — flavors (FLAV-*) removed, phases renumbered 4-7, 46 requirements mapped to 7 phases*
