# Research Summary — Flutter Mobile Skeleton 2026 Refresh

**Date:** 2026-04-16
**Inputs:** STACK.md, FEATURES.md, ARCHITECTURE.md, PITFALLS.md
**Overall confidence:** HIGH on versions/APIs, MEDIUM on exact `flutter create` 3.41 defaults and RIVE/native-splash handoff timing.

---

## TL;DR

- **This is a rebase, not a rewrite.** `lib/` survives verbatim; native scaffolding is regenerated from a fresh `flutter create`; packages get majors bumped as a coordinated matrix; Firebase gets wired end-to-end; flavors + AuthService + onboarding + RIVE splash land on top.
- **Nine hard blockers must be dodged** — the two sharpest are (a) native rebase vs. ObjectBox leftover state (rebase **before** removing ObjectBox; otherwise `flutter create` wipes custom entries AND fights ObjectBox native libs) and (b) Firebase-flavor coupling where one mis-pathed `google-services.json` or one missing SHA-1 silently breaks Google Sign-In with a generic error.
- **The single most consequential new boundary is `AuthService`** — abstract contract, `Stream<AuthUser?>` for `auto_route`'s `reevaluateListenable`, sealed `AuthResult` (`AuthSuccess` / `AuthFailure` / `AuthCancelled`). Every downstream app builds its login UX on top of it, so the contract must be right before flavors or onboarding plug in.
- **Three package bumps are structural, not cosmetic:** `auto_route` 9→11 (global guards move from `implements AutoRouteGuard` to router-level `guards` override; `$AppRouter` generated class is gone), `google_sign_in` 6→7 (stream-based API; `serverClientId` now required on Android), and `rive` 0.13→0.14 (total C++ runtime rewrite with `await RiveNative.init()` + `RiveWidget` replacing `RiveAnimation`).
- **Critical path is 8 phases**: rebase → lints/errors/Drift in parallel → flavors → Firebase+Auth → onboarding+RIVE splash → coach marks → tests → bootstrap script + docs. Roughly 3 phases can parallelize after P1 lands.

---

## Stack Highlights (downstream phases MUST pin to these)

### Core SDKs
- **Flutter** `3.41.5` stable (bundles **Dart 3.9**) via FVM; commit `.fvmrc`, gitignore `.fvm/`
- **Android**: AGP `8.11.1` / Kotlin `2.2.20` / Gradle `8.14` / **Java 17** / NDK `r28` / Kotlin DSL (`.kts`) for new plugin projects
- **Android SDKs**: `compileSdk 36` / `targetSdk 36` / `minSdk 24` (via `flutter.*` variables, never hard-coded) — verify by running `flutter create` on 3.41 during Phase 1
- **iOS**: Podfile pinned `platform :ios, '15.0'` (Firebase iOS SDK 12.x floor + AppFrameworkInfo.plist also 15); `use_frameworks!` + `use_modular_headers!` on; `BUILD_LIBRARY_FOR_DISTRIBUTION = NO` (breaks Firebase pods if YES); Xcode 16; stay on CocoaPods not SPM this cycle
- **AGP 9 is explicitly paused** in Flutter 3.41 — do not bump

### FlutterFire BoM 4.12.0 (matched set — never mix majors)
| Package | Version |
|---|---|
| `firebase_core` | `^4.7.0` |
| `firebase_auth` | `^6.4.0` |
| `cloud_firestore` | `^6.3.0` |
| `firebase_crashlytics` | `^5.2.0` |
| `firebase_analytics` | `^12.3.0` |
| `firebase_performance` | `^0.11.3` |
| `firebase_app_check` | `^0.4.3` |

