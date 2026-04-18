<!-- GSD:project-start source:PROJECT.md -->
## Project

**Skeleton — Flutter Mobile App Starter (2026 Refresh)**

A reusable Flutter skeleton the author uses to bootstrap new mobile apps. This milestone refreshes the skeleton against 2026 Flutter tooling: native Android/iOS scaffolding is rebased on Flutter 3.41.5's `flutter create`, key packages are replaced or upgraded (Drift over ObjectBox, Dart 3 sealed classes over `dartz`, `flutter_bloc` 9, `auto_route` 11, RIVE 0.14), Firebase is wired end-to-end on the FlutterFire BoM 4.12.0 matrix (Firebase config files gitignored, configured per-app via FlutterFire CLI after bootstrap), and starter patterns for onboarding, in-app tutorials, and RIVE splash + animations are added. The outcome is a template whose `git clone → bootstrap → flutterfire configure → flutter run` loop lands a production-ready, Firebase-connected iOS + Android app in under 30 minutes.

**Core Value:** Going from `git clone` to a working, Firebase-connected Flutter app on iOS and Android should take minutes, not hours — with a production-grade Clean Architecture already in place. Every decision in this refresh serves that one thing.

### Constraints

- **Tech stack**: Flutter 3.41.5 stable / Dart 3.9, AGP 8.11.1 / Kotlin 2.2.20 / Gradle 8.14 / Java 17 on Android, iOS Podfile floor 15 (Firebase iOS SDK 12.x requires 15)
- **Platforms**: iOS + Android only — other platforms explicitly descoped
- **Languages**: code and documentation in English; user-facing UI localized PL + EN
- **Performance**: skeleton must not regress cold-start relative to the current baseline once Firebase + RIVE + Drift are initialized
- **DX**: `git clone → bootstrap → flutter run` under 30 minutes on a clean machine is the skeleton's reason to exist
- **Compatibility**: the rebase process itself must be repeatable — design bootstrap + rebase so the next Flutter major can replay them without a rewrite
<!-- GSD:project-end -->

<!-- GSD:stack-start source:codebase/STACK.md -->
## Technology Stack

