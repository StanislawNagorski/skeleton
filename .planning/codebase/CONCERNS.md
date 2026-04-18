# Codebase Concerns

**Analysis Date:** 2026-04-16

## Tech Debt

**Firebase initialization is fully commented out:**
- Issue: `_configureFirebase()` does nothing — all Firebase init code is commented out behind `TODO` comments
- Files: `lib/startup_service.dart` (lines 26-35)
- Impact: All declared Firebase dependencies (`firebase_core`, `firebase_crashlytics`, `firebase_performance`, `firebase_analytics`, `firebase_app_check`) are dead code. App ships without crash reporting, analytics, performance tracing, or app integrity checks despite the bundle including all five SDKs (~ several MB extra binary size).
- Fix approach: Either run `flutterfire configure` to generate `firebase_options.dart` and uncomment init blocks, or remove unused Firebase packages from `pubspec.yaml` and convert this into a feature flag/module the consuming app opts into.

**Default `com.example.skeleton` package identifier still in place:**
- Issue: Android namespace, iOS bundle ID, and macOS bundle ID all use `com.example.skeleton`. Android Kotlin folder structure is also at `android/app/src/main/kotlin/com/example/skeleton/MainActivity.kt`.
- Files: `android/app/build.gradle` (lines 9, 24), `ios/Runner.xcodeproj/project.pbxproj`, `macos/Runner.xcodeproj/project.pbxproj`, `android/app/src/main/kotlin/com/example/skeleton/MainActivity.kt`
- Impact: The `// TODO: Specify your own unique Application ID` comment from `flutter create` still ships in `android/app/build.gradle:23`. Each downstream project must remember to do this manually — easy to forget and ship to stores under wrong identifier.
- Fix approach: Add a `tools/rename_app.sh` script (or document `change_app_package_name`/`rename` package usage in README) that automates package rename across Android, iOS, macOS, and pubspec.

**Release build uses debug signing:**
- Issue: `signingConfig = signingConfigs.debug` for release build, with `// TODO: Add your own signing config for the release build.`
- Files: `android/app/build.gradle` (lines 33-39)
- Impact: Skeleton-derived apps will produce unsigned-with-debug-key release builds until manually fixed. Cannot be uploaded to Play Store as-is.
- Fix approach: Document keystore setup in README and provide a `key.properties.template` file plus reading logic in `build.gradle`.

**Many declared dependencies are unused in `lib/`:**
- Issue: `pubspec.yaml` declares packages that are never imported anywhere in `lib/`:
  - `collection` (^1.19.0) — no imports
  - `uuid` (^4.5.1) — no imports
  - `http` (^1.2.2) — no imports
  - `cloud_firestore` (^5.6.1) — no imports
  - `firebase_analytics` (^11.4.0) — no imports
  - `firebase_performance` (^0.10.1) — no imports
  - `flutter_native_splash` (^2.3.9) — no imports, no native splash config block in `pubspec.yaml`
- Files: `pubspec.yaml` (lines 16-50)
- Impact: Bloated dependency tree, slower `pub get`, larger app binary, more potential transitive vulnerability surface, longer build times.
- Fix approach: Either remove from `pubspec.yaml` until needed, or add minimal example feature scaffolding (e.g., a remote data source using `http`, a Firestore example) that demonstrates intended usage so a copy-from-skeleton workflow finds them ready.

**README references packages not in `pubspec.yaml`:**
- Issue: README documents `device_info_plus` (line 92-93) and `get_it` (line 108-109) as direct dependencies, but only `get_it` is pulled in transitively via `injectable`, and `device_info_plus` is not present at all.
- Files: `README.md` (lines 92-93, 108-109), `pubspec.yaml`
- Impact: Misleading onboarding docs; new contributors expect APIs that aren't there.
- Fix approach: Either add the missing packages or remove from README.

