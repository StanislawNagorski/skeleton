# Features Research — Flutter Mobile Skeleton 2026

**Project:** Skeleton — Flutter Mobile App Starter (2026 Refresh)
**Researched:** 2026-04-16
**Overall confidence:** HIGH (most claims verified against Firebase official docs via Context7, FlutterFire docs, Drift docs, and pub.dev; package choices cross-referenced with existing skeleton and PROJECT.md decisions)

## Summary

A 2026-grade Flutter mobile skeleton earns its keep on three axes: **native wiring pre-solved**, **architecture already expressed**, and **one representative feature proving the patterns end-to-end**. Everything else is either table-stakes hygiene (lints, localization, themes) or differentiator fat to be trimmed.

The author's target apps (Firebase + RIVE + onboarding) concentrate value in two bands that most community templates skip:
1. **Native + Firebase setup that actually runs** — not `TODO: configure Firebase`, but per-flavor `google-services.json` / `GoogleService-Info.plist`, SHA keys checklist, reversed client IDs in Info.plist URL schemes, App Check with Play Integrity + DeviceCheck, and Crashlytics hooked into `FlutterError.onError` + `PlatformDispatcher.instance.onError`.
2. **Starter UX patterns the author re-implements every project** — RIVE splash, 3-slide onboarding with `hasSeenOnboarding` persistence, `tutorial_coach_mark` wrapped in a reusable `CoachMarkService`.

Anti-features (Login UI, CI/CD, push UI, deep links, staging flavor, analytics taxonomy) are not gaps — they are deliberate load-bearing decisions. A skeleton that ships them is pre-committing each downstream app to shapes it does not yet know. PROJECT.md has them out of scope and research confirms the call.

The Drift + Dart 3 sealed classes + `flutter_bloc` 9 + `auto_route` 10 + `very_good_analysis` stack already matches the 2026 community direction; no evidence argues for changing course.

Categorization follows: **table stakes** (production skeletons all have these — omitting any of them negates the skeleton's acceleration value), **differentiators** (what makes *this* skeleton uniquely valuable for the author's target apps), **anti-features** (deliberately out of scope with justification).

---

## Table Stakes (production skeletons all have these)

### Architecture Scaffolding

**What:** Clean Architecture per feature (`data/` → `domain/` → `presentation/`), Cubit state management with immutable `part`-linked state, `get_it` + `injectable` DI with abstract-class-first registration, `auto_route` 10 with `@RoutePage` annotations, reactive data flow (data-source stream → repository → cubit → UI).

**Complexity:** Low — the existing skeleton already has this. Rebase preserves `lib/` verbatim.

**Likely skeleton location:**
- `lib/core/injectable/injection.dart` + `.config.dart` (generated)
- `lib/core/router/router.dart` + `.gr.dart` (generated)
- `lib/features/<feature>/data/<model|local_database|remote|repository>/`
- `lib/features/<feature>/domain/<service>.dart`
- `lib/features/<feature>/presentation/<page>.dart` + `cubit/<cubit|state>.dart`

**Notes:** 2026 community guidance (Startup House, Code with Andrea) warns against over-engineering Clean Architecture for trivial features. Mitigation: keep the layer set minimal (model / data source / repository / service / cubit / widget) and skip Use Cases until business logic warrants them. The skeleton already does this.

**Dependencies:** None — this is the foundation everything else builds on.

---

### Firebase Full Wiring

**What:** End-to-end Firebase: Core, Auth (providers configured natively, no login UI), Firestore, Crashlytics with global error handler, Analytics, Performance, App Check with Play Integrity (Android) + DeviceCheck/App Attest (iOS). No stubs. Per-flavor `firebase_options.dart`.

**Initialization order (locked in by FlutterFire docs, 2026-04 refresh):**
1. `WidgetsFlutterBinding.ensureInitialized()`
2. `await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)` — platform-specific options loaded from generated `firebase_options.dart`.
3. `await FirebaseAppCheck.instance.activate(...)` — **before** any other Firebase service call that hits the backend.
4. Install `FlutterError.onError` + `PlatformDispatcher.instance.onError` hooks.
5. `await configureDependenciesApp()` (DI).
6. `await initDrift()`.
7. `runApp(...)`.

**Complexity:** High — per-flavor wiring is where most skeletons regress. `flutterfire configure` must be run once per flavor with `--ios-bundle-id`, `--ios-out`, `--android-package-name`, `--android-out` flags to produce per-flavor config files. iOS requires an Xcode Run Script Phase that copies the correct `GoogleService-Info.plist` based on the active scheme.

