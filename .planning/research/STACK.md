# Stack Research — Flutter Mobile Skeleton 2026

**Researched:** 2026-04-16
**Mode:** Ecosystem (hybrid rebase — current state in `.planning/codebase/STACK.md` is the baseline)
**Overall confidence:** HIGH for package versions (verified on pub.dev), MEDIUM for exact Flutter 3.41 native template defaults (verified against release notes and contemporary articles; recommend running `flutter create` on 3.41 to confirm the exact generated files during Phase 1 of the rebase).

## Summary

The 2026 Flutter skeleton should pin to **Flutter 3.41.5 stable (bundling Dart 3.9)** via FVM, with **Android minSdk 24 / compileSdk 36 / targetSdk 36 / AGP 8.11.1 / Kotlin 2.2.20 / Gradle 8.14 / Java 17** and **iOS 15 deployment target** (Firebase 4.x requires ≥13, but the Firebase iOS SDK v12 chain and UIScene lifecycle make 15 the pragmatic floor). Every Dart package on the existing skeleton needs at least a major bump: `flutter_bloc 8 → 9.1.1`, `auto_route 9 → 11.1.0` (v10 was a transitional major, v11 is where the skeleton should land), `objectbox → drift 2.32.1 + drift_flutter 0.3.0`, `dartz → Dart 3 sealed classes`, `flutter_lints → very_good_analysis 10.2.0`, `intl 0.19 → 0.20.2`, `shared_preferences 2.5.5` (using the new `SharedPreferencesAsync` API), and `flutter_secure_storage 10.0.0`. FlutterFire should be pinned as a matched set at BoM 4.12.0 (`firebase_core 4.7.0` + siblings). Rive jumps to `0.14.5` — which is a total runtime rewrite on top of `rive_native` and requires `await RiveNative.init()` at startup plus a widget-API migration.

