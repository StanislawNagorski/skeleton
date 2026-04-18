# Architecture

**Analysis Date:** 2026-04-16

## Pattern Overview

**Overall:** Clean Architecture (3-layer) + Feature-First organization + Cubit (BLoC) state management

This is a Flutter app skeleton/template (`pubspec.yaml` name: `skeleton`, version `1.0.1+2`) intended as a starting point for new projects. It implements a strict Clean Architecture with three layers (data, domain, presentation), wires components together via dependency injection (`get_it` + `injectable`), and ships a single working example feature (`home_page` counter) that demonstrates the full data flow from a local NoSQL database (ObjectBox) to the UI.

**Key Characteristics:**
- Strict 3-layer Clean Architecture per feature: `data` (sources, models, repositories), `domain` (services, entities), `presentation` (pages, cubits, widgets)
- Each layer dependency points inward via abstract classes; concrete implementations are bound via `@Injectable(as: AbstractType)`
- Functional error handling using `dartz` `Either<Failure, T>` returned from repositories upward
- Reactive data via ObjectBox `Stream` watchers consumed by Cubits, which then `emit` immutable state to the UI
- Generated code (`*.g.dart`, `*.gr.dart`, `*.config.dart`) for routing, DI, ObjectBox bindings, and localization
- Firebase scaffolding present but commented out in `lib/startup_service.dart` — wired for opt-in by the consuming project

## Layers

**Data Layer:**
- Purpose: Owns all data acquisition concerns — local DB queries, remote API calls, and translating raw exceptions into typed `Failure` values.
- Location: `lib/features/<feature>/data/`
- Contains:
  - `model/` — Persistence/wire data classes annotated with ObjectBox `@Entity()` (e.g. `lib/features/home_page/data/model/counter_model.dart`)
  - `local_database/` (or `remote/`) — Data sources implementing an `abstract class` interface, no business logic (e.g. `lib/features/home_page/data/local_database/counter_local_database.dart`)
  - `repository/` — Implements an abstract repository, wraps data source calls in `try/catch`, returns `Either<Failure, T>` (e.g. `lib/features/home_page/data/repository/counter_repository.dart`)
- Depends on: `lib/core/local_database/object_box.dart`, `lib/core/errors/failures.dart`, `dartz`, `injectable`, `objectbox`
- Used by: Domain services

**Domain Layer:**
- Purpose: Business logic that is independent of UI — orchestrates one or more repositories, may apply rules, transformations, or compose data.
- Location: `lib/features/<feature>/domain/`
- Contains:
  - `services/` (or service files) — Abstract `*Service` + `*ServiceImpl` annotated with `@Injectable(as: ...)` (e.g. `lib/features/home_page/domain/counter_service.dart`)
  - `entities/` — Pure business objects exposed to presentation. (Currently the skeleton reuses `CounterModel` directly as both model and entity for simplicity; the README prescribes separate `entities/` for real features.)
- Depends on: Repositories (data layer abstractions only), `dartz`, `core/errors`
- Used by: Cubits in the presentation layer

**Presentation Layer:**
- Purpose: Renders UI, handles user input, manages page-scoped state, navigates.
- Location: `lib/features/<feature>/presentation/`
- Contains:
  - `<feature>_page.dart` — `StatelessWidget` annotated `@RoutePage()` for `auto_route` (e.g. `lib/features/home_page/presentation/home_page.dart`)
  - `cubit/` — `Cubit<State>` subclasses annotated `@injectable` plus a `part`-linked `*_state.dart` file with an immutable state class and `enum`s for `status` / `navigation` (e.g. `lib/features/home_page/presentation/cubit/home_cubit.dart`, `lib/features/home_page/presentation/cubit/home_state.dart`)
  - `widgets/` — Reusable widgets (not yet present in the example feature; reserved by README convention)
- Depends on: Domain services (injected into cubits), `flutter_bloc`, `auto_route`, `core/presentation/*`, `core/extensions/context_extension.dart`
- Used by: The `AppRouter` in `lib/core/router/router.dart`