**Likely skeleton location:**
- `lib/firebase/firebase_options_dev.dart`, `firebase_options_prod.dart` (generated)
- `lib/core/firebase/firebase_initializer.dart` (orchestrator called from `startup_service.dart`)
- `android/app/src/dev/google-services.json`, `android/app/src/prod/google-services.json`
- `ios/config/dev/GoogleService-Info.plist`, `ios/config/prod/GoogleService-Info.plist` + Xcode Run Script Phase
- `.gitignore` entries for `lib/firebase_options*.dart`, `ios/config/*/GoogleService-Info.plist`, `android/app/src/*/google-services.json` when the author chooses to keep them out of the template repo (decision needed at roadmap time)

**Dependencies:** Flavors must exist first (per-flavor config file paths depend on flavor names).

---

### Auth Native Setup

**What:** Email + Password, Google Sign-In, Apple Sign-In **providers initialized natively** — no login screen. Covers the painful repeatable bits that vary per project:

- **Android:** SHA-1 (debug) + SHA-256 (release) keys registered in Firebase Console per app; `google-services.json` wired via `google-services` Gradle plugin; Google Sign-In auto-wires SHA-based OAuth client.
- **iOS:** `REVERSED_CLIENT_ID` from `GoogleService-Info.plist` added to `Info.plist` URL Types `CFBundleURLSchemes`; `Sign in with Apple` capability in Xcode entitlements; Apple Services `.p8` configured in Firebase Console (one-time per Apple Developer team).
- **Dart-side:** `FirebaseAuth.instance`, `GoogleSignIn` (or `signInWithProvider(GoogleAuthProvider())`), `SignInWithApple` initialized in DI; `authStateChanges()` stream exposed via an `AuthRepository`.

**Complexity:** Medium — the code is small; the Firebase Console / Apple Developer / Xcode clicks are where projects stall. Skeleton's job is a **README checklist** per provider, not the UI.

**Likely skeleton location:**
- `lib/core/auth/auth_repository.dart` (abstract + `Impl`) — exposes `Stream<AuthUser?> authStateChanges()`, `signInWith...` methods that return `Result<AuthUser, Failure>`.
- `lib/core/auth/auth_user.dart` — app-side user entity (not `FirebaseUser`).
- `ios/Runner/Info.plist` — URL Types entry with placeholder REVERSED_CLIENT_ID that `bootstrap.dart` or a manual step replaces per project.
- `README.md` section: "Auth provider checklist — Android SHA keys, iOS URL scheme, Apple Services file".

**Dependencies:** Firebase Full Wiring.

---

### Flavors (dev/prod)

**What:** Two flavors only — `dev` and `prod`. Each flavor carries a distinct:
- Android `applicationIdSuffix` (e.g., `.dev`) and `resValue "string" "app_name"`.
- iOS Build Configuration + Scheme + `PRODUCT_BUNDLE_IDENTIFIER` per configuration + `Display Name` override.
- Firebase config file (`google-services.json` / `GoogleService-Info.plist`).
- Launcher icon (dev icon visually distinct — e.g., "DEV" band — so testers can tell builds apart on-device).
- Dart `--dart-define=FLAVOR=dev|prod` entry point (`lib/main_dev.dart`, `lib/main_prod.dart`) OR a single `main.dart` that reads `const String.fromEnvironment('FLAVOR')`.

**Complexity:** High (initial setup), low (ongoing). The first wiring is fragile — flavor drift in `build.gradle`, missing Xcode scheme, wrong bundle id in plist — but once correct, it is rarely touched.

**Recommendation:** Drive flavor setup with **`flutter_flavorizr`** — it generates iOS schemes, Android product flavors, launcher icons, and flavor entry points in one pass. Manual setup is a known time sink (docs.flutter.dev official flavors guide runs to several pages of native edits). Alternative: hand-rolled scripts. For a skeleton whose purpose is "clone + bootstrap", generator-backed flavors are the right abstraction level.

**Likely skeleton location:**
- `flavorizr.yaml` (package config at project root)
- `android/app/build.gradle` — `flavorDimensions`, `productFlavors { dev { ... } prod { ... } }`
- `ios/Runner.xcodeproj/project.pbxproj` + `xcshareddata/xcschemes/dev.xcscheme`, `prod.xcscheme`
- `lib/main_dev.dart`, `lib/main_prod.dart`
- `lib/core/flavor/flavor_config.dart` — exposes `currentFlavor` + flavor-aware configs (Firebase options selector, API base URL hook for downstream apps).

**Dependencies:** Must exist before Firebase per-flavor wiring; must exist before per-flavor launcher icons.

---

### Bootstrap / Rename

**What:** `dart run tool/bootstrap.dart --name <AppName> --bundle <com.foo.app>` — a deterministic, re-runnable script that renames:
- Dart package (`pubspec.yaml` `name:`, all `package:skeleton/...` imports → `package:<newname>/...`).
- Android `applicationId` + `namespace` + `MainActivity` package path + AndroidManifest.
- iOS `PRODUCT_BUNDLE_IDENTIFIER` across Debug / Release / Profile + dev / prod configurations.
- `Info.plist` `CFBundleDisplayName` + `CFBundleName`.
- Launcher icons (invokes `flutter_launcher_icons` per flavor).
- `firebase.json` project selection (optional — points at per-project FlutterFire setup).