The most consequential non-version decisions: (1) replace `dartz` with native sealed classes (no new package), (2) replace `ObjectBox` with `drift` + `drift_flutter` + `sqlite3_flutter_libs` (Drift's `driftDatabase()` helper eliminates almost all platform-specific boilerplate), (3) align the iOS Podfile to `platform :ios, '15.0'` even though FlutterFire technically tolerates 13 — staying at 13 forces custom Podfile gymnastics for gRPC/Firestore pods.

## Core SDKs and Versions

### Flutter + Dart

| Component | Pin | Why |
|---|---|---|
| **Flutter SDK** | `3.41.5` (stable) | Latest stable as of 2026-04 per [Flutter release notes](https://docs.flutter.dev/release/release-notes); bumps Dart to 3.9, defaults new plugin projects to Kotlin DSL for Gradle, adds UIScene lifecycle on iOS by default — which Apple will require for iOS 27 submissions. Release posted February 2026. |
| **Dart SDK constraint** | `sdk: ^3.9.0` in `pubspec.yaml` | Bundled with Flutter 3.41 per [3.41 release notes PR #179041](https://docs.flutter.dev/release/release-notes/release-notes-3.41.0). Sealed classes / records / pattern matching all stabilized in Dart 3.0+; no reason to pin lower. |
| **FVM** | latest (`fvm` 4.x) with `.fvmrc` committed | Existing skeleton already uses FVM correctly. Keep `.fvmrc` committed, keep `.fvm/` gitignored, keep `.flutter-plugins-dependencies` generated against the same version as `.fvmrc` (the current drift from 3.27.1→3.29.0 is a bug to fix in the rebase). Recommended `.fvmrc` flags: `"runPubGetOnSdkChanges": true`, `"updateVscodeSettings": true`, `"updateGitIgnore": true` per [FVM configuration docs](https://fvm.app/documentation/getting-started/configuration). |

**Confidence:** HIGH (Flutter 3.41.5 confirmed, Dart 3.9 confirmed).

### Android (AGP, Gradle, Kotlin, compileSdk, minSdk)

| Setting | Value | Source / Why |
|---|---|---|
| **AGP** | `8.11.1` | Flutter 3.38+ toolchain floor per [Foresight blog](https://foresightmobile.com/blog/flutter-3-38-dart-3-10-november-2025-update); Flutter 3.41 still supports this baseline (AGP 9 support is **paused** per the 3.41 blog post — explicitly do **not** bump to AGP 9 yet). |
| **Kotlin Gradle Plugin** | `2.2.20` | Floor for Flutter 3.38+; Flutter 3.41 plugin projects default to Kotlin DSL for Gradle. |
| **Gradle wrapper** | `8.14` (minimum `8.13`) | Matched to AGP 8.11.1 + Java 17. |
| **Java** | `17` | Flutter 3.38 made Java 17 the minimum; the existing skeleton's `sourceCompatibility = 1.8` is broken for modern Flutter. |
| **compileSdk** | `flutter.compileSdkVersion` → **36** | Flutter 3.41 bumped default compileSdk to API 36 (Android 16). Always use the Flutter-managed variable, never hard-code. |
| **targetSdk** | `flutter.targetSdkVersion` → **36** | Google Play requirement: new submissions since Aug 2025 require targetSdk 35; apps rebuilt since Feb 2025 already target 36. Pin to the Flutter default which matches compile. |
| **minSdk** | `flutter.minSdkVersion` → **24** (Android 7.0) | Flutter 3.41 supported platform floor is API 24 per [Flutter supported platforms](https://docs.flutter.dev/reference/supported-platforms). `firebase_auth` needs minSdk 23+, `flutter_secure_storage` needs 23+ — 24 clears both. |
| **NDK** | `27.0.12077973` (or `r28` for 16KB page support) | Flutter 3.38 made NDK r28 the default. Google Play requires NDK r28+ for new native-code submissions starting May 2026. |
| **Build DSL** | **Kotlin DSL** (`.gradle.kts`) | Flutter 3.41 new plugin projects default to Kotlin DSL. App projects from `flutter create` on 3.41 also generate `.kts`. Embrace it — matches Android Studio ergonomics, type-safe. |
| **Signing** | keystore from `android/key.properties` (gitignored) + committed `android/key.properties.template` | Existing skeleton ships debug-signed release builds (see CONCERNS.md); fix in the rebase. |

**Confidence:** HIGH for the floors (pubspec package floors + Flutter 3.38 release notes); MEDIUM for the exact `compileSdk 36` default — this is what `flutter create` on 3.41 generates but the skeleton must verify by running it during Phase 1.

### iOS (Podfile, deployment target, Xcode)

| Setting | Value | Why |
|---|---|---|
| **`platform :ios`** in `Podfile` | `'15.0'` | FlutterFire 4.x technically allows iOS 13, but: (a) Firebase iOS SDK 12.x requires iOS 15, (b) gRPC-Core pods inside `cloud_firestore` regularly push the floor higher and break builds on 13/14, (c) iOS 15 is the 2026-realistic baseline (iOS 15 shipped Sep 2021, 4.5 years ago). The existing skeleton is pinned at 13.0 with `AppFrameworkInfo.plist` declaring 12.0 — both wrong for 2026. |
| **`use_frameworks!`** | keep enabled | Required by Firebase pods. |
| **`use_modular_headers!`** | keep enabled | Required by Firebase / gRPC on iOS for Swift module imports. |
| **`post_install` hook** | standard Flutter `flutter_additional_ios_build_settings(target)` + explicit `IPHONEOS_DEPLOYMENT_TARGET = 15.0` override per target | Overrides silence the "X pod requires higher deployment target" warnings Firebase consistently throws. |
| **`BUILD_LIBRARY_FOR_DISTRIBUTION`** | **NOT** set (leave default `NO`) | Only needed when shipping the Flutter module as an xcframework to a host iOS app. A standalone Flutter app (this skeleton's case) must not enable it — it triggers Swift module-stability requirements that break several Firebase pods. Document this as an anti-pattern. |
| **Xcode** | 16.x (CI), 15.4+ minimum dev | Xcode 16 is the Apple floor for App Store submissions in 2026. |
| **Swift Package Manager** | **opt-in, not default** | Flutter 3.41 is "continuing the long-term shift" to SPM but CocoaPods is still the default and the ecosystem (FlutterFire, many plugins) is still CocoaPods-first. Do **not** enable SPM for the 2026 refresh — revisit in the next Flutter major. |
| **UIScene lifecycle** | let Flutter 3.41's auto-migration handle `Info.plist` | Flutter 3.41 ships UIScene support by default; required for iOS 27 per Apple. No manual Info.plist surgery needed. |

**Confidence:** HIGH on the 15.0 floor (Firebase iOS 12.x documented floor + community issue patterns); HIGH on `BUILD_LIBRARY_FOR_DISTRIBUTION` being wrong for standalone apps.

## Dart Packages

### State Management (flutter_bloc 9)

| Package | Pin | Why |
|---|---|---|
| `flutter_bloc` | `^9.1.1` | Current stable per [flutter_bloc changelog](https://pub.dev/packages/flutter_bloc/changelog). 9.0.0 renamed `cubit:` → `bloc:` in `BlocConsumer`/`BlocBuilder`/`BlocListener`, added the `mounted` safeguard in `BlocListener`, dropped `BlocOverrides`. 9.1.0 added `dispose` on `RepositoryProvider`. 9.1.1 fixes `BlocSelector` rebuild-on-selector-change. |
| `bloc` | `^9.0.1` (transitive) | Locked to `flutter_bloc` 9. |
| `bloc_test` | `^10.0.0` (dev) | Required for bloc 9. |

**Migration cost from existing skeleton:** trivial — `HomeCubit` uses `Cubit`, not `Bloc`, and `BlocBuilder<HomeCubit, HomeState>` form does not need renaming. The main gain is the `mounted` check inside `BlocListener`, which directly mitigates the "status-clobbering emit" bug noted in `.planning/codebase/CONCERNS.md`.

### Routing (auto_route 10)

| Package | Pin | Why |
|---|---|---|
| `auto_route` | `^11.1.0` | **Note:** the question asks about auto_route 10, but the current stable is 11.1.0 (published Dec 2025). v10 was a transitional major; v11 is where active development sits. Land on 11, not 10, per [auto_route changelog](https://pub.dev/packages/auto_route/changelog). |
| `auto_route_generator` | `^10.5.0` (dev) | Pairs with auto_route ^11.1.0; the generator's own major version lags the runtime's, which is confusing but correct. |

**Key breaking changes from 9 → 11 (affecting existing `lib/core/router/router.dart`):**
- Global guards now done via overriding `guards` property on the `AutoRouter` subclass; implementing `AutoRouteGuard` globally no longer supported.
- `AutoRouterConfig.module` removed (not used in existing skeleton — non-issue).
- `PageRouteInfo` equality no longer compares args by default — add `argsEquality: true` in the `@AutoRouterConfig` annotation only if the existing code relies on arg equality (it does not; single route currently).
- `appBarBuilder` is nullable in `AutoTabsScaffold` (non-issue — not used).
- Deep-link routes without host no longer auto-handled (non-issue — no deep linking in skeleton).

**Migration cost:** low. Regenerate router; the existing `AppRouter` + single `MyHomeRoute` will transplant cleanly.

### DI (get_it + injectable)

| Package | Pin | Why |
|---|---|---|
| `get_it` | `^9.2.1` | Current stable per pub.dev. injectable 2.7+ allows `>=8.3.0 <10.0.0`. |
| `injectable` | `^2.7.1+4` | Current stable. Supports LeanBuilder (faster codegen) in generator 2.12+. |
| `injectable_generator` | `^2.12.1` (dev) | Pairs with injectable 2.7.x; unlocks LeanBuilder. |

**Migration cost:** trivial (existing skeleton uses these at slightly older versions); run build_runner. Recommendation: fix the "factory everywhere" smell from `.planning/codebase/CONCERNS.md` by switching data sources / repositories / services to `@LazySingleton` during the refresh; only cubits stay `@injectable`.

### Local Database (drift + drift_flutter)

| Package | Pin | Why |
|---|---|---|
| `drift` | `^2.32.1` | Current stable per [drift pub page](https://pub.dev/packages/drift). Active maintenance, strongly typed, reactive streams via `.watch()`. |
| `drift_flutter` | `^0.3.0` | Provides the `driftDatabase(name: ...)` helper — eliminates platform-specific boilerplate for opening the SQLite connection on iOS, Android, macOS, Linux, Windows, web. Per [drift setup docs](https://drift.simonbinder.eu/setup/), this is the 2026 recommended path. |
| `sqlite3_flutter_libs` | `^0.5.36` | Bundles a recent SQLite3 on Android; Drift's recommended companion for the modern pipeline (vs. `moor_ffi` or the system SQLite). |
| `path_provider` | `^2.1.5` | Already in skeleton; drift_flutter still needs it. |
| `drift_dev` | `^2.32.1` (dev) | Codegen — must match the `drift` runtime version exactly (drift_dev declares `drift >=2.30.0 <2.33.0`). |

**Recommended database pattern (per drift docs):**
```dart
@DriftDatabase(tables: [CounterItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'skeleton_db',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
    );
  }
}
```

**Reactive pattern (direct replacement for ObjectBox's `watch()`):**
```dart
Stream<Counter?> watchCounter() =>
    (select(counterItems)..limit(1)).watchSingleOrNull();
```

**Code generation workflow:**
- One-shot: `dart run build_runner build --delete-conflicting-outputs`
- Watch mode during dev: `dart run build_runner watch --delete-conflicting-outputs`
- Output: `database.g.dart` next to `database.dart` (no project-specific output_dir override needed, unlike `objectbox`)

**Migration cost from ObjectBox:** MEDIUM. The schema is trivial (single `CounterModel`), but every data-source, repo, cubit, and test needs a rewrite. Because ObjectBox's `objectbox-model.json` UIDs were locked into the skeleton (see CONCERNS.md), this switch also fixes the "derived projects inherit the same UIDs" fragility.

### Preferences & Secure Storage

| Package | Pin | Why |
|---|---|---|
| `shared_preferences` | `^2.5.5` | Use the **new `SharedPreferencesAsync` API**, not the legacy `SharedPreferences.getInstance()`. The legacy API is marked for future deprecation per the [shared_preferences docs](https://pub.dev/packages/shared_preferences): *"We highly encourage any new users of the plugin to use the newer SharedPreferencesAsync or SharedPreferencesWithCache APIs instead."* For the skeleton's onboarding flag use case, `SharedPreferencesAsync` is the right pick — no cache warm-up required, multi-isolate-safe. |
| `flutter_secure_storage` | `^10.0.0` | Current stable. Android floor: API 23 (covered by minSdk 24). iOS: keychain-access-groups entitlement must be correct or writes silently fail — document this in the README. For the skeleton, use default options (`AndroidOptions(encryptedSharedPreferences: true)`, `IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device)`) as sane defaults. |

**Pattern:**
```dart
// Preferences (onboarding flag, theme mode, locale override)
final _prefs = SharedPreferencesAsync();
await _prefs.setBool('hasSeenOnboarding', true);

// Secure storage (auth tokens, refresh tokens)
const _secure = FlutterSecureStorage();
await _secure.write(key: 'auth_token', value: token);
```

### Firebase (compatibility matrix)

Pin all Firebase packages as a **matched set from FlutterFire BoM 4.12.0** (released 2026-04-13, the freshest at the time of this research — per [Firebase Flutter release notes](https://firebase.google.com/support/release-notes/flutter)):

| Package | Version (BoM 4.12.0) |
|---|---|
| `firebase_core` | `^4.7.0` |
| `firebase_auth` | `^6.4.0` |
| `cloud_firestore` | `^6.3.0` |
| `firebase_crashlytics` | `^5.2.0` |
| `firebase_analytics` | `^12.3.0` |
| `firebase_performance` | `^0.11.3` |
| `firebase_app_check` | `^0.4.3` |

**Compatibility constraints (all packages in this BoM):**
- Dart SDK: `>=3.2.0 <4.0.0`
- Flutter SDK: `>=3.3.0` (firebase_auth needs `>=3.16.0`)
- Android: `minSdk 21` (auth needs `minSdk 23`) → our `minSdk 24` is fine
- iOS: backed by Firebase iOS SDK 12.x which mandates iOS 15+

**Critical pitfall:** Firebase packages must be upgraded as a matched BoM, not individually. Mixing `firebase_core 4.7` with `firebase_auth 5.x` produces obscure runtime errors or iOS pod resolution failures. The BoM version in the Firebase release notes is the authoritative source. During `flutter pub upgrade`, use `--major-versions` on the whole Firebase group together.

**`firebase_options.dart`:** generate per flavor via `flutterfire configure --yes --project=<dev-project> --out=lib/firebase_options_dev.dart` and `--project=<prod-project> --out=lib/firebase_options_prod.dart`. Commit both. Select at runtime from flavor entry points (`main_dev.dart`, `main_prod.dart`).

**App Check in 2026:** `AppCheckProvider.playIntegrity` on Android (requires Play Integrity API enabled in Google Cloud), `AppCheckProvider.deviceCheck` on iOS (free, or DeviceCheck App Attest for stronger guarantees). Debug provider for local development must register a debug token in the Firebase console — do not ship debug provider to release builds.

**Crashlytics wiring (critical — fix the existing broken pattern):**
```dart
FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};
// Also wrap async outer zones for isolate errors
Isolate.current.addErrorListener(RawReceivePort((pair) async {
  final [error, stack] = pair as List<dynamic>;
  await FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
}).sendPort);
```

### Auth (google_sign_in, sign_in_with_apple)

| Package | Pin | Why |
|---|---|---|
| `google_sign_in` | `^7.2.0` | **Major 7.x API rewrite** per [google_sign_in pub page](https://pub.dev/packages/google_sign_in) — stream-based (`GoogleSignIn.instance.authenticationEvents.listen(...)`), no more `signIn()`; use `initialize()`, `attemptLightweightAuthentication()` (silent), and `authenticate()` (interactive). Requires explicit clientId config on iOS via `GoogleService-Info.plist` + URL scheme. |
| `sign_in_with_apple` | `^7.0.1` | Current stable. An 8.0.0-spm prerelease exists (SPM migration) but we're staying on CocoaPods this cycle — pin to 7.0.1. |

**Native setup the skeleton must pre-solve (per the PROJECT.md Core Value of minimizing per-app setup):**
- **Android:** SHA-1 + SHA-256 fingerprints per flavor in Firebase console, `google-services.json` per flavor in `android/app/src/{dev,prod}/`, `applicationIdSuffix ".dev"` in debug.
- **iOS:** `GoogleService-Info.plist` per flavor in `ios/Runner/Firebase/{dev,prod}/`, Xcode build phase script to copy the right plist per configuration, URL schemes in `Info.plist` for Google (`REVERSED_CLIENT_ID`), `Sign in with Apple` capability enabled in Runner target (`Runner.entitlements`).
- **Firebase Auth providers** enabled in console: Email/Password, Google, Apple.

No login UI — skeleton exposes a `FirebaseAuthService` wrapper and each target app builds its own screen (per PROJECT.md Out of Scope).

### Animations (rive) + Splash

| Package | Pin | Why |
|---|---|---|
| `rive` | `^0.14.5` | Current stable per [rive pub page](https://pub.dev/packages/rive). **This is a total runtime rewrite** — 0.14 ditches the old Dart-based runtime and calls into the Rive C++ runtime via the new `rive_native` package. |
| `rive_native` | transitive via `rive` | Do not depend on directly; `rive` pulls the right version. |
| `flutter_native_splash` | `^2.4.7` | Current stable. For the split splash strategy (native splash → RIVE animated splash → first frame), `flutter_native_splash:create` generates Android 12+ splash-screen API assets + legacy `launch_background.xml` + iOS `LaunchScreen.storyboard`. |

**Breaking changes from 0.13 → 0.14** (affect skeleton):
- Must call `await RiveNative.init()` in `main()` before `runApp()`.
- Old widgets (`Rive`, `RiveAnimation`) replaced with `RiveWidget`/`RiveWidgetBuilder`.
- State machine controllers replaced with typed inputs: `TriggerInput`, `BooleanInput`, `NumberInput`.

**`flame_rive`:** do **not** use. It's a `flame` game-engine integration package, unrelated to plain Flutter app animations. Not applicable here.

**Recommended splash flow (per PROJECT.md's "animated RIVE splash post-native splash" requirement):**
1. `flutter_native_splash` shows the static logo during Flutter engine initialization (~200-800ms).
2. First Flutter route is a `SplashRoute` that:
   - Runs app startup (Firebase init, DI, Drift warm-up).
   - Plays a `.riv` state-machine animation (e.g., logo morph → ready trigger).
   - On the state machine's `ready` trigger, navigates to `/home` or `/onboarding` depending on `hasSeenOnboarding`.
3. `rive_splash_screen` package is an option but adds a dependency for what `RiveWidget` can do in ~50 lines — skip it.

### Onboarding helpers

**No package** per PROJECT.md Key Decisions — `PageView` + a dots indicator is ~100 lines. Recommended minimal ingredients:
- `PageView.builder` for slides
- `smooth_page_indicator` (`^1.1.0`) **only if** the team wants Material-style animated dots; otherwise a custom `Row` of `AnimatedContainer` dots is fine. Pick one and document it.
- `hasSeenOnboarding` bool in `SharedPreferencesAsync`.
- `auto_route` guard: `OnboardingGuard implements AutoRouteGuard` — redirects to `/onboarding` when the flag is false.

**Confidence:** HIGH (this is table-stakes Flutter UI — any package here adds risk without benefit).

### tutorial_coach_mark

| Package | Pin | Why |
|---|---|---|
| `tutorial_coach_mark` | `^1.3.3` | Current stable. Author's prior experience; maintained. |

Wrap in a thin `CoachMarkService` (per PROJECT.md Key Decisions) with `register(key, description)` + `showTour()`. A single example tour on the counter FAB demonstrates the API.

### Lints (very_good_analysis)

| Package | Pin | Why |
|---|---|---|
| `very_good_analysis` | `^10.2.0` (dev) | Current stable per [very_good_analysis pub page](https://pub.dev/packages/very_good_analysis). Stricter than `flutter_lints`; Very Good Ventures maintained. |

**`analysis_options.yaml`:**
```yaml
include: package:very_good_analysis/analysis_options.10.0.0.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    # Promote common smells to errors so CI fails fast
    unused_import: error
    unused_local_variable: error
    avoid_print: error
    missing_return: error
    dead_code: error
  exclude:
    - "**/*.g.dart"
    - "**/*.gr.dart"
    - "**/*.freezed.dart"
    - "**/generated_plugin_registrant.dart"
    - "lib/core/localization/app_localizations.dart"
```

Pinning to the `analysis_options.10.0.0.yaml` specific file (rather than the floating `analysis_options.yaml`) guards against a silent lint rule bump breaking a downstream project on an unrelated `flutter pub upgrade`.

### Localization (intl + l10n)

| Package | Pin | Why |
|---|---|---|
| `intl` | `^0.20.2` | Current stable; Flutter 3.41's SDK-pinned `intl` resolves to 0.20+. The existing 0.19 is now floor-blocked. |
| `flutter_localizations` | SDK (not pubspec-pinned) | Built-in delegates. |

**`l10n.yaml`:**
```yaml
arb-dir: lib/core/localization
template-arb-file: app_en.arb  # switch template to EN per CONCERNS.md recommendation
output-localization-file: app_localizations.dart
output-class: AppLocalizations
nullable-getter: false
```

**Fix from existing skeleton:**
- Switch `template-arb-file` from `app_pl.arb` → `app_en.arb` (English-as-source is the industry convention and stops the PL-first drift that currently desyncs EN).
- Add the two missing keys to `app_en.arb` per CONCERNS.md.
- Regenerate via `flutter gen-l10n` (now bundled with Flutter; no extra step).

### Code Generation (build_runner)

| Package | Pin | Why |
|---|---|---|
| `build_runner` | `^2.13.1` (dev) | Current stable. |
| `drift_dev` | `^2.32.1` (dev) | See Drift section. |
| `injectable_generator` | `^2.12.1` (dev) | See DI section. |
| `auto_route_generator` | `^10.5.0` (dev) | See Routing section. |

**Workflow command aliases (document in README + optionally in a `Makefile` / `melos`):**
- `bootstrap`: `fvm flutter pub get && dart run build_runner build --delete-conflicting-outputs && fvm flutter gen-l10n`
- `watch`: `dart run build_runner watch --delete-conflicting-outputs`
- `clean`: `fvm flutter clean && dart run build_runner clean`

**Testing deps (added — CONCERNS.md flags zero coverage):**

| Package | Pin | Why |
|---|---|---|
| `bloc_test` | `^10.0.0` (dev) | Required for bloc 9; canonical for cubit state-transition testing. |
| `mocktail` | `^1.0.5` (dev) | Null-safe, code-gen-free mocking. Preferred over `mockito` for 2026 — no build_runner annotations. |
| `flutter_test` | SDK (dev) | Built-in. |
| `integration_test` | SDK (dev) | Add for the counter integration test (Drift + cubit end-to-end). |

## What NOT to Use (deprecated / risky)

| Package | Why avoid | What to use instead |
|---|---|---|
| **`dartz`** | Effectively unmaintained since 2021; no Dart 3 record/pattern integrations; pinned exact version in existing skeleton is a red flag. | **Native Dart 3 sealed classes + pattern matching.** `sealed class Result<T> { }` + `final class Success<T> extends Result<T>` + `final class Failure<T> extends Result<T> { final DomainFailure failure; }`. Consumers use `switch (result) { case Success(:final value): ...; case Failure(:final failure): ...; }`. Zero dependencies. |
| **`hive` / `hive_flutter`** | Core author stepped back; `hive_ce` is a community fork but both lack the ergonomics of a proper query layer. The author's own experience (per PROJECT.md Context) drove away from Hive. | **`drift` + `drift_flutter`**. |
| **`objectbox`** | Niche, unfamiliar to author (explicit PROJECT.md rationale); `objectbox_flutter_libs: any` constraint in the existing skeleton is a reproducibility risk; model UIDs locked into the skeleton contaminate every derived project. | **`drift`**. |
| **`fpdart`** | Technically alive and a valid `dartz` replacement, but imports a whole functional-style library for a single use case that sealed classes cover natively. Adds onboarding friction for anyone not already fluent in functional idioms. | Sealed classes (as above). If specifically needed later for `Option` / `Task` / `ReaderTaskEither` patterns, `fpdart ^1.1.1` is fine — but the skeleton doesn't need it. |
| **`mockito`** | Requires build_runner annotations; slower feedback loop; redundant when `mocktail` is available. | `mocktail`. |
| **`flutter_lints`** | Too permissive for a skeleton that is supposed to set the bar. | `very_good_analysis`. |
| **`go_router`** | Fine package, but the skeleton commits to `auto_route` per PROJECT.md Key Decisions (code generation parity with DI, better type safety, more mature guard semantics for the onboarding + auth flows the skeleton needs). Do not mix routers. | `auto_route`. |
| **`riverpod` / `provider` / `get`** | State management is `flutter_bloc` per PROJECT.md; no mixing. | `flutter_bloc`. |
| **`rive_splash_screen`** | Thin wrapper over the main `rive` package; adds a dep for ~50 lines of code. | Build the splash in-tree with `RiveWidget` and a state machine trigger. |
| **`flutter_spinkit`** (if tempted for the splash loading state) | Unnecessary — the RIVE animation IS the loading state. | RIVE state machine. |
| **`device_info_plus`** (referenced in current README but not in pubspec) | Not needed in the base skeleton. Derived apps add it when they need device fingerprinting / ID. | Per-app add-on. |
| **`http`** (declared but unused in existing skeleton) | Per PROJECT.md active items — remove. Remote data is Firestore in the baseline. | Add `dio ^5.x` per-app when REST is actually needed. |
| **`uuid`, `collection`** (declared but unused) | Per PROJECT.md active items — remove. | Add per-feature when needed. |
| **`BUILD_LIBRARY_FOR_DISTRIBUTION = YES`** (iOS Podfile) | Only applies to Flutter-module-as-framework scenarios; breaks Firebase pods due to Swift module-stability requirements. | Leave default (`NO`). |

## Key Compatibility Pitfalls

1. **FlutterFire BoM drift** — the highest-frequency support issue. Always upgrade `firebase_*` packages as a matched set from the [official Firebase Flutter release notes](https://firebase.google.com/support/release-notes/flutter). Mixing majors = obscure iOS pod errors or Android `Duplicate class` exceptions. Pin the BoM version in a comment in `pubspec.yaml`.

2. **iOS Podfile vs. Firebase deployment target mismatch** — the existing skeleton has `platform :ios, '13.0'` in Podfile but `MinimumOSVersion 12.0` in `AppFrameworkInfo.plist`. Fix both to `15.0` in the rebase. Any time Firebase iOS SDK bumps its floor (Firebase iOS 12 → 15 minimum), every Flutter skeleton / app must bump Podfile in lockstep or `pod install` will emit warnings that later manifest as `gRPC-Core requires higher iOS deployment target`.

3. **AGP vs. Flutter vs. Kotlin triangle** — the existing skeleton's AGP 8.1.0 + Kotlin 1.8.22 is below the Flutter 3.38 floor (AGP 8.11.1 + Kotlin 2.2.20). Bumping Flutter without bumping these produces cryptic `Module compiled with an incompatible version of Kotlin` errors. Always bump the triangle together. **Do not bump to AGP 9** (Flutter 3.41 explicitly pauses AGP 9 support).

4. **Drift version ↔ drift_dev version must match exactly** — drift_dev pins a narrow range (currently `>=2.30.0 <2.33.0`). A `dart pub upgrade` on `drift` without matching `drift_dev` breaks codegen. Pin both to the same `^2.32.1`.

5. **auto_route runtime-generator major asymmetry** — `auto_route ^11.1.0` pairs with `auto_route_generator ^10.5.0`. The generator major lags the runtime major. Always check the generator's `auto_route` dependency constraint in pub.dev before bumping.

6. **`rive` 0.14 requires `await RiveNative.init()`** — forgetting this in `main()` produces confusing runtime errors on first `.riv` load. The skeleton's `StartUpService.initServices()` must call this before `runApp()`.

7. **`google_sign_in` 7.x API is stream-based** — any code copied from pre-7.x examples will not compile. Document the new pattern in the skeleton's auth example.

8. **`shared_preferences` legacy API is future-deprecated** — use `SharedPreferencesAsync` in new code. Don't mix the legacy and async APIs in the same app.

9. **`flutter_secure_storage` on iOS silently drops writes if keychain-access-groups entitlement is wrong** — the skeleton's iOS entitlements files must declare the right keychain access group, and the bootstrap script must rename it per target app. This is exactly the kind of pre-solved native pain the skeleton exists for.

10. **Flutter Gradle plugin imperative apply deprecation** — the existing skeleton's `settings.gradle` uses the newer declarative form already, but the rebase must confirm the `flutter create` 3.41 output matches per [this breaking change doc](https://docs.flutter.dev/release/breaking-changes/flutter-gradle-plugin-apply).

11. **`intl` SDK pin conflict** — Flutter 3.41 ships a bundled `intl`; pinning `^0.19.0` in pubspec triggers version resolution failure. Bump to `^0.20.2`.

12. **Google Play NDK r28 requirement (May 2026)** — new Play submissions with native code (which includes every Flutter app) must use NDK r28+ for 16KB page support. Flutter 3.38+ defaults to r28, so staying on Flutter 3.41 covers this automatically. Older Flutter versions don't.

## Confidence Levels

| Area | Confidence | Basis |
|---|---|---|
| Dart package versions (all) | **HIGH** | Every version verified directly on pub.dev individual package pages during this research (fetched April 2026). |
| FlutterFire BoM 4.12.0 matrix | **HIGH** | Verified against official [Firebase Flutter release notes](https://firebase.google.com/support/release-notes/flutter), dated 2026-04-13. |
| Flutter 3.41.5 as current stable | **HIGH** | Verified against Flutter docs release-notes page. |
| Dart 3.9 bundled with Flutter 3.41 | **HIGH** | Confirmed in Flutter 3.41 release notes PR #179041. |
| Android AGP 8.11.1 / Kotlin 2.2.20 / Gradle 8.14 / Java 17 floors | **HIGH** | Flutter 3.38 release notes + Foresight Mobile 2025-11 retrospective + 3.41 article confirmations. |
| `compileSdk 36 / targetSdk 36 / minSdk 24` | **MEDIUM** | Flutter 3.41 is documented to bump defaults but exact numbers vary by source (35 vs 36). Phase 1 of the rebase must verify by running `flutter create` on 3.41 and diffing. The Flutter-managed variable `flutter.compileSdkVersion` makes this self-correcting. |
| iOS 15 deployment target recommendation | **HIGH** | Backed by Firebase iOS SDK 12 floor + ecosystem signals (iOS 15 shipped 4.5 years ago). |
| Flutter 3.41 iOS Podfile default | **MEDIUM** | Not independently verified; Flutter's default may still be `12.0` or `13.0` in the generated Podfile — rebase should check and override to 15 explicitly. |
| AGP 9 guidance ("do not use yet") | **HIGH** | Explicit in Flutter 3.41 blog post. |
| Drift as ObjectBox replacement | **HIGH** | Active maintenance (drift_dev 24 days old at research time), documented 2026 setup, matches skeleton's reactive-data pattern natively. |
| `flutter_bloc 9` API changes | **HIGH** | Verified on pub.dev changelog and corroborated by multiple migration guides. |
| `auto_route 11` breaking changes from v9 | **HIGH** | Verified on pub.dev changelog. |
| `google_sign_in 7` stream-based API | **HIGH** | Verified on pub.dev; migration guide explicit. |
| `rive 0.14` runtime rewrite | **HIGH** | Verified on pub.dev and migration blog post. |
| `sign_in_with_apple 7.0.1` as stable pick (vs 8.0-spm prerelease) | **HIGH** | Staying on CocoaPods this cycle per Flutter 3.41's SPM "long-term shift" stance. |

### Gaps to address during rebase (Phase 1)

- Run `fvm flutter create .` on Flutter 3.41.5 in a scratch directory and diff the generated `android/app/build.gradle.kts`, `ios/Podfile`, `ios/Runner/Info.plist` against current to confirm exact `compileSdk` / `targetSdk` / `minSdk` / Podfile platform default numbers.
- Verify that `flutterfire configure` in 2026 still generates per-flavor-compatible `firebase_options.dart` or if the CLI has changed — this is high-risk because it wires every downstream app.
- Verify that Drift 2.32 + Firebase 4.x + Flutter 3.41 coexist in a single `pub get` without version resolution loops (most likely — all three target Dart 3.x+ — but untested combination).

---

## Sources

- [Flutter release notes index](https://docs.flutter.dev/release/release-notes) — confirmed 3.41.5 current stable.
- [Flutter 3.41.0 release notes](https://docs.flutter.dev/release/release-notes/release-notes-3.41.0) — Dart 3.9 bump.
- [What's new in Flutter 3.38 / Foresight Mobile, Nov 2025](https://foresightmobile.com/blog/flutter-3-38-dart-3-10-november-2025-update) — AGP 8.11.1 / Kotlin 2.2.20 / Gradle 8.14 floors.
- [Flutter supported platforms](https://docs.flutter.dev/reference/supported-platforms) — iOS 13 / Android API 24 minimums.
- [Firebase SDK for Flutter release notes](https://firebase.google.com/support/release-notes/flutter) — BoM 4.12.0 matrix.
- [flutter_bloc changelog](https://pub.dev/packages/flutter_bloc/changelog) — 9.1.1 current.
- [auto_route changelog](https://pub.dev/packages/auto_route/changelog) — 11.1.0 current; 10.x breaking changes.
- [auto_route_generator pub page](https://pub.dev/packages/auto_route_generator) — 10.5.0 current, pairs with auto_route ^11.1.0.
- [drift pub page](https://pub.dev/packages/drift) — 2.32.1 current.
- [drift_dev pub page](https://pub.dev/packages/drift_dev) — 2.32.1 current, requires drift >=2.30.0 <2.33.0.
- [drift_flutter pub page](https://pub.dev/packages/drift_flutter) — 0.3.0 current.
- [Drift setup guide](https://drift.simonbinder.eu/setup/) — 2026 recommended setup.
- [injectable pub page](https://pub.dev/packages/injectable) — 2.7.1+4 current, requires get_it >=8.3.0 <10.0.0.
- [injectable_generator pub page](https://pub.dev/packages/injectable_generator) — 2.12.1 current.
- [get_it pub page](https://pub.dev/packages/get_it) — 9.2.1 current.
- [very_good_analysis pub page](https://pub.dev/packages/very_good_analysis) — 10.2.0 current.
- [shared_preferences pub page](https://pub.dev/packages/shared_preferences) — 2.5.5 current; legacy API deprecation notice.
- [flutter_secure_storage pub page](https://pub.dev/packages/flutter_secure_storage) — 10.0.0 current.
- [google_sign_in pub page](https://pub.dev/packages/google_sign_in) — 7.2.0 current; stream-based API.
- [sign_in_with_apple pub page](https://pub.dev/packages/sign_in_with_apple) — 7.0.1 current stable.
- [rive pub page](https://pub.dev/packages/rive) — 0.14.5 current; rive_native dependency.
- [rive_native pub page](https://pub.dev/packages/rive_native) — 0.1.5 current; helper library.
- [Migrating to Rive Flutter 0.14.0 / dev.to](https://dev.to/uianimation/migrating-to-rive-flutter-0140-5d74) — RiveNative.init() and widget API migration.
- [flutter_native_splash pub page](https://pub.dev/packages/flutter_native_splash) — 2.4.7 current; Android 12+ splash API.
- [tutorial_coach_mark pub page](https://pub.dev/packages/tutorial_coach_mark) — 1.3.3 current.
- [intl pub page](https://pub.dev/packages/intl) — 0.20.2 current.
- [build_runner pub page](https://pub.dev/packages/build_runner) — 2.13.1 current.
- [bloc_test pub page](https://pub.dev/packages/bloc_test) — 10.0.0 current.
- [mocktail pub page](https://pub.dev/packages/mocktail) — 1.0.5 current.
- [FVM configuration docs](https://fvm.app/documentation/getting-started/configuration) — .fvmrc recommended flags.
- [FlutterFire migration guide](https://firebase.flutter.dev/docs/migration/) — 3→4 upgrade steps.
- [Rethinking Error Handling in Dart / Medium March 2026](https://medium.com/@naman.kashyap12/rethinking-error-handling-in-dart-mastering-the-result-either-pattern-d04b659c977a) — sealed-class Result pattern.
- [Deploy Flutter Android App to Play Store 2026 / dev.to](https://dev.to/dharanidharan_d_tech/deploy-your-flutter-android-app-to-play-store-in-2026-step-by-step-guide-with-code-gotchas-n2k) — 2026 Play Store SDK requirements.
- [Flutter Android Java Gradle migration guide](https://docs.flutter.dev/release/breaking-changes/android-java-gradle-migration-guide) — Java 17 requirement.
- [Flutter Gradle plugin imperative apply deprecation](https://docs.flutter.dev/release/breaking-changes/flutter-gradle-plugin-apply) — declarative apply is the 2026 form.

*Research complete: 2026-04-16*