### Dart packages
- **State:** `flutter_bloc ^9.1.1` (+ `bloc ^9.0.1`, `bloc_test ^10.0.0`)
- **Routing:** `auto_route ^11.1.0` + `auto_route_generator ^10.5.0` (generator major LAGS runtime — this is correct, not a typo) — **NOT v10** (v10 was transitional)
- **DI:** `get_it ^9.2.1` + `injectable ^2.7.1+4` + `injectable_generator ^2.12.1`
- **Database:** `drift ^2.32.1` + `drift_flutter ^0.3.0` + `sqlite3_flutter_libs ^0.5.36` + `drift_dev ^2.32.1` (runtime and dev versions must match exactly; drift_dev range is `>=2.30.0 <2.33.0`)
- **Preferences:** `shared_preferences ^2.5.5` — use new `SharedPreferencesAsync` API (legacy future-deprecated)
- **Secure storage:** `flutter_secure_storage ^10.0.0`
- **Auth providers:** `google_sign_in ^7.2.0` (stream API: `authenticationEvents.listen(...)`, no more `signIn()`; requires `serverClientId` on Android = Web Client ID, not Android Client ID); `sign_in_with_apple ^7.0.1` (staying CocoaPods; skip `8.0.0-spm`)
- **Animations:** `rive ^0.14.5` (brings `rive_native` transitively) + `flutter_native_splash ^2.4.7`
- **Onboarding helper:** `smooth_page_indicator ^1.1.0` (optional) — no onboarding package
- **Coach marks:** `tutorial_coach_mark ^1.3.3` wrapped in `CoachMarkService`
- **Lints:** `very_good_analysis ^10.2.0` (pin to `analysis_options.10.0.0.yaml` specific file, not floating)
- **i18n:** `intl ^0.20.2`
- **Codegen:** `build_runner ^2.13.1`
- **Tests:** `bloc_test ^10.0.0` + `mocktail ^1.0.5` (not mockito)

### What NOT to use
- `dartz` (unmaintained; use Dart 3 sealed classes)
- `hive` / `objectbox` (dropped for this refresh)
- `fpdart` (overkill — sealed classes cover it)
- `mockito` (use `mocktail`)
- `flutter_lints` (use `very_good_analysis`)
- `rive_splash_screen` (build in-tree with `RiveWidget`)
- `http`, `uuid`, `collection` (declared-but-unused — remove)
- `BUILD_LIBRARY_FOR_DISTRIBUTION = YES` (anti-pattern for standalone Flutter apps)

---

## Feature Landscape

### Table stakes (every production skeleton has these — omitting breaks the value prop)
- Architecture scaffolding (Clean Architecture per feature; Cubit; DI; `auto_route`; reactive data flow) — already in `lib/`, preserved
- **Firebase full wiring** — no stubs; per-flavor `firebase_options_*.dart`; App Check before any service call; Crashlytics via `FlutterError.onError` + `PlatformDispatcher.instance.onError` + isolate listener
- **Auth native setup** — Email+Password / Google / Apple providers; no UI; skeleton ships `AuthService` + `FirebaseAuthService` + README checklist (SHA keys, URL schemes, Apple capability)
- **Flavors (dev/prod only)** — Android productFlavors + iOS schemes + per-flavor Firebase config + dart-entrypoints (`main_dev.dart`, `main_prod.dart`); drive with `flutter_flavorizr` or hand-rolled
- **Bootstrap script** (`tool/bootstrap.dart`) — Dart, idempotent, dry-run mode, whitelisted paths, atomic file writes, prints post-run checklist for interactive steps
- Sealed `Result<T>` + sealed `Failure` hierarchy (replaces `dartz`)
- Localization (ARB + gen_l10n; PL + EN; **switch template to `app_en.arb`**)
- Theme system (add dark theme via `ColorScheme.fromSeed(..., brightness: Brightness.dark)`)
- Logging (`package:logger`, Crashlytics forwarder for `.e`-level)
- Lints (very_good_analysis, errors-not-warnings, exclude generated files)
- **Example test coverage** (counter cubit + counter repository with Drift `NativeDatabase.memory()`) — pattern every future feature copies
- README + UPGRADE playbook (bootstrap flow, architecture conventions, how to re-run the rebase for the next Flutter major)

### Differentiators (value-adds for this author's target apps)
- **RIVE two-stage splash** — native splash covers engine boot → `SplashPage` plays `.riv` state machine while Firebase/DI/Drift init → state-machine "end" trigger navigates to `HomeRoute` (guards branch to `/onboarding` or `/home`). `FlutterNativeSplash.remove()` fires from `SplashPage`'s `addPostFrameCallback`, not `bootstrap.dart`, to eliminate the flash
- **Onboarding feature** — 3-slide `PageView` + dots + skip/next; `hasSeenOnboarding` in `SharedPreferencesAsync`; `OnboardingGuard` on `HomeRoute`
- **Coach mark service** — thin `CoachMarkService` wrapping `tutorial_coach_mark` with `register(tourId, key, description)` + `showTour(tourId)` + `hasSeenTour` in prefs; home FAB demo
- **Firebase App Check** — `AndroidProvider.playIntegrity` / `AppleProvider.appAttest` in release, `.debug` in dev (requires debug token per developer)
- **Global error handler → Crashlytics** — all three hooks (`FlutterError.onError`, `PlatformDispatcher.instance.onError`, `Isolate.addErrorListener`)
- **Per-flavor launcher icons** — banded DEV icon so testers can distinguish builds; `flutter_launcher_icons` + per-flavor config yamls