## Languages
- Dart `^3.6.0` - Flutter application code (`lib/`)
- Swift - iOS host application (`ios/Runner/AppDelegate.swift`)
- Kotlin `1.8.22` - Android host application (`android/app/src/main/kotlin/`, plugin declared in `android/settings.gradle`)
- Objective-C - Generated Flutter plugin registrant (`ios/Runner/GeneratedPluginRegistrant.m`)
- Ruby - iOS CocoaPods configuration (`ios/Podfile`)
- Groovy - Android Gradle build scripts (`android/build.gradle`, `android/app/build.gradle`)
## Runtime
- Flutter SDK `3.29.0` (pinned via FVM in `.fvmrc`)
- Dart SDK constraint `^3.6.0` (declared in `pubspec.yaml`)
- Resolved Flutter floor `>=3.24.0` (declared in `pubspec.lock` `sdks` section)
- `.flutter-plugins-dependencies` was generated against Flutter `3.27.1` — there is a drift between `.fvmrc` (3.29.0) and the last `flutter pub get` run
- pub (Dart/Flutter native)
- Lockfile: `pubspec.lock` (present, committed)
- iOS: CocoaPods — `ios/Podfile`, `ios/Podfile.lock` (committed, ~1500 lines, locked to Firebase iOS SDK `11.6.0`)
- Android: Gradle `8.1.0` Android plugin via `dev.flutter.flutter-gradle-plugin` (`android/settings.gradle`)
- Flutter Version Manager (FVM): `.fvmrc` pins `3.29.0`; `.fvm/` directory is git-ignored
## Frameworks
- Flutter `3.29.0` - UI framework, multi-platform (iOS, Android, web, macOS, Linux, Windows enabled)
- `flutter_localizations` (SDK) - Built-in i18n delegates
- `flutter_test` (SDK) - The only test framework declared (`pubspec.yaml`); no test files exist under `test/`
- `build_runner` `^2.4.14` - Code generation orchestrator (`pubspec.yaml`)
- `auto_route_generator` `^9.0.0` - Generates router boilerplate (`lib/core/router/router.gr.dart`)
- `injectable_generator` `^2.6.2` - Generates DI registrations (`lib/core/injectable/injection.config.dart`)
- `objectbox_generator` `any` - Generates ObjectBox bindings (`lib/core/local_database/objectbox.g.dart`, `objectbox-model.json`)
- `flutter_lints` `^5.0.0` - Lint rules referenced by `analysis_options.yaml`
## Key Dependencies
- `flutter_bloc` `^8.1.6` - State management (`bloc` `8.1.4` transitive); used in `lib/features/home_page/presentation/cubit/home_cubit.dart`
- `auto_route` `^9.3.0+1` - Declarative routing wired in `lib/core/router/router.dart`; pages annotated with `@RoutePage()`
- `injectable` `^2.5.0` + `get_it` `8.0.3` - Service locator pattern; configured in `lib/core/injectable/injection.dart`
- `objectbox` `^4.0.3` + `objectbox_flutter_libs` `any` - Local NoSQL persistence; bootstrap in `lib/core/local_database/object_box.dart`, output dir overridden to `core/local_database` in `pubspec.yaml`
- `dartz` `0.10.1` - Functional `Either<Failure, T>` pattern used by repositories and services (`lib/features/home_page/data/repository/counter_repository.dart`)
- `cloud_firestore` `^5.6.1` - Remote NoSQL data store (declared dependency, not yet imported in `lib/`)
- `firebase_core` `^3.10.0` - Firebase initialization base (resolves to native SDK `11.6.0` on iOS)
- `firebase_crashlytics` `^4.3.0` - Crash reporting (wiring stubbed in `lib/startup_service.dart`)
- `firebase_analytics` `^11.4.0` - Analytics (declared, not yet imported in `lib/`)
- `firebase_performance` `^0.10.1` - Performance traces (declared, not yet imported in `lib/`)
- `firebase_app_check` `^0.3.2` - App attestation; wiring stubbed for Play Integrity (Android) and DeviceCheck (Apple) in `lib/startup_service.dart`
- `logger` `^2.5.0` - Structured logging used in `lib/core/router/router.dart` and repositories
- `path_provider` `^2.1.5` - Filesystem paths for ObjectBox store (`lib/core/local_database/object_box.dart`)
- `http` `^1.2.2` - HTTP client (declared, no usage found in `lib/`)
- `uuid` `^4.5.1` - UUID generation (declared, no usage found in `lib/`)
- `collection` `^1.19.0` - Dart collection helpers (declared, no usage found in `lib/`)
- `intl` `^0.19.0` - Drives ARB-generated localizations
- `cupertino_icons` `^1.0.8` - iOS icon glyphs
- `flutter_native_splash` `^2.3.9` (resolved `2.4.4`) - Native splash screen generator
## Configuration
- No `.env` file present; no environment-variable-based configuration in `lib/`
- Firebase initialization is stubbed out in `lib/startup_service.dart` (`_configureFirebase` body commented). Native Firebase config files are absent: no `ios/Runner/GoogleService-Info.plist`, no `android/app/google-services.json`, no `lib/firebase_options.dart`. The README instructs the consumer to wire Firebase via FlutterFire CLI.
- Localization sources: `lib/core/localization/app_pl.arb` (template) and `lib/core/localization/app_en.arb`; output declared in `l10n.yaml` to `app_localizations.dart` consumed via `package:flutter_gen/gen_l10n/app_localizations.dart`
- `analysis_options.yaml` - Inherits `package:flutter_lints/flutter.yaml`; no custom rules enabled
- `l10n.yaml` - `arb-dir: lib/core/localization`, `template-arb-file: app_pl.arb`, `output-localization-file: app_localizations.dart`
- `pubspec.yaml` `flutter:` block - `uses-material-design: true`, `generate: true` (l10n), assets `assets/images/`, `assets/sounds/`, `assets/images/webp/` (asset folders are declared but the `assets/` directory does not exist on disk yet)
- `pubspec.yaml` `objectbox:` block - `output_dir: core/local_database`
- `android/gradle.properties` - `org.gradle.jvmargs=-Xmx4G -XX:MaxMetaspaceSize=2G`, AndroidX + Jetifier enabled
- `android/app/build.gradle` - `namespace = "com.example.skeleton"`, `applicationId = "com.example.skeleton"`, Java/Kotlin target `1.8`, debug signing reused for release builds (TODO marker in file)
- `ios/Podfile` - `platform :ios, '13.0'`, `use_frameworks!`, `use_modular_headers!`
- `ios/Runner/Info.plist` - `CFBundleDisplayName = Skeleton`, all orientations supported, `CADisableMinimumFrameDurationOnPhone = true`
- `.metadata` - Tracks Flutter project revision `17025dd88227cd9532c33fa78f5250d548d87e9a` on `stable` channel
## Platform Requirements
- Flutter SDK `3.29.0` via FVM (`.fvmrc`)
- Xcode with CocoaPods for iOS builds (Podfile uses `flutter_install_all_ios_pods`)
- Android Studio / Android SDK with Gradle `8.1.0` and Kotlin `1.8.22`
- Run `flutter pub get` then `dart run build_runner build --delete-conflicting-outputs` to regenerate `injection.config.dart`, `router.gr.dart`, and `objectbox.g.dart`
- iOS deployment target: 13.0 (`ios/Podfile`)
- Android: `compileSdk` and `minSdk` inherited from Flutter Gradle plugin defaults; AndroidX/Jetifier enabled
- Multi-platform scaffolding present for `web/`, `macos/`, `linux/`, `windows/` (Flutter create defaults; ObjectBox + Firebase plugins claim native builds across all of them per `.flutter-plugins-dependencies`)
- Bundle/application id placeholder: `com.example.skeleton` (must be replaced per project per README)
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