**Complexity:** Medium — straightforward file edits but must be re-runnable (idempotent) and carefully scoped (do not touch `.git/`, `build/`, `.dart_tool/`, `ios/Pods/`). Community `rename` package exists but does not cover per-flavor bundle ids or Firebase wiring hooks. Writing a Dart script gives full control and does not add a runtime dependency.

**Good bootstrap script coverage:**
- Validates inputs (name PascalCase-able, bundle is reverse-DNS).
- Dry-run mode (`--dry-run` prints changes without writing).
- Idempotent (running twice produces the same result; safe to re-run after a partial failure).
- Skips regenerating generated files (runs `build_runner` at the end instead).
- Prints a post-run checklist: "Run `flutterfire configure` for dev, then for prod. Register SHA keys in Firebase Console. Add REVERSED_CLIENT_ID to Info.plist URL Types."

**Likely skeleton location:**
- `tool/bootstrap.dart` — main entry point.
- `tool/lib/rename_dart_package.dart`, `rename_android.dart`, `rename_ios.dart`, `rename_launcher_icons.dart` — composable steps.
- `tool/README.md` — usage + flag reference.

**Dependencies:** Flavors must exist (bootstrap renames per-flavor bundle ids).

---

### Error Handling Pattern

**What:** Dart 3 sealed classes + pattern matching replace `dartz` `Either<Failure, T>`. Keep the `Failure` hierarchy concept; drop the library dependency.

**Pattern (verified 2026 community direction):**

```dart
// lib/core/errors/result.dart
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Err<T> extends Result<T> {
  const Err(this.failure);
  final Failure failure;
}
```

```dart
// lib/core/errors/failures.dart
sealed class Failure {
  const Failure(this.message);
  final String? message;
}

final class LocalDataNotFoundFailure extends Failure {
  const LocalDataNotFoundFailure([super.message]);
}

final class LocalDataSourceFailure extends Failure {
  const LocalDataSourceFailure([super.message]);
}

final class RemoteFailure extends Failure {
  const RemoteFailure([super.message]);
}

final class AuthFailure extends Failure {
  const AuthFailure([super.message]);
}
```

**Consumer pattern (replaces `.fold()`):**

```dart
switch (await repository.getCounter()) {
  case Success(:final value):
    emit(state.copyWith(status: HomePageStatus.success, counter: value));
  case Err(:final failure):
    _logger.e('getCounter failed: ${failure.message}');
    emit(state.copyWith(status: HomePageStatus.error));
}
```

**Complexity:** Low — the pattern is simpler than `Either`. Exhaustive `switch` on `sealed` gives the same compile-time guarantee as `Either.fold()` without the library.

**Likely skeleton location:**
- `lib/core/errors/result.dart`
- `lib/core/errors/failures.dart`
- Used throughout `lib/features/*/data/repository/*.dart` and consumed in `lib/features/*/presentation/cubit/*_cubit.dart`.

**Dependencies:** None — this is groundwork before the counter example is ported.

---

### Localization

**What:** ARB + `gen_l10n` pipeline, PL + EN supported, key naming `<feature>_<camelCaseDescriptor>`, access via `context.localizations.<key>`.

**Complexity:** Low — already in place.

**Likely skeleton location:**
- `l10n.yaml`
- `lib/core/localization/app_en.arb`, `app_pl.arb`
- `lib/core/extensions/context_extension.dart` — `context.localizations`.

**Notes:** Keep `app_pl.arb` as template per current convention. The author's personal workflow is Polish-first; codebase stays English, so the template-as-Polish choice is deliberate.

**Dependencies:** None.

---

### Theme System

**What:** Material 3 theme built from `ColorScheme.fromSeed()` for both light and dark modes. Design tokens broken into `app_colors`, `app_dimensions`, `app_fonts`, `app_styles`, `app_images`. **Add dark theme** — currently only `AppThemes.light` exists; `MaterialApp.router` passes `theme`, `darkTheme`, and `themeMode: ThemeMode.system`.

**Complexity:** Low — Material 3's `ColorScheme.fromSeed()` with `brightness: Brightness.dark` handles the dark palette automatically from the same seed color.

**Recommendation:** Keep the existing tokens (`AppColors.primary` seed). Add `AppThemes.dark`. Let downstream apps override the seed in their `app_colors.dart`. Do not ship a runtime theme toggle — that is per-app UX.

**Likely skeleton location:**
- `lib/core/presentation/app_themes.dart` — `static ThemeData get light`, `static ThemeData get dark`.
- `lib/core/presentation/app_colors.dart` — seed + semantic color tokens.
- `lib/core/presentation/app_dimensions.dart`, `app_fonts.dart`, `app_styles.dart`, `app_images.dart` — populated tokens (not empty placeholders).