### Anti-features (out-of-scope by design, confirmed by research)
Login UI · CI/CD · pre-commit hooks · web/desktop scaffolds · staging flavor · anonymous auth · deep linking config · push notification UI · analytics event taxonomy · Riverpod/`go_router` swaps · in-app purchases.

---

## Architecture Shape

### Two-entrypoint flavor design
```
main_dev.dart   → imports firebase_options_dev.dart  → bootstrap(DefaultFirebaseOptions.currentPlatform)
main_prod.dart  → imports firebase_options_prod.dart → bootstrap(DefaultFirebaseOptions.currentPlatform)
bootstrap.dart  → the shared runZonedGuarded + Firebase init + DI + runApp sequence
```
Static imports (not runtime `String.fromEnvironment` branching) — makes Crashlytics symbolication cleaner, matches FlutterFire CLI's expectations, avoids a runtime options `Map`.

### AuthService contract (the central new boundary)
```dart
abstract class AuthService {
  Stream<AuthUser?> get authStateChanges;   // feeds auto_route reevaluateListenable
  AuthUser? get currentUser;

  Future<AuthResult> signInWithEmail({required String email, required String password});
  Future<AuthResult> signUpWithEmail({required String email, required String password});
  Future<AuthResult> signInWithGoogle();
  Future<AuthResult> signInWithApple();
  Future<void> signOut();
  Future<AuthResult> sendPasswordReset({required String email});
}
```
- `AuthUser` is a pure Dart entity, **not** a re-exported `firebase_auth.User` — downstream apps must import zero `firebase_auth` symbols.
- `sealed class AuthResult` with `AuthSuccess(user)` / `AuthFailure(failure)` / `AuthCancelled()` (cancellation is first-class because Google/Apple native sheets routinely back out).
- `@LazySingleton(as: AuthService)` → `FirebaseAuthService(FirebaseAuth.instance)`.

### Sealed `Result<T>` + sealed `Failure`
```dart
sealed class Result<T> { }
final class Success<T> extends Result<T> { final T value; }
final class Failed<T> extends Result<T> { final Failure failure; }

sealed class Failure {
  const Failure(this.message);
  final String message;
}
final class LocalDataNotFoundFailure extends Failure { ... }
final class LocalDataSourceFailure   extends Failure { ... }
final class RemoteFailure            extends Failure { ... }
final class NetworkFailure           extends Failure { ... }
final class AuthFailure              extends Failure { ... }
final class UnexpectedFailure        extends Failure { ... }
```
`final class` on subtypes seals the exhaustiveness guarantee. Consumers use `switch` expressions (not statements) to force compile-time exhaustiveness.

### DI topology
- `@lazySingleton` for `AppDatabase` (Drift), `AuthService`, `PreferencesService`, `SecureStorageService`, `CoachMarkService`, all data sources + repositories + services (fix the "factory everywhere" smell)
- `@injectable` (factory) for Cubits only
- Register externals **before** `$initGetIt(getIt)`: `SharedPreferences.getInstance()`, `FirebaseAuth.instance`, `FirebaseFirestore.instance` — so `@LazySingleton` classes can take them as constructor params

### Initialization sequence
```
1. WidgetsFlutterBinding.ensureInitialized()
2. await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform)
3. await FirebaseAppCheck.instance.activate(...)        ← BEFORE any service call
4. FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError
   PlatformDispatcher.instance.onError = (e, s) { ... recordError ...; return true; }
   Isolate.current.addErrorListener(...)
5. await RiveNative.init()                              ← new in rive 0.14
6. await configureDependencies()                        ← DI with external pre-registrations
7. runApp(const MyApp())                                ← wraps MaterialApp.router(routerConfig: ...)
8. FlutterNativeSplash.remove()                         ← from SplashPage addPostFrameCallback, NOT here
```
Wrap the whole thing in `runZonedGuarded` for async errors outside Flutter's zone.

### Routing + guards
- `AppRouter` extends `RootStackRouter` (no more generated `$AppRouter` in auto_route 11)
- Routes: `SplashRoute` (initial, `/`) → `OnboardingRoute` (`/onboarding`) → `HomeRoute` (`/home`, guarded by `[OnboardingGuard, AuthGuard]`) → `RedirectRoute(path: '*', redirectTo: '/')`
- Guards are `AutoRouteGuard` subclasses with `onNavigation(resolver, router)`:
  - `OnboardingGuard` reads `PreferencesService.hasSeenOnboarding` synchronously
  - `AuthGuard` reads `AuthService.currentUser`