**Core Layer (cross-cutting infrastructure):**
- Purpose: Shared, app-wide infrastructure consumed by all features.
- Location: `lib/core/`
- Contains:
  - `injectable/` — `get_it` + `injectable` setup (`lib/core/injectable/injection.dart`, generated `injection.config.dart`)
  - `local_database/` — Singleton ObjectBox `Store` wrapper (`lib/core/local_database/object_box.dart`) and generated bindings (`objectbox.g.dart`, `objectbox-model.json`)
  - `router/` — `auto_route` `RootStackRouter` and observer (`lib/core/router/router.dart`, generated `router.gr.dart`)
  - `errors/` — `Failure` type hierarchy used by all repositories (`lib/core/errors/failures.dart`)
  - `presentation/` — App-wide design tokens: `app_themes.dart`, `app_colors.dart`, `app_dimensions.dart`, `app_fonts.dart`, `app_styles.dart`, `app_images.dart`
  - `extensions/` — `BuildContext` helpers (`lib/core/extensions/context_extension.dart` exposes `context.localizations` and `context.theme`)
  - `localization/` — ARB translation files (`app_en.arb`, `app_pl.arb`); generated into `flutter_gen/gen_l10n/app_localizations.dart` per `l10n.yaml`
  - `utils/` — Generic helpers (`lib/core/utils/debouncer.dart`)

## Data Flow

**Read flow (Counter example, reactive):**

1. UI builds `MyHomePage` (`lib/features/home_page/presentation/home_page.dart`) which provides a `HomeCubit` via `BlocProvider(create: (context) => getIt<HomeCubit>()..init())`.
2. `HomeCubit.init()` (`lib/features/home_page/presentation/cubit/home_cubit.dart`) calls `_counterService.getCounter()`; if no counter exists it seeds one with `setCounter(...)`.
3. `HomeCubit.init()` subscribes to `_counterService.watchCounter()` (a `Stream<Either<Failure, CounterModel>>`).
4. `CounterServiceImpl` (`lib/features/home_page/domain/counter_service.dart`) delegates to `CounterRepository`.
5. `CounterRepositoryImpl` (`lib/features/home_page/data/repository/counter_repository.dart`) maps the data-source stream, converting `null`/exceptions into `Left(Failure.localDataNotFound(...))` / `Left(Failure.localDataSource(...))` and successes into `Right(counter)`.
6. `CounterLocalDataBaseImpl` (`lib/features/home_page/data/local_database/counter_local_database.dart`) calls `_counterBox.query().watch(triggerImmediately: true).asyncMap(...)` against the ObjectBox `Box<CounterModel>`.
7. Cubit `fold`s the `Either` and `emit`s `HomeState` with `HomePageStatus.success | error`.
8. `BlocBuilder<HomeCubit, HomeState>` rebuilds the counter `Text` (`buildWhen` filters to `counter.value` changes); `BlocListener` reacts to `status` changes by showing snackbars.

**Write flow:**

1. User taps the FloatingActionButton → `context.read<HomeCubit>().increment()`.
2. Cubit copies the current `state.counter` with an incremented `value` and calls `_counterService.setCounter(counter: updatedData)`.
3. Service → repository → data source → `_counterBox.put(counter)` writes to ObjectBox.
4. The ObjectBox `watch()` stream from step 6 above emits the new value, which flows back into the Cubit and triggers a rebuild. Writes and reads share one reactive loop.

**State Management:**
- `flutter_bloc` `Cubit<State>` per page/feature.
- State is an immutable class with a `factory .initial()` constructor and a `copyWith` method (see `lib/features/home_page/presentation/cubit/home_state.dart`).
- Status surfaces via a `<Feature>PageStatus` enum (`loading`, `success`, `error`, `empty`).
- One-shot navigation intents surface via a `<Feature>PageNavigation` enum (currently only `empty`).
- Cubits are registered as `factory` in DI (`lib/core/injectable/injection.config.dart` shows `gh.factory<HomeCubit>(...)`) and instantiated via `getIt<HomeCubit>()` inside `BlocProvider.create`.

## Key Abstractions

**`abstract class Failure` (typed error envelope):**
- Purpose: Represents recoverable error states surfaced from data/domain to presentation, decoupling UI from raw exceptions.
- Examples: `lib/core/errors/failures.dart` — `LocalDataNotFoundFailure`, `LocalDataSourceFailure`. New variants are added as factory constructors plus subclasses.
- Pattern: Always wrapped in `dartz` `Left(...)`; consumers `fold` to handle.