**Dependencies:** None.

---

### Logging

**What:** `package:logger` per-class `Logger` instances; log levels used consistently (`.t` trace, `.d` debug, `.i` info, `.w` warn, `.e` error with stack). Integrated with Crashlytics: `logger.e(...)` also forwards to `FirebaseCrashlytics.instance.recordError()` for non-fatal tracking.

**Complexity:** Low — existing skeleton already has per-class logger. The Crashlytics forwarder is a small extension.

**Likely skeleton location:**
- `lib/core/logging/app_logger.dart` — optional factory that pairs a `Logger` with a Crashlytics forwarder output for error-level logs.
- Used from every repository, service, and cubit.

**Dependencies:** Firebase Full Wiring (for Crashlytics hook).

---

### Lints

**What:** `very_good_analysis` (not `flutter_lints`), analyzer configured to promote lints to **errors** rather than warnings, generated files excluded via `analyzer: exclude:` block.

**Rationale (verified):** `very_good_analysis` enables `strict-inference` and `strict-raw-types`; adds rules that `flutter_lints` leaves off (`prefer_single_quotes`, `prefer_const_constructors_in_immutables`, `require_trailing_commas`, etc.). Errors-not-warnings means CI (when downstream adds it) cannot be silently polluted.

**Complexity:** Low.

**Likely skeleton location:**
- `analysis_options.yaml` — `include: package:very_good_analysis/analysis_options.yaml`; `analyzer.errors:` map promoting key lints; `analyzer.exclude:` list for generated files (`**/*.g.dart`, `**/*.gr.dart`, `**/*.config.dart`, `lib/generated/**`, `**/firebase_options*.dart`).

**Dependencies:** None.

---

### Example Feature + Test

**What:** The counter feature, ported from ObjectBox to Drift, with its reactive stream preserved. Accompanied by a **reference test** covering:
1. **Cubit unit test** — `HomeCubit` with a `MockCounterService`, using `bloc_test` + `mocktail`, asserts emitted state sequence for `init()`, `incrementCounter()`, error path.
2. **Repository unit test** — `CounterRepositoryImpl` with a Drift in-memory `NativeDatabase.memory()` (the official Drift-recommended pattern), asserts `getCounter` / `setCounter` / `watchCounter` happy + error paths.

**Why both layers:** gives downstream apps a copy-paste pattern for both UI-layer and data-layer tests. Without the repository test, teams default to "mock the repo" everywhere and never unit-test Drift code — a known gap in the current skeleton's empty `test/` dir.

**Complexity:** Medium — Drift tests need `sqlite3` on the host; `NativeDatabase.memory()` and `closeStreamsSynchronously: true` on the `DatabaseConnection` are required to avoid leaking stream timers at test shutdown.

**Likely skeleton location:**
- `test/features/home_page/presentation/cubit/home_cubit_test.dart`
- `test/features/home_page/data/repository/counter_repository_test.dart`
- `test/helpers/test_drift_db.dart` — in-memory database factory shared by data-layer tests.
- `test/helpers/fallback_values.dart` — `registerFallbackValue()` calls for mocktail (CounterModel, HomeState).

**Dependencies:** Drift swap must be complete; sealed-class Result must be in place (tests assert `Success` / `Err`, not `Right` / `Left`).

---

### README / Upgrade Playbook

**What:** Three distinct documents (or three well-marked README sections):

1. **Bootstrap flow** — `git clone → fvm install → fvm flutter pub get → dart run tool/bootstrap.dart --name MyApp --bundle com.me.myapp → flutterfire configure (dev) → flutterfire configure (prod) → SHA keys + URL schemes checklist → fvm flutter run --flavor dev`.
2. **Architecture conventions** — distilled from existing `.planning/codebase/CONVENTIONS.md` (naming, layer rules, DI registration, error handling).
3. **Upgrade playbook** — *how to re-run the rebase when the next Flutter major ships*. This is the under-appreciated piece: document what the 2026 refresh changed, which files were regenerated by `flutter create` vs preserved, and give the next author the recipe.

**Complexity:** Low — writing discipline, not technical difficulty.

**Likely skeleton location:**
- `README.md` — top-level bootstrap + conventions reference.
- `UPGRADE.md` (or `docs/UPGRADING.md`) — playbook for the next Flutter major.

**Dependencies:** Everything else (the README describes how to use everything else).

---

## Differentiators (value-adds for this author's apps)

These are the features that separate this skeleton from "yet another Flutter template" and serve the author's specific target-app profile (Firebase-backed + RIVE + onboarding-heavy).

### RIVE Splash + Widget