**No `flutter_native_splash` configuration block:**
- Issue: Package declared in `pubspec.yaml` but no `flutter_native_splash:` section configures it; assets directory `assets/images/`, `assets/sounds/`, `assets/images/webp/` are listed in `pubspec.yaml` but the directories do not exist.
- Files: `pubspec.yaml` (lines 26, 69-72)
- Impact: `flutter pub get` warning about missing asset directories; running `flutter pub run flutter_native_splash:create` fails with no config.
- Fix approach: Either commit empty `.gitkeep` placeholders inside the asset folders and add a default splash config, or remove the asset entries until needed.

**Default counter app left as the example feature:**
- Issue: The "Skeleton" still ships the Flutter `counter` template feature (`features/home_page`) as the only example. Files: `home_page.dart`, `home_cubit.dart`, `counter_repository.dart`, `counter_local_database.dart`, `counter_service.dart`, `counter_model.dart`.
- Files: `lib/features/home_page/**/*.dart`
- Impact: Every new app derived from the skeleton inherits an unrelated counter feature that must be deleted. The `MyHomeRoute` route, `MyHomePage` widget, and ObjectBox `CounterModel` entity (locked into `objectbox-model.json` IDs) all leak into derived projects.
- Fix approach: Move counter feature into `examples/` or guard it behind a build flavor. Provide a `.template` skeleton structure that shows the pattern without leaking domain code.

**Empty placeholder files in core presentation layer:**
- Issue: Several abstraction files exist but are empty stubs.
  - `lib/core/presentation/app_styles.dart` — empty `AppStyles` class (3 lines of body, 0 members)
  - `lib/core/presentation/app_fonts.dart` — empty `AppFonts` and `AppFontsSizes` classes
  - `lib/core/presentation/app_images.dart` — single private `_path` constant, no public asset references
- Files: `lib/core/presentation/app_styles.dart`, `lib/core/presentation/app_fonts.dart`, `lib/core/presentation/app_images.dart`
- Impact: Files exist as conventions but provide nothing — derived apps must figure out the intended pattern from emptiness. The unused `_path` private field in `app_images.dart` is a lint warning waiting to happen.
- Fix approach: Either commit minimal example entries (e.g., one font family, one TextStyle, one asset path constant) that demonstrate the convention, or remove the files until first real use.

## Known Bugs

**HomeCubit emits `empty` status immediately after every `success`/`error` emission:**
- Symptoms: After the watch stream emits a counter, the cubit emits `success` (or `error`) inside `data.fold`, then unconditionally emits `empty` on the next line — clobbering the status. The snackbar listener in `home_page.dart` therefore never reliably shows the loading or error snackbars on stream updates because the state quickly settles back to `empty`. Also `BlocListener` only fires on state change, so the rapid success → empty transition can suppress UI feedback.
- Files: `lib/features/home_page/presentation/cubit/home_cubit.dart` (lines 23-38, specifically line 36)
- Trigger: Any emission from `_counterService.watchCounter()` (e.g., increment/decrement).
- Workaround: None in code. Remove the trailing `emit(state.copyWith(status: HomePageStatus.empty));` outside the `fold` block, or move it into a place where it's intentional.

**`HomePageStatus.loading` is never emitted:**
- Symptoms: `_showLoadingSnackBar` in `home_page.dart` is unreachable — nothing in `HomeCubit` ever sets status to `loading`.
- Files: `lib/features/home_page/presentation/cubit/home_cubit.dart`, `lib/features/home_page/presentation/home_page.dart` (line 21-23, line 47-58)
- Trigger: N/A — dead code.
- Workaround: Either emit `loading` while the initial `_getCounter()`/`setCounter` calls are in flight, or remove the loading branch.

**Localization key drift between `app_pl.arb` (template) and `app_en.arb`:**
- Symptoms: `app_en.arb` is missing `homePage_decrementButton` and `homePage_error` keys that exist in `app_pl.arb` (the template per `l10n.yaml`). The English version of the app will throw on these missing keys at runtime when used (e.g., decrement tooltip, error snackbar).
- Files: `lib/core/localization/app_en.arb`, `lib/core/localization/app_pl.arb`, `l10n.yaml`
- Trigger: Switching device locale to English and triggering an error or hovering decrement button.
- Workaround: None. Add missing keys to `app_en.arb`. Consider switching `template-arb-file` to `app_en.arb` (English-as-source is the more common default).