## Lint Configuration
- `package:flutter_lints/flutter.yaml` (via `flutter_lints: ^5.0.0`)
- No custom rules added/removed - the project uses Flutter's recommended defaults out of the box
- No custom analyzer plugins, no `errors:`, `exclude:`, or `analyzer:` overrides defined
- `prefer_const_constructors`, `prefer_const_literals_to_create_immutables` enforced
- `use_super_parameters` enforced (visible in `lib/app.dart:9` -> `MyApp({super.key, ...})`)
- `avoid_print` enabled - use `Logger` from `package:logger` instead (see `lib/features/home_page/data/repository/counter_repository.dart:21`)
- Single quotes are NOT enforced by default (the `prefer_single_quotes` rule is commented out), but the codebase consistently uses single quotes
- `// ignore:` and `// ignore_for_file:` comments are used for generated files (e.g. `injection.config.dart:7,10`)
## Naming Patterns
- Examples: `getCounter()`, `setCounter()`, `watchCounter()`, `initObjectBox()`, `configureDependenciesApp()`, `validateCode`, `getAllPromotions`
- See: `lib/features/home_page/domain/counter_service.dart:10-12`
- Examples: `CounterModel counter`, `Logger logger`, `AppRouter appRouter`, `String userInput`
- See: `lib/main.dart:10` -> `final appRouter = AppRouter();`
- Examples: `isValid`, `isFirstTimeLogin`, `shouldFetchNewData`
- Codebase example: `if (_timer?.isActive ?? false)` in `lib/core/utils/debouncer.dart:12`
## Dart-Style Naming
- `counter_repository.dart`, `counter_local_database.dart`, `home_cubit.dart`, `app_themes.dart`, `context_extension.dart`
- `lib/core/local_database/`, `lib/features/home_page/`, `lib/core/injectable/`
- `CounterRepository`, `HomeCubit`, `MyHomePage`, `AppRouter`, `StartUpService`, `ObjectBox`
- `CounterRepositoryImpl implements CounterRepository` (`lib/features/home_page/data/repository/counter_repository.dart:17`)
- `CounterLocalDataBaseImpl implements CounterLocalDataBase` (`lib/features/home_page/data/local_database/counter_local_database.dart:14`)
- `CounterServiceImpl implements CounterService` (`lib/features/home_page/domain/counter_service.dart:16`)
- `appRouter`, `getCounter`, `_counterService`, `defaultDebounceMilliSeconds`
- `_localDataBase`, `_logger`, `_timer`, `_counterStream`, `_store`, `_configureFirebase()`, `_getCounter()`, `_showErrorSnackBar()`, `_Page` (private widget class)
- `defaultDebounceMilliSeconds = 100` (`lib/core/utils/debouncer.dart:7`)
- `spacingSmall = 4`, `spacingBase = 8`, `radiusMedium = 12` (`lib/core/presentation/app_dimensions.dart`)
- `homePage_title`, `homePage_centeredText`, `homePage_incrementButton`, `homePage_error`
- See `lib/core/localization/app_pl.arb`
## File Organization
- **Data sources** must contain NO business logic - only fetch/persist (`lib/features/home_page/data/local_database/counter_local_database.dart:6`)
- **Repositories** handle errors and convert exceptions to `Failure` instances (`counter_repository.dart:9`)
- **Services** connect multiple repositories, hold non-UI business logic (`counter_service.dart:8`)
- **Cubits** manage UI state and bridge presentation -> domain
- Each layer defines an `abstract class` interface, then `<Name>Impl` for the implementation registered with `@Injectable(as: Name)`
## Import Organization
- Mix of `package:skeleton/...` absolute and `../` relative imports - relative is preferred for siblings within the same feature, absolute for crossing features
- `part`/`part of` used for state classes paired with cubits (`home_cubit.dart:8` <-> `home_state.dart:1`) and generated router (`router.dart:7`)
## Error Handling
- Data sources throw exceptions normally - they do NOT use `Either`
- Repositories MUST catch and translate to `Failure` subtypes
- Services and cubits propagate `Either<Failure, T>` further up
- Always `_logger.e(...)` before returning `Left(...)` so errors are observable
- Never let exceptions escape the repository layer
## Async Patterns
## Class Design
- `const MyApp({super.key, required this.appRouter});` (`lib/app.dart:9`)
- `const Failure(this.message);` (`lib/core/errors/failures.dart:2`)
- `setCounter({required CounterModel counter})` (`counter_repository.dart:38`)
- `MyApp({super.key, required this.appRouter})` (`app.dart:9`)
- `HomeState.copyWith` (`home_state.dart:20-30`)
- `CounterModel.copyWith` (`counter_model.dart:11-17`)
- `HomeState.initial()` (`home_state.dart:10-14`)
- `Failure.localDataNotFound(...)`, `Failure.localDataSource(...)` (`failures.dart:4-5`)
## Widget Patterns
## Logging
- `_logger.e(...)` for caught exceptions in repositories
- `logger.t(...)` for trace-level (route changes in `AppRouterObserver`)
## Dependency Injection
## Generated Code
- `lib/core/injectable/injection.config.dart`
- `lib/core/router/router.gr.dart`
- `lib/core/local_database/objectbox.g.dart`
- `lib/core/localization/app_localizations*.dart` (generated by `flutter_gen` from ARB files)
## Comments
- `lib/startup_service.dart:27-34` lists Firebase setup TODOs
## Localization
## Tooling
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