- `MaterialApp.router(routerConfig: appRouter.config(reevaluateListenable: ReevaluateListenable.stream(_authService.authStateChanges)))` — guards re-run on every auth state flip

### File layout (new folders marked)
```
lib/
  main_dev.dart                                 [new]
  main_prod.dart                                [new]
  bootstrap.dart                                [new — shared runZonedGuarded]
  firebase_options_dev.dart                     [generated per flavor]
  firebase_options_prod.dart                    [generated per flavor]
  core/
    injectable/
    database/         [renamed from local_database/] — AppDatabase lives here
    router/ + router/guards/                    [new guards dir]
    errors/           [new — failure.dart, result.dart]
    auth/             [new — AuthService contract, FirebaseAuthService, AuthUser, AuthResult]
    preferences/      [new — PreferencesService, SecureStorageService]
    firebase/         [new — firebase_bootstrap.dart orchestrator]
    coach_mark/       [new — CoachMarkService]
    presentation/     [tokens: app_colors, app_themes (add dark), app_dimensions, app_fonts, app_styles, app_images]
    localization/     [switch template to app_en.arb]
    extensions/
    utils/
  features/
    splash/           [new — RIVE splash page]
    onboarding/       [new — page + cubit + slide widget + repository]
    home_page/        [migrated ObjectBox → Drift]
tool/
  bootstrap.dart + lib/rename_*.dart            [new rename CLI]
test/
  features/home_page/cubit + repository/       [new — example tests]
  helpers/ + fallback_values.dart              [new shared harness]
```

---

## Critical Pitfalls (must-dodge list)

1. **Native rebase wipes custom files silently** — back up first, apply Step-5 bespoke edits from a `rebase_manifest.md` checklist, delete old Kotlin source folder manually, delete `ios/Podfile.lock` + `ios/Pods/` before first post-rebase `pod install`.
2. **Remove ObjectBox *before* installing Drift** — delete `objectbox.g.dart`, `objectbox-model.json`, `@Entity()` imports, the `objectbox: output_dir:` pubspec block, `Pods/ObjectBox`; `flutter clean`; `flutter pub get`; only then wire Drift.
3. **FlutterFire BoM drift = obscure iOS pod errors or Android Duplicate class** — upgrade `firebase_*` as a matched set from official release notes; pin BoM version in a pubspec.yaml comment.
4. **Podfile iOS platform must be `15.0`** — Firebase iOS SDK 12.x mandates it; AppFrameworkInfo.plist must match; do this in lockstep with any future Firebase bump.
5. **Google Sign-In SHA-1 + `serverClientId` = silent `sign_in_failed` code 10** — collect all SHA-1 + SHA-256 per developer × per flavor × Play App Signing key; register in Firebase Console AND Google Cloud OAuth credentials; pass `serverClientId` = **Web Client ID** (not Android client ID) to `GoogleSignIn.initialize()`.
6. **App Check provider mismatch = silent no-protection or dev-only failure** — `.playIntegrity`/`.appAttest` in release, `.debug` in debug; register debug token per developer per flavor in Firebase Console; activate **before** any Firebase service call or Firestore uses an unattested token.
7. **Apple Sign-In capability + Services ID required** — enable "Sign In with Apple" on App ID via Xcode GUI (triggers provisioning regen); persist email+fullName on FIRST sign-in (subsequent sign-ins return null); Apple Review 4.8 makes Apple Sign-In mandatory on iOS if Google is shipped.
8. **auto_route 9→11 is a breaking structural change** — global `AutoRouteGuard implements` no longer supported (move to router `guards` override); `pushNamed`→`pushPath`; `pop`→`maybePop`; generated `$AppRouter` gone (extend `RootStackRouter` directly); regenerate with `--delete-conflicting-outputs`.
9. **`rive` 0.14 needs `await RiveNative.init()` before `runApp()`** — confusing runtime errors on first `.riv` load otherwise; `RiveAnimation`/`Rive` widgets replaced by `RiveWidget`/`RiveWidgetBuilder` + typed `TriggerInput`/`BooleanInput`/`NumberInput`.
10. **Flavors × Firebase = one mis-pathed file breaks everything silently** — flavor names must match across Dart entrypoints, Android productFlavors, iOS schemes, Firebase project registrations; `applicationIdSuffix ".dev"` means Firebase Android app must register `com.example.app.dev` (the suffixed name); commit `.xcscheme` files.