**`abstract class <Feature>Repository` / `<Feature>Service` / `<Feature>LocalDataBase`:**
- Purpose: Define stable contracts; concrete `*Impl` bound via `@Injectable(as: <Abstract>)` so consumers depend only on the interface.
- Examples: `CounterRepository` (`.../data/repository/counter_repository.dart`), `CounterService` (`.../domain/counter_service.dart`), `CounterLocalDataBase` (`.../data/local_database/counter_local_database.dart`).
- Pattern: Abstract class declares method signatures; impl class is `@Injectable(as: AbstractType)` with constructor injection of upstream dependencies.

**`ObjectBox` (singleton store wrapper):**
- Purpose: One process-wide ObjectBox `Store` initialized at app start, exposed via `ObjectBox.getBox<T>()` and `ObjectBox.store`.
- Examples: `lib/core/local_database/object_box.dart`. Throws `Exception("ObjectBox not initialized...")` if accessed before `initObjectBox()`.
- Pattern: Initialized in `StartUpService._configureDatabases()` before any DI factory that calls `ObjectBox.getBox<T>()` is resolved. Generated bindings live next to it: `objectbox.g.dart`, `objectbox-model.json` (output configured in `pubspec.yaml` under `objectbox: output_dir: core/local_database`).

**`AppRouter` (declarative routes):**
- Purpose: `auto_route` `RootStackRouter` annotated `@AutoRouterConfig()`; pages register via `@RoutePage()` annotation and appear here as `<Page>Route.page`.
- Examples: `lib/core/router/router.dart` declares `AutoRoute(page: MyHomeRoute.page, path: '/')`. Generated `router.gr.dart` produces `MyHomeRoute`.
- Pattern: Add a new `@RoutePage()` page, run `flutter pub run build_runner build --delete-conflicting-outputs`, then add it to the `routes` list.

**`AppRouterObserver` (navigation logging):**
- Purpose: `AutoRouterObserver` subclass that logs every `didPush`/`didPop`/`didRemove`/`didStartUserGesture` via the `logger` package.
- Location: `lib/core/router/router.dart`. Attached in `lib/app.dart` via `routerConfig: appRouter.config(navigatorObservers: () => [AppRouterObserver()])`.

**`HomeState` (immutable state contract):**
- Purpose: Holds all data the UI reads, plus ephemeral `status` / `navigation` enums for side effects.
- Examples: `lib/features/home_page/presentation/cubit/home_state.dart`. `factory HomeState.initial()` provides defaults; `copyWith` is required for emissions.
- Pattern: One state class per Cubit, declared as `part of '*_cubit.dart'`.

## Entry Points

**`main()` — `lib/main.dart`:**
- Triggers: App launch.
- Responsibilities:
  1. `WidgetsFlutterBinding.ensureInitialized()`
  2. `await StartUpService.initServices()` (Firebase placeholder, DI, ObjectBox)
  3. Construct `AppRouter`
  4. `runApp(MyApp(appRouter: appRouter))`

**`StartUpService.initServices()` — `lib/startup_service.dart`:**
- Triggers: Called by `main()` before `runApp`.
- Responsibilities (in order):
  1. `_configureFirebase()` — currently a no-op stub with TODOs to enable `Firebase.initializeApp`, Crashlytics (`_configureCrashlytics()`), and App Check (`_configureAppCheck()` for `playIntegrity` / `deviceCheck` in release, `debug` providers otherwise)
  2. `_configureDependencies()` → `configureDependenciesApp()` from `lib/core/injectable/injection.dart`, which calls the generated `$initGetIt(getIt)`
  3. `_configureDatabases()` → `ObjectBox.initObjectBox()` opens the store at the app documents directory (`path_provider.getApplicationDocumentsDirectory()`)

**`MyApp` — `lib/app.dart`:**
- Triggers: Built by `runApp`.
- Responsibilities: Builds `MaterialApp.router` with `appRouter.config(navigatorObservers: () => [AppRouterObserver()])`, registers localization delegates (`AppLocalizations`, `GlobalMaterial`/`Widgets`/`Cupertino`), declares `supportedLocales` `pl` and `en`, applies `AppThemes.light` (Material 3 `ColorScheme.fromSeed(seedColor: AppColors.primary)`).