**StreamSubscription `_counterStream` is never cancelled:**
- Symptoms: `HomeCubit._counterStream` is assigned but `HomeCubit` overrides no `close()` method to cancel it. Bloc's parent `close()` does not auto-cancel external StreamSubscriptions. Each disposal of `MyHomePage` leaks a subscription that keeps holding a reference to the cubit and the underlying ObjectBox query.
- Files: `lib/features/home_page/presentation/cubit/home_cubit.dart` (line 15, 23-38)
- Trigger: Navigating away from `MyHomePage` (or hot-reloading repeatedly). Less visible because the home is the only route, but will manifest when more pages are added.
- Workaround: None. Override `close()`:
  ```dart
  @override
  Future<void> close() {
    _counterStream?.cancel();
    return super.close();
  }
  ```

**`getCounter()` in data source crashes on empty box:**
- Symptoms: `CounterLocalDataBaseImpl.getCounter()` calls `_counterBox.getAll().first` — `Iterable.first` throws `StateError` on empty collections. The repository wraps this in try/catch and converts to `Failure.localDataSource`, but the contract claims to return `null` when nothing is found (signature is `Future<CounterModel?>`).
- Files: `lib/features/home_page/data/local_database/counter_local_database.dart` (line 19)
- Trigger: First app launch before any counter has been persisted.
- Workaround: The repository swallows the error and returns `Failure.localDataSource`; the cubit then misclassifies a fresh-install state as a data-source error. Replace with `_counterBox.getAll().firstOrNull` (from `package:collection`) or use ObjectBox's query API.

**`@Injectable` on the local data source crashes if registered before ObjectBox init:**
- Symptoms: `CounterLocalDataBaseImpl` initializes `final _counterBox = ObjectBox.getBox<CounterModel>();` at field declaration time. `ObjectBox.getBox` throws "ObjectBox not initialized" if the store isn't open yet. `StartUpService.initServices()` calls `configureDependenciesApp()` BEFORE `_configureDatabases()` — but because the data source is registered as `factory` (not `singleton`), the box is only fetched on first injection. This works today only by accident of ordering: the cubit is first injected on `MyHomePage` build, which is after `runApp()`.
- Files: `lib/features/home_page/data/local_database/counter_local_database.dart` (line 16), `lib/startup_service.dart` (lines 12-16), `lib/core/local_database/object_box.dart` (lines 29-34)
- Trigger: Any change in DI registration to eager singleton, or any pre-runApp injection of `CounterLocalDataBase`.
- Workaround: Either reorder `StartUpService.initServices()` to init databases before DI, or change `CounterLocalDataBaseImpl` to lazily resolve the box per-call (`Box<CounterModel> get _counterBox => ObjectBox.getBox<CounterModel>();`).

**`Right(null)` on `void` return type uses dynamic typing fallback:**
- Symptoms: `setCounter` returns `Right(null)` for `Either<Failure, void>`. With strict null safety this works but produces a `Right<dynamic>` widening — fine for `void` but a smell.
- Files: `lib/features/home_page/data/repository/counter_repository.dart` (line 41), `lib/features/home_page/domain/counter_service.dart` (line 26)
- Trigger: Any call to `setCounter` then attempting to inspect the right side.
- Workaround: Use `const Right<Failure, Unit>(unit)` from `dartz` and change the return type to `Either<Failure, Unit>`.

## Security Considerations

**`firebase_app_check` integration commented out:**
- Risk: When Firebase is eventually wired in, no App Check is enforced — Firebase backends (Firestore, Functions, Storage) are exposed to abuse without device attestation.
- Files: `lib/startup_service.dart` (lines 33, 47-52)
- Current mitigation: None. Code is commented out.
- Recommendations: When Firebase is enabled, ensure App Check activation runs before any Firebase service call. Document App Check console setup in README.