---

## Recommended Phase Shape (8 phases — reconciled)

The three researchers proposed slightly different orderings (ARCHITECTURE.md gave P1→P6; FEATURES.md gave a dependency DAG; PITFALLS.md gave a 6-phase mapping). The reconciled ordering below preserves ARCHITECTURE's critical-path logic, adds FEATURES.md's tests-alongside-migration insight, and front-loads PITFALLS.md's lint cascade so new code is written under strict rules from day one.

### Phase 1 — Native Rebase (alone, must land first)
**Rationale:** Regenerated `android/` + `ios/` change every other file's ground truth; subsequent phases must target the new shape. Also removes web/macos/linux/windows scaffolds and unused deps (`http`, `uuid`, `collection`).
- Backup + `2026-update` branch already in place
- Temp-dir `flutter create` → copy native dirs back → merge pubspec
- Re-apply Step-5 bespoke edits from a `rebase_manifest.md`
- Verify `compileSdk 36 / targetSdk 36 / minSdk 24` from actual `flutter create` output
- Confirm `fvm flutter run --flavor dev` works before any subsequent phase
- **Pitfalls addressed:** Native Rebase Gotchas, Removed platforms leftover refs, Multi-dex sanity check
- **Research flag:** LOW — mechanical procedure documented in ARCHITECTURE.md

### Phase 2 — Lints + Error Handling + Drift (parallel track after P1)
**Rationale:** ARCHITECTURE.md explicitly flags these three as independent (disjoint file sets). Lints go first so P2 code is written against strict rules. Sealed `Result`/`Failure` comes before the counter port. Drift migration closes the objectbox chapter.
- Swap `flutter_lints` → `very_good_analysis ^10.2.0`; exclude generated files; disable `public_member_api_docs`; promote key lints to errors
- Define `sealed class Result<T>` + `sealed class Failure` in `lib/core/errors/`
- Remove ObjectBox completely (files + pubspec + Pods) BEFORE adding Drift
- Wire `AppDatabase` (Drift) + `driftDatabase()` helper; `@DriftDatabase` + `@lazySingleton`
- Migrate `CounterModel` → `CounterTable` + DAO; port repository + cubit to sealed-class `switch`
- Write reference tests: `home_cubit_test.dart` (bloc_test + mocktail) + `counter_repository_test.dart` (Drift `NativeDatabase.memory()` + `closeStreamsSynchronously: true`)
- **Pitfalls addressed:** ObjectBox→Drift semantics, ObjectBox leftover files, dartz→sealed exhaustiveness, very_good_analysis cascade
- **Research flag:** MEDIUM — Drift schema design + migration testing

### Phase 3 — Package Upgrades (flutter_bloc 9, auto_route 11)
**Rationale:** These are structural API changes independent of flavors/Firebase. Keep them contained in one phase so test breakage and codegen churn land together.
- Bump `flutter_bloc ^9.1.1` + `bloc_test ^10.0.0`; remove any `BlocOverrides.runZoned` → `Bloc.observer =`
- Bump `auto_route ^11.1.0` + `auto_route_generator ^10.5.0`; rewrite `AppRouter` to extend `RootStackRouter`; move global guards to router `guards` override; search-and-replace `pushNamed`→`pushPath`, `pop`→`maybePop`
- Regenerate with `--delete-conflicting-outputs`
- Bump `shared_preferences ^2.5.5` (use `SharedPreferencesAsync`), `intl ^0.20.2`, `flutter_secure_storage ^10.0.0`
- **Pitfalls addressed:** flutter_bloc 8→9, auto_route 9→11 codegen
- **Research flag:** LOW — both changelogs are explicit

### Phase 4 — Flavors (dev/prod)
**Rationale:** Blocks P5 (Firebase per-flavor wiring). Native-config heavy; iOS scheme wiring is notoriously finicky — budget extra time.
- Android `productFlavors { dev { applicationIdSuffix ".dev"; resValue("string", "app_name", "Skeleton Dev") } prod { ... } }`
- iOS Xcode schemes `dev` + `prod`; per-scheme `PRODUCT_BUNDLE_IDENTIFIER` + `INFOPLIST_KEY_CFBundleDisplayName`; Run Script copies `FIREBASE_CONFIG_FILE`; commit `.xcscheme` files
- Dart entrypoints `lib/main_dev.dart` + `lib/main_prod.dart` calling shared `bootstrap.dart`
- `lib/core/flavor/flavor_config.dart` (optional) for flavor-aware config selection
- Per-flavor launcher icons via `flutter_launcher_icons-dev.yaml` / `-prod.yaml` + banded dev icon asset
- Release keystore documentation (ship `key.properties.template`, never the real keystore; `.gitignore` entries; README checklist)
- **Pitfalls addressed:** Flavors misconfiguration, Release keystore
- **Research flag:** HIGH — iOS scheme configuration matrix is a common stumbling block