## Error Handling

**Strategy:** Functional error handling with `dartz` `Either<Failure, T>` returned from every data-layer call upward. Exceptions are caught at the repository boundary and converted to `Failure` subtypes. Cubits `fold` the `Either` to emit a success state or an error status; the page widget reacts to `state.status == HomePageStatus.error` to surface UI feedback (snackbars).

**Patterns:**
- Repository pattern: every public method wrapped in `try { ... return Right(...) } catch (e) { _logger.e(...); return Left(Failure.<variant>(e.toString())); }` — see `lib/features/home_page/data/repository/counter_repository.dart` lines 24–46.
- Stream pattern: `.map((value) { try { ... return Right(...); } catch (...) { return Left(...); } })` — same file lines 49–61.
- Cubit `fold`: `data.fold((failure) => emit(state.copyWith(status: error)), (data) => emit(state.copyWith(status: success, ...)))` — `lib/features/home_page/presentation/cubit/home_cubit.dart` lines 25–35.
- New failure types are added as factory constructors on `Failure` plus a subclass — see `lib/core/errors/failures.dart`.
- Firebase Crashlytics integration is scaffolded (`_configureCrashlytics()` in `lib/startup_service.dart`) to forward `FlutterError.onError` and `PlatformDispatcher.instance.onError` to Crashlytics in release builds — currently commented out pending Firebase setup.

## Cross-Cutting Concerns

**Logging:**
- Library: `logger` package.
- Usage: Instantiated locally (`final Logger _logger = Logger();` in repository impls; `Logger(printer: PrettyPrinter(methodCount: 0, noBoxingByDefault: true))` in `AppRouterObserver`).
- README directs project-wide style configuration to `lib/core/utils/logger.dart` (file not yet present in the skeleton — to be created when first needed).
- Repositories log all caught exceptions via `_logger.e(...)` before returning the `Left(Failure)`.

**Validation:**
- No formal validation framework in the skeleton. Validation is expected to live in domain services per README convention ("services ... may also handle some business logic which is not related to UI").

**Authentication:**
- None implemented. Firebase App Check is scaffolded in `lib/startup_service.dart`.

**Localization:**
- `intl` + Flutter's `gen_l10n` generator. Source ARB files: `lib/core/localization/app_en.arb`, `lib/core/localization/app_pl.arb`. Configured in `l10n.yaml` (`arb-dir: lib/core/localization`, `template-arb-file: app_pl.arb`, `output-localization-file: app_localizations.dart`). Generated at build time into `flutter_gen/gen_l10n/app_localizations.dart`. Accessed via `context.localizations.<key>` from `lib/core/extensions/context_extension.dart`.
- Key naming: `<feature>_<element>` (e.g. `homePage_title`, `homePage_incrementButton`, `homePage_error`).

**Theming:**
- Material 3 light theme generated from `AppColors.primary` seed in `lib/core/presentation/app_themes.dart`. Accessed via `context.theme` extension. Spacing tokens in `AppDimensions` (`lib/core/presentation/app_dimensions.dart`). `AppFonts`, `AppStyles`, `AppImages` are scaffolded but empty — populated per project.

**Dependency Injection:**
- `get_it` instance singleton in `lib/core/injectable/injection.dart` (`final getIt = GetIt.instance`).
- `@InjectableInit` generates `injection.config.dart` listing all `@Injectable`/`@injectable` classes (currently registers `CounterLocalDataBase`, `CounterRepository`, `CounterService`, `HomeCubit` — all as `factory`).
- Cubits resolved at widget build via `getIt<HomeCubit>()` inside `BlocProvider.create`.
- Run `flutter pub run build_runner build --delete-conflicting-outputs` after adding new annotated classes.

**Generated Code:**
- `auto_route_generator` → `lib/core/router/router.gr.dart` (part-of `router.dart`)
- `injectable_generator` → `lib/core/injectable/injection.config.dart`
- `objectbox_generator` → `lib/core/local_database/objectbox.g.dart`, `objectbox-model.json`
- Flutter `gen_l10n` → `flutter_gen/gen_l10n/app_localizations.dart`

---

*Architecture analysis: 2026-04-16*
