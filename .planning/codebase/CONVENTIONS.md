# Coding Conventions

**Analysis Date:** 2026-04-16

## Lint Configuration

**Source:** `analysis_options.yaml`

**Base Ruleset:**
- `package:flutter_lints/flutter.yaml` (via `flutter_lints: ^5.0.0`)
- No custom rules added/removed - the project uses Flutter's recommended defaults out of the box
- No custom analyzer plugins, no `errors:`, `exclude:`, or `analyzer:` overrides defined

**Implications of using flutter_lints defaults:**
- `prefer_const_constructors`, `prefer_const_literals_to_create_immutables` enforced
- `use_super_parameters` enforced (visible in `lib/app.dart:9` -> `MyApp({super.key, ...})`)
- `avoid_print` enabled - use `Logger` from `package:logger` instead (see `lib/features/home_page/data/repository/counter_repository.dart:21`)
- Single quotes are NOT enforced by default (the `prefer_single_quotes` rule is commented out), but the codebase consistently uses single quotes
- `// ignore:` and `// ignore_for_file:` comments are used for generated files (e.g. `injection.config.dart:7,10`)

**Customization point:** Add new rules under the `linter.rules:` block in `analysis_options.yaml`.

## Naming Patterns

**From `README.md` (lines 75-82) - explicitly documented project conventions:**

**Methods:** Verb-prefixed, action-clear.
- Examples: `getCounter()`, `setCounter()`, `watchCounter()`, `initObjectBox()`, `configureDependenciesApp()`, `validateCode`, `getAllPromotions`
- See: `lib/features/home_page/domain/counter_service.dart:10-12`

**Variables and classes:** Nouns.
- Examples: `CounterModel counter`, `Logger logger`, `AppRouter appRouter`, `String userInput`
- See: `lib/main.dart:10` -> `final appRouter = AppRouter();`

**Booleans:** Question prefix (`is`, `should`).
- Examples: `isValid`, `isFirstTimeLogin`, `shouldFetchNewData`
- Codebase example: `if (_timer?.isActive ?? false)` in `lib/core/utils/debouncer.dart:12`

## Dart-Style Naming

**Files:** `snake_case.dart`
- `counter_repository.dart`, `counter_local_database.dart`, `home_cubit.dart`, `app_themes.dart`, `context_extension.dart`

**Directories:** `snake_case`
- `lib/core/local_database/`, `lib/features/home_page/`, `lib/core/injectable/`

**Classes:** `UpperCamelCase`
- `CounterRepository`, `HomeCubit`, `MyHomePage`, `AppRouter`, `StartUpService`, `ObjectBox`

**Class implementation suffix:** `<Abstract>Impl`
- `CounterRepositoryImpl implements CounterRepository` (`lib/features/home_page/data/repository/counter_repository.dart:17`)
- `CounterLocalDataBaseImpl implements CounterLocalDataBase` (`lib/features/home_page/data/local_database/counter_local_database.dart:14`)
- `CounterServiceImpl implements CounterService` (`lib/features/home_page/domain/counter_service.dart:16`)

**Variables/methods:** `lowerCamelCase`
- `appRouter`, `getCounter`, `_counterService`, `defaultDebounceMilliSeconds`

**Private members:** Leading underscore
- `_localDataBase`, `_logger`, `_timer`, `_counterStream`, `_store`, `_configureFirebase()`, `_getCounter()`, `_showErrorSnackBar()`, `_Page` (private widget class)

**Constants:** `lowerCamelCase` (Dart-style, NOT `SCREAMING_SNAKE_CASE`)
- `defaultDebounceMilliSeconds = 100` (`lib/core/utils/debouncer.dart:7`)
- `spacingSmall = 4`, `spacingBase = 8`, `radiusMedium = 12` (`lib/core/presentation/app_dimensions.dart`)

**Enums:** `UpperCamelCase` type, `lowerCamelCase` values
```dart
enum HomePageStatus { loading, success, error, empty }
```
See `lib/features/home_page/presentation/cubit/home_state.dart:33-42`.

**Localization keys:** `feature_camelCaseDescriptor` pattern
- `homePage_title`, `homePage_centeredText`, `homePage_incrementButton`, `homePage_error`
- See `lib/core/localization/app_pl.arb`

## File Organization

**Project layout follows Clean Architecture (per `README.md:62-73`):**

```
lib/
├── main.dart                    # Entry point - minimal bootstrap
├── app.dart                     # MyApp root widget
├── startup_service.dart         # Service initialization orchestration
├── core/                        # Cross-cutting infrastructure
│   ├── injectable/              # GetIt + injectable DI setup
│   ├── local_database/          # ObjectBox setup + generated objectbox.g.dart
│   ├── router/                  # auto_route config + generated router.gr.dart
│   ├── localization/            # ARB files for intl
│   ├── presentation/            # App-wide design tokens (themes, colors, dimensions)
│   ├── extensions/              # BuildContext and similar extensions
│   ├── errors/                  # Failure types for Either-based error handling
│   └── utils/                   # Shared utilities (Debouncer, etc.)
└── features/<feature_name>/     # Per-feature Clean Architecture slice
    ├── data/
    │   ├── model/               # Data classes (e.g. ObjectBox @Entity)
    │   ├── local_database/      # Local data source interface + impl
    │   └── repository/          # Repository: error handling -> Either<Failure, T>
    ├── domain/                  # Service classes orchestrating repositories
    └── presentation/
        ├── cubit/               # Bloc/Cubit + part-of state file
        └── *_page.dart          # Page widgets
```