**What:** Two-layer splash:
1. **Native splash** via `flutter_native_splash` — displays instantly on cold start, covers Dart VM + Flutter engine boot.
2. **RIVE animated splash** — displayed after `WidgetsFlutterBinding.ensureInitialized()`, during the Firebase + DI + Drift initialization window. Uses `rive_splash_screen` pattern: `startAnimation` → `loopAnimation` → `endAnimation` driven by an `until:` future that resolves when `StartUpService.initServices()` completes.

Plus a second **example RIVE widget** (separate from the splash) demonstrating state-machine input/output — e.g., a tappable RIVE button whose animation responds to a Dart-side boolean.

**Why differentiating:** Every target app the author ships uses RIVE. Pre-solving the splash → RIVE → Flutter handoff (which is where seams show: black flash between native splash and first Flutter frame, timing the RIVE end animation with init completion) saves hours per app.

**Complexity:** Medium — timing the native-to-Flutter handoff requires `FlutterNativeSplash.preserve()` + `FlutterNativeSplash.remove()` bookending the Rive widget.

**Likely skeleton location:**
- `assets/rive/splash.riv` — placeholder RIVE file with `start`, `loop`, `end` state machine names documented.
- `assets/rive/example.riv` — second placeholder demonstrating a state machine with inputs.
- `lib/core/splash/rive_splash_screen.dart` — the splash widget.
- `lib/features/home_page/presentation/widgets/rive_example.dart` — the state-machine example widget, embedded on the counter page.
- `pubspec.yaml` — `rive:` + `flutter_native_splash:` dependencies; `flutter_native_splash:` config section (or separate `flutter_native_splash.yaml`).

**Dependencies:** None (runs before Firebase init completes; actually *covers* that init window).

---

### Onboarding Feature

**What:** 3-slide `PageView` with `smooth_page_indicator` dots + Skip + Next/Done buttons. `hasSeenOnboarding` bool in `shared_preferences`. `auto_route` guard (`OnboardingGuard`) redirects first-run users to `/onboarding` instead of `/home`. Once completed, flag flips and the guard becomes transparent.

**Why differentiating:** Re-implemented in every app the author has shipped. 100 lines + a guard + a prefs key — a package adds maintenance risk for no real savings (author decision per PROJECT.md Key Decisions).

**Complexity:** Low — straightforward `PageView` + prefs + route guard.

**Likely skeleton location:**
- `lib/features/onboarding/presentation/onboarding_page.dart` — `@RoutePage()`, builds the `PageView` + indicator + buttons.
- `lib/features/onboarding/presentation/widgets/onboarding_slide.dart` — reusable slide component (image + title + description).
- `lib/features/onboarding/presentation/cubit/onboarding_cubit.dart` + `state.dart` — tracks current page, handles skip/done.
- `lib/features/onboarding/data/onboarding_repository.dart` — reads/writes `hasSeenOnboarding` to `SharedPreferences`.
- `lib/core/router/guards/onboarding_guard.dart` — `AutoRouteGuard` that reads the flag via DI and redirects.
- Route registered in `lib/core/router/router.dart`.

**Dependencies:** `shared_preferences` in DI; `auto_route` 10.

---

### Coach Marks (`tutorial_coach_mark` wrapper)

**What:** A `CoachMarkService` wrapping `tutorial_coach_mark`. Exposes:
- `register(GlobalKey key, {required String description, String? title})` — features add their coach marks declaratively from `initState` / `build`.
- `showTour({String? tourId})` — presents the tour; `tourId` lets a single app run multiple distinct tours (e.g., "home tour" vs "settings tour").
- `markTourCompleted(String tourId)` / `hasSeenTour(String tourId)` — persisted to `shared_preferences`.

Live demo: the home page FAB is registered in `initState`; on first visit after onboarding, `showTour('home')` highlights it with "Tap to increment the counter" description.

**Why differentiating:** The author has used `tutorial_coach_mark` successfully (per PROJECT.md); the thin service wrapper is the piece worth carrying project-to-project because the raw package API requires boilerplate at every call site (`TargetFocus` construction, `TargetContent.builder`, overlay show/dismiss). The wrapper keeps feature code declarative.

**Complexity:** Low-Medium — the wrapper is ~100 lines; the tricky part is ensuring coach marks fire *after* `build` completes and widgets have their render boxes attached (`WidgetsBinding.instance.addPostFrameCallback`).

**Likely skeleton location:**
- `lib/core/coach_marks/coach_mark_service.dart` — the wrapper (abstract + Impl, registered as singleton via `@LazySingleton(as: CoachMarkService)`).
- `lib/core/coach_marks/coach_mark_target.dart` — a small data class pairing `GlobalKey` + description.
- `lib/features/home_page/presentation/home_page.dart` — demonstration call: `coachMarkService.register(fabKey, description: ...)` + `coachMarkService.showTour('home')` gated by `hasSeenTour('home')`.