## Pattern Overview
- Strict 3-layer Clean Architecture per feature: `data` (sources, models, repositories), `domain` (services, entities), `presentation` (pages, cubits, widgets)
- Each layer dependency points inward via abstract classes; concrete implementations are bound via `@Injectable(as: AbstractType)`
- Functional error handling using `dartz` `Either<Failure, T>` returned from repositories upward
- Reactive data via ObjectBox `Stream` watchers consumed by Cubits, which then `emit` immutable state to the UI
- Generated code (`*.g.dart`, `*.gr.dart`, `*.config.dart`) for routing, DI, ObjectBox bindings, and localization
- Firebase scaffolding present but commented out in `lib/startup_service.dart` — wired for opt-in by the consuming project
## Layers
- Purpose: Owns all data acquisition concerns — local DB queries, remote API calls, and translating raw exceptions into typed `Failure` values.
- Location: `lib/features/<feature>/data/`
- Contains:
- Depends on: `lib/core/local_database/object_box.dart`, `lib/core/errors/failures.dart`, `dartz`, `injectable`, `objectbox`
- Used by: Domain services
- Purpose: Business logic that is independent of UI — orchestrates one or more repositories, may apply rules, transformations, or compose data.
- Location: `lib/features/<feature>/domain/`
- Contains:
- Depends on: Repositories (data layer abstractions only), `dartz`, `core/errors`
- Used by: Cubits in the presentation layer
- Purpose: Renders UI, handles user input, manages page-scoped state, navigates.
- Location: `lib/features/<feature>/presentation/`
- Contains:
- Depends on: Domain services (injected into cubits), `flutter_bloc`, `auto_route`, `core/presentation/*`, `core/extensions/context_extension.dart`
- Used by: The `AppRouter` in `lib/core/router/router.dart`
- Purpose: Shared, app-wide infrastructure consumed by all features.
- Location: `lib/core/`
- Contains:
## Data Flow
- `flutter_bloc` `Cubit<State>` per page/feature.
- State is an immutable class with a `factory .initial()` constructor and a `copyWith` method (see `lib/features/home_page/presentation/cubit/home_state.dart`).
- Status surfaces via a `<Feature>PageStatus` enum (`loading`, `success`, `error`, `empty`).
- One-shot navigation intents surface via a `<Feature>PageNavigation` enum (currently only `empty`).
- Cubits are registered as `factory` in DI (`lib/core/injectable/injection.config.dart` shows `gh.factory<HomeCubit>(...)`) and instantiated via `getIt<HomeCubit>()` inside `BlocProvider.create`.
## Key Abstractions
- Purpose: Represents recoverable error states surfaced from data/domain to presentation, decoupling UI from raw exceptions.
- Examples: `lib/core/errors/failures.dart` — `LocalDataNotFoundFailure`, `LocalDataSourceFailure`. New variants are added as factory constructors plus subclasses.
- Pattern: Always wrapped in `dartz` `Left(...)`; consumers `fold` to handle.
- Purpose: Define stable contracts; concrete `*Impl` bound via `@Injectable(as: <Abstract>)` so consumers depend only on the interface.
- Examples: `CounterRepository` (`.../data/repository/counter_repository.dart`), `CounterService` (`.../domain/counter_service.dart`), `CounterLocalDataBase` (`.../data/local_database/counter_local_database.dart`).
- Pattern: Abstract class declares method signatures; impl class is `@Injectable(as: AbstractType)` with constructor injection of upstream dependencies.
- Purpose: One process-wide ObjectBox `Store` initialized at app start, exposed via `ObjectBox.getBox<T>()` and `ObjectBox.store`.
- Examples: `lib/core/local_database/object_box.dart`. Throws `Exception("ObjectBox not initialized...")` if accessed before `initObjectBox()`.
- Pattern: Initialized in `StartUpService._configureDatabases()` before any DI factory that calls `ObjectBox.getBox<T>()` is resolved. Generated bindings live next to it: `objectbox.g.dart`, `objectbox-model.json` (output configured in `pubspec.yaml` under `objectbox: output_dir: core/local_database`).
- Purpose: `auto_route` `RootStackRouter` annotated `@AutoRouterConfig()`; pages register via `@RoutePage()` annotation and appear here as `<Page>Route.page`.
- Examples: `lib/core/router/router.dart` declares `AutoRoute(page: MyHomeRoute.page, path: '/')`. Generated `router.gr.dart` produces `MyHomeRoute`.
- Pattern: Add a new `@RoutePage()` page, run `flutter pub run build_runner build --delete-conflicting-outputs`, then add it to the `routes` list.
- Purpose: `AutoRouterObserver` subclass that logs every `didPush`/`didPop`/`didRemove`/`didStartUserGesture` via the `logger` package.
- Location: `lib/core/router/router.dart`. Attached in `lib/app.dart` via `routerConfig: appRouter.config(navigatorObservers: () => [AppRouterObserver()])`.
- Purpose: Holds all data the UI reads, plus ephemeral `status` / `navigation` enums for side effects.
- Examples: `lib/features/home_page/presentation/cubit/home_state.dart`. `factory HomeState.initial()` provides defaults; `copyWith` is required for emissions.
- Pattern: One state class per Cubit, declared as `part of '*_cubit.dart'`.
## Entry Points
- Triggers: App launch.
- Responsibilities:
- Triggers: Called by `main()` before `runApp`.
- Responsibilities (in order):
- Triggers: Built by `runApp`.
- Responsibilities: Builds `MaterialApp.router` with `appRouter.config(navigatorObservers: () => [AppRouterObserver()])`, registers localization delegates (`AppLocalizations`, `GlobalMaterial`/`Widgets`/`Cupertino`), declares `supportedLocales` `pl` and `en`, applies `AppThemes.light` (Material 3 `ColorScheme.fromSeed(seedColor: AppColors.primary)`).
## Error Handling
- Repository pattern: every public method wrapped in `try { ... return Right(...) } catch (e) { _logger.e(...); return Left(Failure.<variant>(e.toString())); }` — see `lib/features/home_page/data/repository/counter_repository.dart` lines 24–46.
- Stream pattern: `.map((value) { try { ... return Right(...); } catch (...) { return Left(...); } })` — same file lines 49–61.
- Cubit `fold`: `data.fold((failure) => emit(state.copyWith(status: error)), (data) => emit(state.copyWith(status: success, ...)))` — `lib/features/home_page/presentation/cubit/home_cubit.dart` lines 25–35.
- New failure types are added as factory constructors on `Failure` plus a subclass — see `lib/core/errors/failures.dart`.
- Firebase Crashlytics integration is scaffolded (`_configureCrashlytics()` in `lib/startup_service.dart`) to forward `FlutterError.onError` and `PlatformDispatcher.instance.onError` to Crashlytics in release builds — currently commented out pending Firebase setup.
## Cross-Cutting Concerns
- Library: `logger` package.
- Usage: Instantiated locally (`final Logger _logger = Logger();` in repository impls; `Logger(printer: PrettyPrinter(methodCount: 0, noBoxingByDefault: true))` in `AppRouterObserver`).
- README directs project-wide style configuration to `lib/core/utils/logger.dart` (file not yet present in the skeleton — to be created when first needed).
- Repositories log all caught exceptions via `_logger.e(...)` before returning the `Left(Failure)`.
- No formal validation framework in the skeleton. Validation is expected to live in domain services per README convention ("services ... may also handle some business logic which is not related to UI").
- None implemented. Firebase App Check is scaffolded in `lib/startup_service.dart`.
- `intl` + Flutter's `gen_l10n` generator. Source ARB files: `lib/core/localization/app_en.arb`, `lib/core/localization/app_pl.arb`. Configured in `l10n.yaml` (`arb-dir: lib/core/localization`, `template-arb-file: app_pl.arb`, `output-localization-file: app_localizations.dart`). Generated at build time into `flutter_gen/gen_l10n/app_localizations.dart`. Accessed via `context.localizations.<key>` from `lib/core/extensions/context_extension.dart`.
- Key naming: `<feature>_<element>` (e.g. `homePage_title`, `homePage_incrementButton`, `homePage_error`).
- Material 3 light theme generated from `AppColors.primary` seed in `lib/core/presentation/app_themes.dart`. Accessed via `context.theme` extension. Spacing tokens in `AppDimensions` (`lib/core/presentation/app_dimensions.dart`). `AppFonts`, `AppStyles`, `AppImages` are scaffolded but empty — populated per project.
- `get_it` instance singleton in `lib/core/injectable/injection.dart` (`final getIt = GetIt.instance`).
- `@InjectableInit` generates `injection.config.dart` listing all `@Injectable`/`@injectable` classes (currently registers `CounterLocalDataBase`, `CounterRepository`, `CounterService`, `HomeCubit` — all as `factory`).
- Cubits resolved at widget build via `getIt<HomeCubit>()` inside `BlocProvider.create`.
- Run `flutter pub run build_runner build --delete-conflicting-outputs` after adding new annotated classes.
- `auto_route_generator` → `lib/core/router/router.gr.dart` (part-of `router.dart`)
- `injectable_generator` → `lib/core/injectable/injection.config.dart`
- `objectbox_generator` → `lib/core/local_database/objectbox.g.dart`, `objectbox-model.json`
- Flutter `gen_l10n` → `flutter_gen/gen_l10n/app_localizations.dart`
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, or `.github/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