### Phase 5 — Firebase Wiring + AuthService
**Rationale:** Depends on flavors (per-flavor config files + bundle IDs). Firebase + Auth together because AuthService implementation is the consumer of Firebase init.
- FlutterFire BoM 4.12.0 packages; `flutterfire configure` per flavor with all flags (`--project`, `--out`, `--ios-bundle-id`, `--ios-out`, `--android-package-name`, `--android-out`)
- `lib/bootstrap.dart`: binding → `Firebase.initializeApp` → App Check activate → Crashlytics hooks (`FlutterError.onError` + `PlatformDispatcher.instance.onError` + isolate listener) → DI → `runApp`
- `FirebaseAppCheck.instance.activate` with kDebugMode branch
- `lib/core/auth/`: abstract `AuthService` + `AuthUser` entity + sealed `AuthResult` (`AuthSuccess` / `AuthFailure` / `AuthCancelled`) + `FirebaseAuthService` impl (`@LazySingleton(as: AuthService)`)
- Native provider setup: Google SHA-1/SHA-256 per flavor in Firebase Console + Google Cloud OAuth; Apple Services ID; `REVERSED_CLIENT_ID` URL scheme in `Info.plist` per flavor; Apple Sign-In capability in entitlements
- `google_sign_in ^7.2.0` with `serverClientId` (Web Client ID); `sign_in_with_apple ^7.0.1`
- `AuthGuard` reads `AuthService.currentUser`; `reevaluateListenable: ReevaluateListenable.stream(_authService.authStateChanges)` on the router config
- **Pitfalls addressed:** FlutterFire version drift, App Check debug config, Apple Sign-In capability + Services ID, Google Sign-In SHA per flavor
- **Research flag:** HIGH — multi-vendor coordination (Firebase + Google Cloud + Apple Developer + Xcode) with the highest silent-failure surface

### Phase 6 — Onboarding + RIVE Splash
**Rationale:** Both depend on routing + shared_preferences. RIVE splash is the app's first painted frame post-native-splash and its "end" trigger is where `SplashPage` chooses to navigate into `HomeRoute` (guards then branch to onboarding or home). Coach marks wait for P7 since they depend on a settled route tree + preferences.
- `PreferencesServiceImpl(SharedPreferencesAsync)` with `hasSeenOnboarding`
- `OnboardingGuard` on `HomeRoute`
- `OnboardingPage` = 3-slide `PageView` + `smooth_page_indicator` + skip/next; `OnboardingCubit.finish()` writes flag + emits navigation intent
- `flutter_native_splash` config (matched background color with RIVE canvas to eliminate flicker)
- `SplashPage` (`@RoutePage(initial: true)`) with `RiveWidget` + state machine; `FlutterNativeSplash.remove()` from `addPostFrameCallback` on first RIVE frame
- State-machine end trigger → `context.router.replaceAll([const HomeRoute()])`; guards handle the onboarding branch
- Second demo `RiveWidget` on home page showing state-machine input interaction
- **Pitfalls addressed:** RIVE splash flicker
- **Research flag:** MEDIUM — native-to-Flutter splash handoff timing; design a test `.riv` file

### Phase 7 — Coach Marks + Theme Dark Mode
**Rationale:** Coach marks depend on preferences + a settled route tree. Dark theme is independent but small enough to bundle.
- `CoachMarkService` (abstract + impl) with `register(tourId, key, description)` / `showTour(tourId)` / `hasSeenTour` persistence
- Home page demo: register FAB `GlobalKey` in `initState`; `WidgetsBinding.instance.addPostFrameCallback((_) async { ... showTour('home') ... })`
- Add `AppThemes.dark` via `ColorScheme.fromSeed(..., brightness: Brightness.dark)`; `MaterialApp.router(theme, darkTheme, themeMode: ThemeMode.system)`
- **Pitfalls addressed:** tutorial_coach_mark GlobalKey timing
- **Research flag:** LOW — well-documented packages