**Dependencies:** `shared_preferences` in DI; no auto_route interaction needed.

---

### Firebase App Check (Play Integrity + DeviceCheck)

**What:** App Check enabled end-to-end. Activated immediately after `Firebase.initializeApp()` and **before** any other Firebase service call:

```dart
await FirebaseAppCheck.instance.activate(
  androidProvider: kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
  appleProvider: kReleaseMode ? AppleProvider.appAttest : AppleProvider.debug,
);
```

Play Integrity (Android) requires linking the Google Play Console project to Firebase. DeviceCheck / App Attest (iOS) require no additional setup beyond enabling the provider in Firebase Console. Debug mode prints debug tokens that must be registered per-developer in Firebase Console → Security → App Check → Manage debug tokens.

**Why differentiating:** App Check protects backend resources from abuse and is required in practice for any Firebase-backed production app dealing with user data. Most skeletons skip it because it is "infrastructure-flavored" — which is exactly why pre-solving it here multiplies value.

**Complexity:** Medium — code is short; the Play Console linking step and debug-token registration are operational gotchas that need README documentation.

**Likely skeleton location:**
- `lib/core/firebase/firebase_initializer.dart` — the `activate(...)` call.
- `README.md` section: "App Check setup — Android Play Console linking, iOS DeviceCheck provider, debug tokens per developer machine".

**Dependencies:** Firebase Full Wiring.