**Layer rules:**
- **Data sources** must contain NO business logic - only fetch/persist (`lib/features/home_page/data/local_database/counter_local_database.dart:6`)
- **Repositories** handle errors and convert exceptions to `Failure` instances (`counter_repository.dart:9`)
- **Services** connect multiple repositories, hold non-UI business logic (`counter_service.dart:8`)
- **Cubits** manage UI state and bridge presentation -> domain
- Each layer defines an `abstract class` interface, then `<Name>Impl` for the implementation registered with `@Injectable(as: Name)`

## Import Organization

**Observed order (e.g. `lib/features/home_page/presentation/home_page.dart:1-8`):**
1. Dart SDK imports (`dart:async`)
2. Flutter framework imports (`package:flutter/...`, `package:flutter_bloc/...`)
3. Third-party packages (`package:auto_route/...`, `package:dartz/...`, `package:injectable/...`)
4. Project absolute imports (`package:skeleton/...`)
5. Relative imports (`../../../core/...`)

**Conventions:**
- Mix of `package:skeleton/...` absolute and `../` relative imports - relative is preferred for siblings within the same feature, absolute for crossing features
- `part`/`part of` used for state classes paired with cubits (`home_cubit.dart:8` <-> `home_state.dart:1`) and generated router (`router.dart:7`)

## Error Handling

**Functional pattern using `dartz` `Either<Failure, T>`** (from `package:dartz: 0.10.1`).

**Failure hierarchy:** `lib/core/errors/failures.dart`
```dart
class Failure {
  const Failure(this.message);
  factory Failure.localDataNotFound(String? message) => LocalDataNotFoundFailure(message);
  factory Failure.localDataSource(String? message) => LocalDataSourceFailure(message);
  final String? message;
}
class LocalDataNotFoundFailure extends Failure { ... }
class LocalDataSourceFailure extends Failure { ... }
```

**Repository pattern - try/catch -> Either:**
```dart
// lib/features/home_page/data/repository/counter_repository.dart:24-35
Future<Either<Failure, CounterModel>> getCounter() async {
  try {
    final counter = await _localDataBase.getCounter();
    if (counter == null) {
      return Left(Failure.localDataNotFound('Counter not found'));
    }
    return Right(counter);
  } catch (e) {
    _logger.e('Local data source exception: $e');
    return Left(Failure.localDataSource(e.toString()));
  }
}
```

**Consumer pattern - `.fold()` to branch:**
```dart
// lib/features/home_page/presentation/cubit/home_cubit.dart:25-36
data.fold(
  (failure) => emit(state.copyWith(status: HomePageStatus.error)),
  (data) => emit(state.copyWith(status: HomePageStatus.success, counter: data)),
);
```

**Rules:**
- Data sources throw exceptions normally - they do NOT use `Either`
- Repositories MUST catch and translate to `Failure` subtypes
- Services and cubits propagate `Either<Failure, T>` further up
- Always `_logger.e(...)` before returning `Left(...)` so errors are observable
- Never let exceptions escape the repository layer

## Async Patterns

**`async`/`await` everywhere** - no raw `.then()` chains except where converting `Future<Either>` to nullable via fold:
```dart
// lib/features/home_page/presentation/cubit/home_cubit.dart:53-55
Future<CounterModel?> _getCounter() async => await _counterService.getCounter().then(
  (result) => result.fold((failure) => null, (data) => data),
);
```

**Stream pattern for reactive data** - ObjectBox watch -> mapped Stream of Either:
```dart
// lib/features/home_page/data/repository/counter_repository.dart:48-61
Stream<Either<Failure, CounterModel>> watchCounter() =>
    _localDataBase.watchCounter().map((counter) { ... });
```

**StreamSubscription tracked in cubit field** for cancellation discipline (`home_cubit.dart:15` -> `StreamSubscription? _counterStream;`).

Note: there is currently no explicit `close()` override that cancels `_counterStream` - this is a known gap (see CONCERNS.md).

**Initialization** - `WidgetsFlutterBinding.ensureInitialized()` then sequential `await`s in `StartUpService.initServices()` (`lib/main.dart:8-9`, `lib/startup_service.dart:12-16`).

## Class Design

**Abstract classes used as:**
1. Interface contracts paired with `Impl` classes (Repository/DataSource/Service)
2. Static-only namespaces - e.g. `AppThemes`, `AppColors`, `AppDimensions`, `AppImages`, `AppFonts`, `StartUpService`, `ObjectBox`. These cannot be instantiated; all members are `static`.