### Phase 8 — Bootstrap Script + Docs + i18n Cleanup
**Rationale:** Bootstrap is last because it automates the final shape — writing it before flavors/Firebase are stable is wasted effort. Docs come after everything works (and after a smoke-test against a throwaway renamed copy).
- `tool/bootstrap.dart` + composable `tool/lib/rename_*.dart` modules; whitelisted paths (`lib/`, `android/app/`, `ios/Runner*/`, `pubspec.yaml`, `l10n.yaml`, `test/`, `README.md`); atomic file writes; dry-run mode; `git status` check at start; final grep for `com.example.skeleton` residue; post-run checklist
- Switch `l10n.yaml` `template-arb-file: app_en.arb`; fix the missing EN keys (`homePage_decrementButton`, `homePage_error`); add `@@x-source-locale: "en"`
- README: bootstrap flow, per-flavor FlutterFire wiring, architecture conventions, Google+Apple Sign-In provider checklist, App Check debug-token flow
- `UPGRADE.md`: playbook for re-running the rebase on the next Flutter major (what was regenerated vs preserved, what the bootstrap script covers)
- `test/tool/bootstrap_test.dart` fixture-based tests
- **Pitfalls addressed:** Bootstrap script false positives, PL→EN template ARB switch, intl codegen
- **Research flag:** HIGH — bootstrap script is bespoke; needs end-to-end test

### Parallelization opportunities
- After P1: lints + sealed classes + Drift migration can run concurrently (disjoint files)
- During P5: example tests for counter can be written in parallel with Auth provider wiring
- During P6/P7: dark theme + onboarding + RIVE splash touch different subtrees
- During P8: README draft can start during P7

---

## Open Questions Left for Requirements/Roadmap Stage

1. **Firebase config commit policy** — does the template commit placeholder `google-services.json` / `GoogleService-Info.plist` / `firebase_options_*.dart` (convenient but meaningless until `flutterfire configure` runs) or gitignore them entirely (forces every downstream to re-run the CLI as part of bootstrap)? Research suggests the latter for prod and committing for dev, but it's an author-preference call.
2. **Flavor tooling choice** — hand-rolled Android + iOS flavor wiring (full control, more script-maintenance burden) vs. `flutter_flavorizr` (single generator pass, external dep in the skeleton). FEATURES.md leans `flutter_flavorizr`; ARCHITECTURE.md is neutral.
3. **Keystore in the skeleton** — research is emphatic: never ship a real keystore. But what's the README story for per-project keystore generation? Full walkthrough? One-liner `keytool` example? CI-oriented (GitHub Secrets reference)?
4. **Unit test bar** — FEATURES.md recommends both cubit AND repository tests for the counter. Is that the minimum bar, or should there be a widget/integration test too to cover the Drift-reactive-stream → Cubit → UI path end-to-end?
5. **`RIVE Splash` fallback** — what happens if `splash.riv` fails to load (corrupted asset, missing state machine)? Does `SplashPage` fall through to `HomeRoute` after a timeout, or show an error state? Skeleton should probably ship one opinion.
6. **Debug token distribution for App Check** — README documents per-developer token registration, but is there a helper script or a documented "print it once from Xcode console, add here" flow that's more reliable than the Jan-2025 regression where FlutterFire stopped printing the iOS token?
7. **Bootstrap script "safe default bundle"** — if a developer runs the script without `--bundle`, do we fail loudly or default to `com.example.<name>` with a warning? Research suggests fail loudly, but it's UX.
8. **Preserve `.arb` template in Polish, or switch to English?** — PITFALLS.md strongly recommends switching to `app_en.arb` (tooling convention, easier for contributors). Author's current convention is Polish-first. This is an author-preference decision with a clear recommendation from research but no mandate.

---

## Confidence Map