**Crashlytics opt-in is gated to release mode but never enabled:**
- Risk: When Firebase is wired in, debug crashes won't reach Crashlytics, which is fine, but `setCrashlyticsCollectionEnabled(kReleaseMode)` is missing the `await` on `recordError`'s async behavior and assumes the Flutter framework's error pipeline is the only source. `PlatformDispatcher.instance.onError` returns `true`, swallowing errors silently.
- Files: `lib/startup_service.dart` (lines 37-45)
- Current mitigation: None — code is currently commented out.
- Recommendations: When enabling, also wire `runZonedGuarded` for async errors not covered by `PlatformDispatcher` (Isolate errors), and consider not returning `true` from `onError` so the framework's default handling still runs.

**No certificate pinning, no input validation utilities:**
- Risk: `http` package is declared but no networking layer exists. When network code is added, there is no shared HTTP client wrapper enforcing TLS pinning, request timeouts, or interceptors.
- Files: `pubspec.yaml` (line 22), no implementation in `lib/`
- Current mitigation: None.
- Recommendations: Add a `core/network/api_client.dart` that wraps `http` (or migrate to `dio` for interceptor support) with default timeouts, retry policy, and an injection seam for auth headers.

**Read-only `Center` body has no error UI fallback:**
- Risk: When `HomePageStatus.error` fires, the only feedback is an ephemeral snackbar — the page body shows the last-good counter or `0`. A real error path (e.g., DB corruption) silently shows stale data.
- Files: `lib/features/home_page/presentation/home_page.dart` (lines 70-83)
- Current mitigation: SnackBar only.
- Recommendations: Add an `ErrorView` widget pattern in `core/presentation/` that pages render in their `BlocBuilder` body when status is error.

## Performance Bottlenecks

**`getApplicationDocumentsDirectory()` blocks app startup:**
- Problem: `ObjectBox.initObjectBox()` awaits the platform channel call to `getApplicationDocumentsDirectory()` synchronously during `main()` before `runApp()`. On cold start this delays first frame.
- Files: `lib/core/local_database/object_box.dart` (lines 11-16), `lib/main.dart` (lines 7-15)
- Cause: All startup work runs serially in `StartUpService.initServices()` before `runApp`.
- Improvement path: Move ObjectBox init off the critical path — render a splash, then init in parallel, or use `flutter_native_splash` (already declared) to mask startup. Investigate `WidgetsBinding.instance.addPostFrameCallback` for non-essential work.

**`watchCounter()` uses `asyncMap` over `query()` for a single-row table:**
- Problem: Every emission does a fresh `query().findFirst()` even though the entire box only contains one row. The query stream re-fires on every put.
- Files: `lib/features/home_page/data/local_database/counter_local_database.dart` (lines 25-28)
- Cause: ObjectBox does not have a "watch one entity by ID" primitive; the project uses query-based watching.
- Improvement path: Acceptable for a counter. Document for future copies that for high-frequency updates the cubit should debounce with `core/utils/debouncer.dart` (which exists but is unused anywhere — see fragile areas).

## Fragile Areas

**`Debouncer` utility is dead code:**
- Files: `lib/core/utils/debouncer.dart`
- Why fragile: Not consumed anywhere. The class shape (callable via `void call()`, `close()` rather than `dispose()`) sets a convention that nobody is following. Will rot.
- Safe modification: Add at least one consumer (e.g., debounce rapid increment/decrement clicks in `HomeCubit`) or move to a `core/utils/_unused/` directory until needed.
- Test coverage: None — entire `lib/` has zero tests.