**Const constructors** used for value/UI types:
- `const MyApp({super.key, required this.appRouter});` (`lib/app.dart:9`)
- `const Failure(this.message);` (`lib/core/errors/failures.dart:2`)

**Required named parameters preferred** for API clarity:
- `setCounter({required CounterModel counter})` (`counter_repository.dart:38`)
- `MyApp({super.key, required this.appRouter})` (`app.dart:9`)

**`copyWith` for immutable state updates** (manual implementation, no code generation):
- `HomeState.copyWith` (`home_state.dart:20-30`)
- `CounterModel.copyWith` (`counter_model.dart:11-17`)

**Factory constructors for named variants:**
- `HomeState.initial()` (`home_state.dart:10-14`)
- `Failure.localDataNotFound(...)`, `Failure.localDataSource(...)` (`failures.dart:4-5`)

## Widget Patterns

**StatelessWidget by default** - state belongs in Cubits, not in widgets.

**Arrow-syntax `build` methods** preferred:
```dart
// lib/app.dart:14
Widget build(BuildContext context) => MaterialApp.router(...);
```

**Private widget classes** (leading underscore) used to break up large `build` methods within a single file:
```dart
// lib/features/home_page/presentation/home_page.dart:61
class _Page extends StatelessWidget { ... }
```

**Theme & localization access via `BuildContext` extension** - never reach for `Theme.of(context)` directly:
```dart
// lib/core/extensions/context_extension.dart
extension ContextExtension on BuildContext {
  AppLocalizations get localizations => AppLocalizations.of(this)!;
  ThemeData get theme => Theme.of(this);
}
// Usage: context.localizations.homePage_title, context.theme.colorScheme.primary
```

## Logging

**Tool:** `package:logger: ^2.5.0`.

**Pattern:** Each class instantiates its own `Logger`:
```dart
final Logger _logger = Logger();                    // counter_repository.dart:21
final logger = Logger(printer: PrettyPrinter(...)); // router.dart:18
```

**Log levels used:**
- `_logger.e(...)` for caught exceptions in repositories
- `logger.t(...)` for trace-level (route changes in `AppRouterObserver`)

**No `print()` statements** - blocked by `flutter_lints` `avoid_print`.

## Dependency Injection

**Tool:** `get_it` + `injectable` with code generation via `injectable_generator`.

**Pattern:**
```dart
// lib/core/injectable/injection.dart
final getIt = GetIt.instance;

@InjectableInit(initializerName: r'$initGetIt', preferRelativeImports: true, asExtension: false)
Future<void> configureDependenciesApp() async => $initGetIt(getIt);
```

**Class registration:** Annotate the implementation, declare the contract:
```dart
@Injectable(as: CounterRepository)
class CounterRepositoryImpl implements CounterRepository { ... }

@injectable
class HomeCubit extends Cubit<HomeState> { ... }
```

**Resolution at usage site:**
```dart
// lib/features/home_page/presentation/home_page.dart:16
BlocProvider(create: (context) => getIt<HomeCubit>()..init(), ...)
```

**Regeneration command:**
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Generated Code

**Files NEVER edited by hand** - all marked with `// GENERATED CODE - DO NOT MODIFY BY HAND`:
- `lib/core/injectable/injection.config.dart`
- `lib/core/router/router.gr.dart`
- `lib/core/local_database/objectbox.g.dart`
- `lib/core/localization/app_localizations*.dart` (generated by `flutter_gen` from ARB files)

Generated files include `// ignore_for_file: type=lint` and `// coverage:ignore-file` directives.

## Comments

**Sparse, purpose-driven** - architecture-explaining comments at the top of contracts:
```dart
//Repository purpose is to handle errors while fetching data from the data sources
abstract class CounterRepository { ... }

//Purpose of data source is to fetch data, there should be no business logic here
abstract class CounterLocalDataBase { ... }

//Purpose of service is to connect with multiple repositories, ...
abstract class CounterService { ... }
```

**`TODO:` markers** for pending wiring tasks:
- `lib/startup_service.dart:27-34` lists Firebase setup TODOs

**No JSDoc/TSDoc-style block comments** observed; triple-slash `///` doc comments used only in `lib/core/injectable/injection.dart:6-11`.

## Localization

**Tool:** `intl: ^0.19.0` + Flutter's built-in `gen_l10n`.

**Configuration:** `l10n.yaml`
```yaml
arb-dir: lib/core/localization
template-arb-file: app_pl.arb
output-localization-file: app_localizations.dart
```

**Supported locales:** Polish (template), English (`lib/app.dart:25-28`).

**Access pattern:** Always via `context.localizations.<key>` - never hardcode user-facing strings in widgets.

**Key naming:** `<feature>_<descriptor>` (e.g. `homePage_incrementButton`).

## Tooling

**Flutter version:** Pinned via FVM in `.fvmrc` -> `3.29.0`.

**Dart SDK:** `^3.6.0` (`pubspec.yaml:8`).

**Run analyzer:**
```bash
flutter analyze
```

**Format code:**
```bash
dart format lib/
```

---

*Convention analysis: 2026-04-16*