| Dimension | Confidence | Notes |
|---|---|---|
| Flutter 3.41.5 / Dart 3.9 baseline | HIGH | Release notes verified |
| Android toolchain (AGP/Kotlin/Gradle/Java 17/NDK r28) | HIGH | 3.38 + 3.41 release notes cross-referenced |
| `compileSdk/targetSdk/minSdk` exact numbers | MEDIUM | Must verify via Phase 1 `flutter create` diff |
| iOS 15 Podfile floor | HIGH | Firebase iOS SDK 12 mandates; ecosystem aligned |
| FlutterFire BoM 4.12.0 matrix | HIGH | Official release notes 2026-04-13 |
| All Dart package pins | HIGH | Verified on pub.dev at research time |
| `auto_route` 11 (not 10) as landing version | HIGH | Current stable; v10 was transitional |
| `google_sign_in` 7.x stream API + serverClientId | HIGH | Changelog + GitHub issue referenced |
| `rive` 0.14 C++ runtime rewrite | HIGH | Migration blog + pub page verified |
| Drift as ObjectBox replacement | HIGH | Active maintenance, feature parity on reactive streams |
| Firebase full-wiring procedure | HIGH | Official docs via Context7 |
| App Check debug tokens + providers | HIGH | Official Firebase docs; known iOS regression referenced |
| Flavor configuration (Android + iOS) | HIGH | Official Flutter docs; Code with Andrea corroboration |
| AuthService contract shape | HIGH | Synthesized from Code with Andrea + FirebaseAuth docs + `auto_route` reevaluateListenable |
| Sealed Result/Failure pattern | HIGH | Dart language spec + multiple 2024-2026 community articles |
| RIVE + native splash handoff timing | MEDIUM | Multiple community sources agree on `addPostFrameCallback` pattern; no single authoritative source |
| Coach marks service-wrapper pattern | MEDIUM | API confirmed; wrapper shape is our own synthesis |
| Bootstrap script design | MEDIUM | Patterns from `rename` + `change_app_package_name`; no single "best practices" source; end-to-end testing mandatory |
| `flutter_flavorizr` vs hand-rolled flavors | MEDIUM | Both valid; choice is author-preference |
| Overall | **HIGH** | Three blind spots (Phase-1 diff for exact SDKs, RIVE handoff timing, bootstrap script edge cases) all have clear mitigation — spike in the respective phase |

---

## Sources

Aggregated from the four research files. All URLs verified during 2026-04-16 research.

**Flutter + Dart:** Flutter release notes index, Flutter 3.41.0 release notes, Flutter 3.38 recap (Foresight Mobile), Flutter supported platforms, Flutter Android Java Gradle migration, Flutter Gradle plugin imperative apply deprecation, Flutter breaking changes index, Flutter platform integration docs, FVM configuration docs.

**Firebase + FlutterFire:** Firebase SDK for Flutter release notes (BoM 4.12.0), Firebase Crashlytics Flutter get started, Firebase App Check Flutter default + debug providers, Firebase App Check Android Play Integrity, Firebase Auth federated identity, FlutterFire overview + migration + CLI docs, FlutterFire issue #16951 (iOS debug token regression Jan 2025).

**Packages (pub.dev + changelogs):** flutter_bloc, bloc_test, auto_route, auto_route_generator, get_it, injectable, injectable_generator, drift, drift_dev, drift_flutter, shared_preferences, flutter_secure_storage, google_sign_in (+ flutter/flutter#172073 for 7.x serverClientId), sign_in_with_apple, rive, rive_native, flutter_native_splash, tutorial_coach_mark (+ RafaelBarbosatec/tutorial_coach_mark#61), smooth_page_indicator, flutter_flavorizr, intl, build_runner, mocktail, very_good_analysis.

**Official Drift docs:** Simon Binder's setup guide, migrations guide, testing guide, FAQ, Context7 reference.

**Community guides / patterns:** Code with Andrea (flavors, Auth service API, error handling), BLoC migration guide, Tomas Repcik on sealed classes vs Freezed, Rethinking Error Handling in Dart (Medium March 2026), Flutter App Best Practices 2026 (Startup House, Miquido), Dart 3 sealed types feature spec, Material 3 migration docs, `ColorScheme.fromSeed` API, Onboarding Flow with Flutter (Mobile@Exxeta), Adding in-app tours to Flutter apps (OpenReplay), RydMike Flutter linting comparison, Firebase App Security with AppCheck/Play Integrity/App Attest (Medium), GoogleService-Info.plist with iOS flavors (Medium), iOS deployment target Firebase 2025 (Medium), FlutterFlow Apple Sign-In provisioning issues, FilledStacks Sign in with Google or Apple, Paul Senni Flutter Re-create, Deploy Flutter Android App to Play Store 2026 (dev.to), Migrating to Rive Flutter 0.14.0 (dev.to).

**Project context:** `.planning/PROJECT.md`, `.planning/codebase/STACK.md`, `ARCHITECTURE.md`, `STRUCTURE.md`, `CONVENTIONS.md`, `INTEGRATIONS.md`, `TESTING.md`, `CONCERNS.md`.

---

*Synthesis complete: 2026-04-16. SUMMARY.md is the orientation document — downstream agents can read it alone and still build correctly by following the phase ordering and pitfalls list.*