**`AppRouterObserver.logRouteChange` parameter ordering quirk:**
- Files: `lib/core/router/router.dart` (lines 20-38)
- Why fragile: `logRouteChange(classOfOrigin, {required Route route, Route? previousRoute})` is called as `logRouteChange(route: ..., previousRoute: ..., this)` — passing `this` as the positional `classOfOrigin`. The `classOfOrigin` parameter has no type annotation (so it's `dynamic`) and the call uses `.runtimeType` on it, which always logs `AppRouterObserver` since `this` is the only call site. Refactoring the observer will silently break logging context.
- Safe modification: Either drop the `classOfOrigin` parameter entirely, or add a type and pass route names instead.
- Test coverage: None.

**`ObjectBox.close()` is never called:**
- Files: `lib/core/local_database/object_box.dart` (lines 36-39)
- Why fragile: The store remains open for the app's lifetime. On Android background termination this is fine, but in tests or hot-reload cycles the store handle leaks and ObjectBox can throw "store already open" errors.
- Safe modification: Hook `close()` into `WidgetsBindingObserver.didChangeAppLifecycleState` or expose via a tear-down method.

**ObjectBox model UIDs hardcoded into the skeleton:**
- Files: `lib/core/local_database/objectbox-model.json`
- Why fragile: The file embeds UIDs for `CounterModel`. Every project copied from this skeleton inherits the same `id`, `lastEntityId`, and `retiredEntityUids` arrays. When derived projects diverge their schema, manual UID surgery becomes risky.
- Safe modification: Strip the counter feature out of the skeleton (see Tech Debt above) so derived projects start with an empty model file generated fresh.

**`@Injectable` factories instantiate per-injection:**
- Files: `lib/core/injectable/injection.config.dart` (lines 32-39)
- Why fragile: `CounterLocalDataBase`, `CounterRepository`, `CounterService`, and `HomeCubit` are all registered as `factory` (per the generated config). Each `getIt<HomeCubit>()` creates a new dependency tree. For a stateful repo backed by ObjectBox this is mostly fine, but the `Logger` instances inside `CounterRepositoryImpl` are recreated every time and the singleton `Logger` from `package:logger` is not used as a shared sink.
- Safe modification: Mark long-lived collaborators (data sources, repositories, services) with `@LazySingleton` or `@Singleton`; leave only cubits as `@injectable`.

## Scaling Limits

**Single-locale source-of-truth design forces translators to update Polish first:**
- Current capacity: Two locales, `pl` (template) and `en`.
- Limit: `l10n.yaml` declares `template-arb-file: app_pl.arb`. As new contributors write keys in English first, they will drift out of sync (already happened — see Bugs above).
- Scaling path: Switch `template-arb-file` to `app_en.arb`, generate `@@x-source-locale: "en"`, and add a CI check `flutter gen-l10n --untranslated-messages-file` to fail on missing translations.

**Single feature module — no example of inter-feature communication:**
- Current capacity: One feature (`home_page`) demonstrating data → domain → presentation.
- Limit: No example of a feature consuming another feature's domain service, or of a shared `core/services/` cross-cutting concern. Future apps will invent their own patterns.
- Scaling path: Add a second example feature that depends on `home_page`'s `CounterService` (or extract a shared `core/auth` example) so the cross-feature DI pattern is documented in code.

## Dependencies at Risk

**Pinned `dartz: 0.10.1` (no caret) and unmaintained:**
- Risk: `dartz` is pinned to an exact version (no `^`), and the package itself has been effectively unmaintained since 2021. Most of the Flutter community has migrated to `fpdart` for functional types.
- Files: `pubspec.yaml` (line 18)
- Impact: Locked into an old API; no Dart 3 record/pattern integrations. Future Dart SDK bumps may break it.
- Migration plan: Replace with `fpdart` (`Either`, `Option`, `TaskEither` are drop-in equivalents with better Dart 3 ergonomics) or with native `sealed class Result` + Dart 3 patterns.

**`auto_route: ^9.3.0+1` (current major is 10.x):**
- Risk: `auto_route` has shipped a v10 with breaking changes around code generation and guards.
- Files: `pubspec.yaml` (line 41)
- Impact: Stuck on outdated routing patterns; no access to newer guard APIs.
- Migration plan: Upgrade to v10, regenerate router, audit `MyHomeRoute` usage in `router.gr.dart`.

**`flutter_bloc: ^8.1.6` (current major is 9.x):**
- Risk: `flutter_bloc` 9.x dropped some deprecated APIs and updates `bloc` core.
- Files: `pubspec.yaml` (line 42)
- Impact: Stuck on prior major; will conflict with newer transitive deps eventually.
- Migration plan: Upgrade to v9, recheck `Cubit.close()` semantics (relevant to the StreamSubscription leak above).

**`intl: ^0.19.0` (Flutter SDK pins newer):**
- Risk: Flutter SDK 3.29+ ships with a newer `intl` and may force a resolver bump.
- Files: `pubspec.yaml` (line 29)
- Impact: Version solving conflicts on newer Flutter channels.
- Migration plan: Bump to `^0.20.0` and re-run code generation.

**`firebase_*` packages declared but no `firebase_options.dart`:**
- Risk: `firebase_core: ^3.10.0` requires `DefaultFirebaseOptions.currentPlatform` to initialize per-platform. This file is generated by `flutterfire configure` and is missing.
- Files: `pubspec.yaml` (lines 45-49), no `lib/firebase_options.dart`
- Impact: Cannot uncomment `Firebase.initializeApp()` in `startup_service.dart` without first running `flutterfire configure`. README does not document this dependency.
- Migration plan: Either run `flutterfire configure` and commit a placeholder `firebase_options.dart` with example projects, or remove Firebase deps from skeleton and document Firebase as a per-project add-on.

**`objectbox: ^4.0.3` (latest is 4.x but Flutter platform deps need careful pairing):**
- Risk: `objectbox_flutter_libs: any` is loose — `any` constraint will pull whatever resolver picks, which can drift between developer machines.
- Files: `pubspec.yaml` (lines 35-36, 61)
- Impact: Reproducibility issues; CI build can pull a newer libs version than developer's machine.
- Migration plan: Pin `objectbox_flutter_libs` and `objectbox_generator` to the same minor as `objectbox`.

**Android Kotlin plugin pinned to 1.8.22:**
- Risk: `android/settings.gradle` pins `org.jetbrains.kotlin.android` to `1.8.22` and `com.android.application` to `8.1.0`. Both are old; modern Flutter projects ship Kotlin 1.9.x+ and AGP 8.4+.
- Files: `android/settings.gradle`
- Impact: Newer Flutter plugins may require newer Kotlin/AGP and fail to build.
- Migration plan: Bump Kotlin to 1.9.22+, AGP to 8.4+, retest Android build.

**iOS minimum deployment target is 13.0 / 12.0:**
- Risk: `ios/Podfile` pins `platform :ios, '13.0'`, but `AppFrameworkInfo.plist` declares `MinimumOSVersion 12.0`. Mismatch can cause Pod install warnings.
- Files: `ios/Podfile`, `ios/Flutter/AppFrameworkInfo.plist`
- Impact: Inconsistent floor; Firebase 11.x requires iOS 13+ which may force the Podfile update anyway.
- Migration plan: Align both to iOS 14 or 15 (Firebase 11 baseline).

## Missing Critical Features

**No environment / build-flavor configuration:**
- Problem: No `--dart-define` plumbing, no `.env` reader, no `flavor`-aware Firebase config switching, no `Environment` enum.
- Blocks: Cannot ship dev/staging/prod variants; must hand-roll secrets injection per derived project.

**No CI/CD configuration:**
- Problem: No `.github/workflows/`, no Codemagic / Bitrise / Fastlane config, no pre-commit hooks.
- Blocks: Every derived project starts with no automated `flutter analyze`, `flutter test`, or build verification.

**No analytics/event-tracking abstraction layer:**
- Problem: `firebase_analytics` is declared but no wrapper exists. Direct SDK calls would couple feature code to Firebase.
- Blocks: Switching analytics providers (Mixpanel, PostHog, Segment) becomes a refactor across every feature.

**No remote data source example / no API client:**
- Problem: README architecture doc describes "remote API data source" as a layer, but the skeleton has zero example. `http` is declared but unused.
- Blocks: New apps invent their own networking patterns each time.

**No theming for dark mode:**
- Problem: `AppThemes` only defines `light`. `MaterialApp.router` does not pass `darkTheme` or `themeMode`. `android/app/src/main/res/values-night/` exists but is not exercised at the Flutter layer.
- Blocks: Dark mode users get a forced light theme; system theme switches are ignored.

**No global error boundary widget:**
- Problem: No `ErrorWidget.builder` override; default red-screen-of-death ships in release builds.
- Blocks: Production crashes show ugly Flutter framework error UI to end users.

**No splash configuration despite `flutter_native_splash` dependency:**
- Problem: Package declared, no `flutter_native_splash:` config block, no splash assets.
- Blocks: Cold start shows white screen until first frame.

## Test Coverage Gaps

**Zero test files anywhere in the project:**
- What's not tested: Everything. There is no `test/` directory, no `integration_test/` directory.
- Files: N/A — entire `lib/` is untested.
- Risk: Refactors of `HomeCubit`, `CounterRepository`, `ObjectBox` wrapper, or routing observer have no safety net. The known bug in `HomeCubit.init()` (status-clobbering emit) would have been caught by a single bloc_test.
- Priority: High. A skeleton project should ship with at least one example unit test per layer (data source, repository, service, cubit) so derived projects inherit testing patterns alongside architecture patterns.

**No `bloc_test` dependency in `dev_dependencies`:**
- What's not tested: Cubit state transitions (specifically `HomeCubit`).
- Files: `pubspec.yaml` (lines 53-63)
- Risk: When tests are added later, contributors won't know whether to use raw `flutter_test`, `bloc_test`, or `mocktail`.
- Priority: High. Add `bloc_test`, `mocktail` (or `mockito`), and a sample test file demonstrating the project's preferred testing style.

**No widget test for `MyHomePage`:**
- What's not tested: Snackbar-on-error path, increment/decrement button behavior, localization rendering.
- Files: `lib/features/home_page/presentation/home_page.dart`
- Risk: The `BlocListener` switch on `HomePageStatus` has unreachable branches (loading) and the localization key drift bug (`homePage_decrementButton`, `homePage_error` missing in EN) would surface here.
- Priority: Medium.

**No integration test for ObjectBox initialization:**
- What's not tested: First-launch persistence flow (the `getCounter` returning `null` vs throwing on empty box).
- Files: `lib/core/local_database/object_box.dart`, `lib/features/home_page/data/local_database/counter_local_database.dart`
- Risk: First-install bug (`Iterable.first` on empty) would only manifest on actual device cold start.
- Priority: Medium.

## Documentation / Onboarding Concerns

**`x_notes.txt` (Polish) records the maintainer's doubt about the project's relevance:**
- Files: `/Users/stanislawnagorski/Developer/WeCodeMobile/skeleton/skeleton/x_notes.txt`
- Content summary: "This project is a skeleton/foundation I created to deliver new mobile apps faster. But it was created some time ago. I'm wondering if it's worth maintaining. Flutter changes its versions often, so generating a project via `flutter new` significantly changes its native integrations."
- Concern: The maintainer explicitly questions whether the skeleton should continue to exist, asking for: package updates, code review, refactor recommendations, in preparation for upcoming new apps.
- Action: This file appears to be a personal note (filename prefixed with `x_`) and likely should be `.gitignore`d. Also add to `.gitignore` if the team uses an `x_*.txt` convention for personal notes.

**README is a mix of English and Polish links:**
- Files: `README.md` (line 45)
- Concern: `https://firebase.google.com/docs/flutter/setup?hl=pl&platform=ios` — the `hl=pl` query param forces Polish docs for an English README.
- Action: Either localize the entire README or remove the language hint.

**README "Changelog" section is stale and tracked manually:**
- Files: `README.md` (lines 134-139)
- Concern: Last entry is `1.0.1` from `13/02/2025`. Manual changelog rot is inevitable.
- Action: Either delete and rely on git tags, or adopt `CHANGELOG.md` + a release-please style automation.

---

*Concerns audit: 2026-04-16*