**Source (verified):** [Firebase App Check Flutter docs via Context7](https://firebase.google.com/docs/app-check/flutter/default-providers) — confirms `AndroidProvider.playIntegrity` and `AppleProvider.appAttest` as the production providers, `AndroidProvider.debug` / `AppleProvider.debug` for development.

---

### Global Error Handler → Crashlytics

**What:** Three catch-all hooks installed during `StartUpService.initServices()`:

```dart
FlutterError.onError = (details) {
  _logger.e('Flutter error', error: details.exception, stackTrace: details.stack);
  FirebaseCrashlytics.instance.recordFlutterFatalError(details);
};

PlatformDispatcher.instance.onError = (error, stack) {
  _logger.e('Platform error', error: error, stackTrace: stack);
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};

Isolate.current.addErrorListener(RawReceivePort((pair) async {
  final [error, stack] = pair as List<dynamic>;
  await FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
}).sendPort);
```

`FlutterError.onError` catches framework-layer errors (widget build exceptions, layout overflows). `PlatformDispatcher.instance.onError` is the Dart 2.17+ catch-all for async errors outside Flutter's zones. The isolate listener catches errors from background isolates (relevant if downstream apps use `compute`).

**Why differentiating:** Every target app needs this; getting all three hooks right (and ordering them before the first `runApp`) is the kind of "boilerplate you only write correctly after doing it three times" that a skeleton should pre-solve.

**Complexity:** Low once you know the pattern. The skeleton makes it reusable.

**Likely skeleton location:**
- `lib/core/errors/global_error_handler.dart` — function `installGlobalErrorHandlers()` called from `startup_service.dart`.

**Dependencies:** Firebase Full Wiring (Crashlytics must be initialized first).

**Source (verified):** [FlutterFire Crashlytics Get Started](https://firebase.google.com/docs/crashlytics/flutter/get-started) and [Flutter error handling docs](https://docs.flutter.dev/testing/errors) — both confirm the two-hook pattern as the 2026 standard.

---

### Per-flavor Launcher Icons + App Names

**What:** Dev builds show a visually distinct launcher icon (e.g., with a "DEV" band) and a distinct display name (e.g., "Skeleton DEV"). Prod uses the canonical icon and name.

Driven by `flutter_launcher_icons` with per-flavor config sections (`flutter_launcher_icons-dev.yaml`, `flutter_launcher_icons-prod.yaml`), invoked from the bootstrap script or a dedicated `tool/generate_icons.dart`.

**Why differentiating:** Testers and internal users end up with dev + prod both installed side-by-side for QA. A banded dev icon eliminates the "which build is this?" confusion. Small DX win, high-frequency benefit across every app.

**Complexity:** Low — `flutter_launcher_icons` handles the cross-platform image variants; the skeleton just provides two base icon files and two config files.

**Likely skeleton location:**
- `assets/icons/launcher_dev.png` (1024x1024 with DEV band).
- `assets/icons/launcher_prod.png` (1024x1024 clean).
- `flutter_launcher_icons-dev.yaml`, `flutter_launcher_icons-prod.yaml`.
- `tool/generate_icons.dart` — convenience wrapper that runs both configs.

**Dependencies:** Flavors must exist.

---

## Anti-Features (confirmed out of scope with justification)

Each anti-feature is already in PROJECT.md "Out of Scope". Research confirms and strengthens the justifications.

### Login UI

**Justification:** Auth UX varies radically per app — splash-gated login vs. inline login vs. social-first vs. email-first vs. magic link. Shipping a screen pre-commits every downstream app to a shape that will get rewritten. The painful part of auth — native setup (SHA keys, URL schemes, Info.plist, Apple services) — is where value concentrates. That **is** in scope (see Differentiator: Auth Native Setup).

**Research note:** Community Flutter skeletons that ship login UIs consistently see them stripped out on first project. No evidence argues against the existing decision.

---

### CI/CD

**Justification:** Per-project concern (different distribution channels, different code-signing setups, different review gates). Adding a `.github/workflows/` directory forces every downstream to delete or adapt it — net negative. The author can add `fastlane/` or a GitHub Actions workflow per-project in minutes once the shape of deployment is known.

**Research note:** Community guidance aligns — CI/CD is one of the most-frequently-rewritten parts of any project; it is fastest to scaffold fresh per-app.

---

### Pre-commit hooks

**Justification:** Developer preference (lefthook vs husky vs raw git hooks vs pre-commit framework). Forcing a choice in the skeleton creates friction without value. `very_good_analysis` set to error-level already catches the majority of what a pre-commit hook would enforce locally.

---

### Web / Desktop

**Justification:** Mobile-first skeleton. `flutter create` on current Flutter generates `web/`, `macos/`, `linux/`, `windows/` scaffolds by default; explicitly removing them in the rebase (and declaring `platforms:` in `pubspec.yaml` as only `android: ... ios: ...`) prevents accidental plugin pollution, unused native maintenance surface, and misleading `flutter devices` output. Re-adding per-project if ever needed is a one-liner.

---

### Staging flavor

**Justification:** Author's current app profile needs two environments (dev for daily development + prod for store releases). A third flavor would carry a triple of native config changes (bundle ids, icons, Firebase project) for no current use case. Adding staging later when a concrete need appears is cheap (one `flavorizr.yaml` edit + one `flutterfire configure` run); carrying it pre-emptively is dead weight.

---

### Anonymous Auth

**Justification:** Not required by any of the author's target apps. `FirebaseAuth.instance.signInAnonymously()` is a single line — if a future app needs it, it is trivial to add. Shipping it pre-wired adds a decision (should routes check anonymous vs authenticated?) that every downstream must explicitly defer.

---

### Deep linking config

**Justification:** Highly per-app (URI schemes, universal link domains, Play Store App Links setup). `auto_route` 10 already exposes deep-link handling via `AppRouter.config()` — the skeleton provides the routing hook; the configuration belongs in each app. Shipping a placeholder intent filter / `AASA` file is worse than nothing because it implies a contract that has not been signed.

---

### Push notification UI

**Justification:** Two layers here — (a) Firebase Messaging wiring, (b) notification UI (foreground banners, permission prompts, notification tap → route). PROJECT.md excludes both. Research agrees: (a) is a one-time addition if ever needed, (b) is per-app. Firebase Messaging is not initialized in the skeleton precisely to avoid the APNs certificate / FCM token / background isolate setup that is wasted effort for apps that do not need push.

---

### Analytics event taxonomy

**Justification:** Analytics events are vocabulary that belongs to the product (which screens, which user actions, which funnels matter). Shipping a taxonomy is prescribing a product. `firebase_analytics` is initialized so downstream apps can `FirebaseAnalytics.instance.logEvent(...)` from day one; the **what to log** is app-specific.

---

## Feature Dependencies (what must exist before what)

```
ArchitectureScaffolding (existing lib/) ─── foundation, no deps
            │
            ▼
ErrorHandlingPattern (sealed Result/Failure) ── must exist before counter is ported
            │
            ▼
DriftSwap (+ example ported) ─── depends on ErrorHandling

Lints (very_good_analysis) ─── no deps; run early so new code is written under strict rules

LocalizationSetup (existing) ─── no deps

ThemeSystem (+ dark theme) ─── no deps

Flavors (dev/prod) ─── must exist before:
    ├─ FirebaseFullWiring (per-flavor google-services.json + GoogleService-Info.plist)
    │       │
    │       ├─ AppCheck (activates via FirebaseAppCheck after Firebase.initializeApp)
    │       ├─ GlobalErrorHandler (Crashlytics must be initialized first)
    │       ├─ AuthNativeSetup (Firebase Auth must be initialized first)
    │       └─ Logging+Crashlytics integration
    │
    ├─ PerFlavorLauncherIcons (flutter_launcher_icons needs flavor config files)
    │
    └─ BootstrapScript (renames per-flavor bundle ids — needs flavors to rename)

RIVESplash ─── depends on flutter_native_splash + native splash config; no flavor dep

OnboardingFeature ─── depends on shared_preferences + auto_route guards

CoachMarkService ─── depends on shared_preferences (for hasSeenTour persistence)

ExampleTest (counter cubit + repository) ─── depends on DriftSwap + ErrorHandling
                                               + Lints (so test code meets the bar)

README/UpgradePlaybook ─── depends on everything above (documents how to use them)
```

**Critical path:** Lints → ErrorHandling → DriftSwap → counter port → Flavors → Firebase wiring → App Check + Crashlytics + Auth. The bootstrap script is written **last** (once the final shape of flavors + Firebase wiring is locked in, the script automates renaming across all of it).

**Independent tracks** (can run in parallel with the critical path): Theme dark mode, localization (no change), RIVE splash + widget, Onboarding feature, Coach marks service.

**Documentation last:** README + upgrade playbook write up only after everything else is wired and the bootstrap flow has been run at least once successfully against a throwaway target project name (smoke-test the skeleton's core value proposition before committing the docs that describe it).

---

## Sources

### Authoritative (Context7 / official)

- [Firebase App Check — Flutter default providers](https://firebase.google.com/docs/app-check/flutter/default-providers) — verified via Context7, 2026-04 refresh
- [Firebase App Check — Flutter debug provider](https://firebase.google.com/docs/app-check/flutter/debug-provider) — verified via Context7
- [Firebase Crashlytics Flutter get started](https://firebase.google.com/docs/crashlytics/flutter/get-started) — Firebase official, 2026-04-13
- [Firebase App Check Android Play Integrity](https://firebase.google.com/docs/app-check/android/play-integrity-provider) — Firebase official
- [Flutter handling errors docs](https://docs.flutter.dev/testing/errors) — Flutter official
- [Flutter flavors for Android](https://docs.flutter.dev/deployment/flavors) — Flutter official, 2026-02-06
- [Flutter flavors for iOS and macOS](https://docs.flutter.dev/deployment/flavors-ios) — Flutter official
- [Drift testing docs](https://drift.simonbinder.eu/testing/) — Drift official (Simon Binder)
- [ColorScheme.fromSeed — Flutter API](https://api.flutter.dev/flutter/material/ColorScheme/ColorScheme.fromSeed.html) — Flutter API
- [Material 3 migration](https://docs.flutter.dev/release/breaking-changes/material-3-migration) — Flutter official
- [`very_good_analysis` package](https://pub.dev/packages/very_good_analysis) — pub.dev official
- [`very_good_analysis` GitHub](https://github.com/VeryGoodOpenSource/very_good_analysis) — Very Good Ventures
- [`flutter_native_splash`](https://pub.dev/packages/flutter_native_splash) — pub.dev
- [`rive_splash_screen`](https://fluttergems.dev/packages/rive_splash_screen/) — Flutter Gems catalog
- [`tutorial_coach_mark`](https://pub.dev/packages/tutorial_coach_mark) — pub.dev
- [`smooth_page_indicator`](https://pub.dev/packages/smooth_page_indicator) — pub.dev
- [`flutter_flavorizr`](https://pub.dev/packages/flutter_flavorizr) — pub.dev
- [`bloc_test`](https://pub.dev/packages/bloc_test) — pub.dev
- [FlutterFire overview](https://firebase.flutter.dev/docs/overview/) — FlutterFire official

### Community / pattern references (verified against multiple sources)

- [How to Setup Flutter & Firebase with Multiple Flavors using the FlutterFire CLI — Code with Andrea](https://codewithandrea.com/articles/flutter-firebase-multiple-flavors-flutterfire-cli/)
- [Flutter Error Handling with try/catch and the Result type — Code with Andrea](https://codewithandrea.com/articles/flutter-exception-handling-try-catch-result-type/)
- [Mastering Material Design 3: Complete Guide to Theming in Flutter](https://www.christianfindlay.com/blog/flutter-mastering-material-design3)
- [Flutter App Best Practices in 2026 — Startup House](https://startup-house.com/blog/flutter-app-best-practices)
- [Flutter March 2026 newsletter — Code with Andrea](https://codewithandrea.com/newsletter/march-2026/)
- [Rethinking Error Handling in Dart: Result/Either Pattern (Mar 2026)](https://medium.com/@naman.kashyap12/rethinking-error-handling-in-dart-mastering-the-result-either-pattern-d04b659c977a)
- [Flutter App Security with Firebase AppCheck, Play Integrity, and App Attest](https://medium.com/@sapanprojects/flutter-app-security-with-firebase-appcheck-google-play-store-app-integrity-and-apple-app-attest-8d854e49d6e3)
- [Onboarding Flow with Flutter — Mobile@Exxeta](https://medium.com/@mobileatexxeta/onboarding-flow-with-flutter-80e7cbddcff4)
- [Adding in-app tours to Flutter apps — OpenReplay](https://blog.openreplay.com/adding-in-app-tours-to-flutter-apps/)
- [RydMike Flutter linting comparison](https://rydmike.com/blog_flutter_linting.html)
