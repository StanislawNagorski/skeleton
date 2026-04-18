# Codebase Structure

**Analysis Date:** 2026-04-16

## Directory Layout

```
skeleton/
├── android/                                # Native Android project (Gradle, AndroidManifest)
├── ios/                                    # Native iOS project (Xcode, Podfile, Info.plist)
├── linux/                                  # Native Linux desktop scaffold
├── macos/                                  # Native macOS desktop scaffold
├── windows/                                # Native Windows desktop scaffold
├── web/                                    # Flutter web scaffold
├── build/                                  # Generated build artefacts (gitignored)
├── assets/                                 # Static assets (images/, sounds/, images/webp/)
├── lib/                                    # All Dart source code
│   ├── main.dart                           # App entry point
│   ├── app.dart                            # MyApp widget — MaterialApp.router setup
│   ├── startup_service.dart                # Bootstrap orchestration: Firebase, DI, ObjectBox
│   ├── core/                               # Cross-cutting infrastructure shared by all features
│   │   ├── injectable/                     # get_it + injectable DI setup
│   │   │   ├── injection.dart              # configureDependenciesApp() + getIt singleton
│   │   │   └── injection.config.dart       # GENERATED — registered factories
│   │   ├── local_database/                 # ObjectBox singleton store + generated bindings
│   │   │   ├── object_box.dart             # initObjectBox(), getBox<T>(), store getter
│   │   │   ├── objectbox.g.dart            # GENERATED bindings
│   │   │   └── objectbox-model.json        # GENERATED schema metadata
│   │   ├── router/                         # auto_route navigation
│   │   │   ├── router.dart                 # AppRouter + AppRouterObserver
│   │   │   └── router.gr.dart              # GENERATED routes
│   │   ├── errors/
│   │   │   └── failures.dart               # Failure base class + LocalDataNotFound/LocalDataSource
│   │   ├── presentation/                   # App-wide design tokens (theme, colors, dimensions, fonts, styles, images)
│   │   │   ├── app_themes.dart
│   │   │   ├── app_colors.dart
│   │   │   ├── app_dimensions.dart
│   │   │   ├── app_fonts.dart
│   │   │   ├── app_styles.dart
│   │   │   └── app_images.dart
│   │   ├── localization/                   # ARB translation files
│   │   │   ├── app_en.arb
│   │   │   └── app_pl.arb
│   │   ├── extensions/
│   │   │   └── context_extension.dart      # context.localizations, context.theme
│   │   └── utils/
│   │       └── debouncer.dart              # Generic Timer-based debouncer
│   └── features/                           # Feature modules (one folder per feature, Clean Architecture inside)
│       └── home_page/                      # Example feature: counter persisted to ObjectBox
│           ├── data/
│           │   ├── model/
│           │   │   └── counter_model.dart            # @Entity()  ObjectBox model
│           │   ├── local_database/
│           │   │   └── counter_local_database.dart   # CounterLocalDataBase + Impl (no business logic)
│           │   └── repository/
│           │       └── counter_repository.dart       # CounterRepository + Impl, returns Either<Failure, T>
│           ├── domain/
│           │   └── counter_service.dart              # CounterService + Impl, orchestrates repositories
│           └── presentation/
│               ├── home_page.dart                    # @RoutePage() MyHomePage StatelessWidget
│               └── cubit/
│                   ├── home_cubit.dart               # @injectable HomeCubit extends Cubit<HomeState>
│                   └── home_state.dart               # part of home_cubit.dart — HomeState + enums
├── pubspec.yaml                            # Dependencies + objectbox output_dir override
├── pubspec.lock
├── analysis_options.yaml                   # Lints (extends package:flutter_lints/flutter.yaml)
├── l10n.yaml                               # gen_l10n config
├── README.md                               # Architecture & convention reference
├── .fvmrc                                  # Pinned Flutter version (FVM)
├── .metadata
├── .gitignore
├── .flutter-plugins                        # GENERATED
└── .flutter-plugins-dependencies           # GENERATED
```

## Directory Purposes

**`lib/`:**
- Purpose: All Dart source code for the app.
- Contains: Three top-level Dart files (`main.dart`, `app.dart`, `startup_service.dart`) plus two subdirectories (`core/`, `features/`).
- Key files: `lib/main.dart`, `lib/app.dart`, `lib/startup_service.dart`.

**`lib/core/`:**
- Purpose: Cross-cutting infrastructure used by every feature. Code here must NOT depend on any feature.
- Contains: DI setup, local DB singleton, router, error types, design tokens, localization ARB files, context extensions, generic utilities.
- Key files: `lib/core/injectable/injection.dart`, `lib/core/local_database/object_box.dart`, `lib/core/router/router.dart`, `lib/core/errors/failures.dart`, `lib/core/extensions/context_extension.dart`.

**`lib/core/injectable/`:**
- Purpose: `get_it` + `injectable` wiring.
- Contains: `injection.dart` (manual `getIt` singleton + `@InjectableInit`-annotated bootstrap function) and `injection.config.dart` (GENERATED — never edit; rerun build_runner instead).

**`lib/core/local_database/`:**
- Purpose: ObjectBox `Store` lifecycle and generated bindings. Singleton `Store` reused by every feature's data source.
- Contains: `object_box.dart` (the `ObjectBox` abstract class with `initObjectBox()`, `getBox<T>()`, `store`, `close()`) and ObjectBox generator output (`objectbox.g.dart`, `objectbox-model.json`).
- Note: The output directory is overridden in `pubspec.yaml` (`objectbox: output_dir: core/local_database`).

**`lib/core/router/`:**
- Purpose: `auto_route` navigation root and observer.
- Contains: `router.dart` (`AppRouter extends RootStackRouter` with the `routes` list, plus `AppRouterObserver extends AutoRouterObserver` for logging) and the generated `router.gr.dart` (linked via `part 'router.gr.dart'`).

**`lib/core/errors/`:**
- Purpose: Typed error hierarchy returned from data layer upward via `dartz` `Either`.
- Contains: `failures.dart` defining `Failure`, `LocalDataNotFoundFailure`, `LocalDataSourceFailure` and `Failure` factory constructors.

**`lib/core/presentation/`:**
- Purpose: App-wide visual design tokens used by every feature page/widget.
- Contains: `app_themes.dart` (Material 3 `ThemeData`), `app_colors.dart`, `app_dimensions.dart` (spacing/radius constants), `app_fonts.dart` (placeholder), `app_styles.dart` (placeholder), `app_images.dart` (asset path constants placeholder).

**`lib/core/localization/`:**
- Purpose: Translation source files; consumed by Flutter's `gen_l10n` tool per `l10n.yaml`.
- Contains: `app_en.arb`, `app_pl.arb`. Template ARB is `app_pl.arb`. Generated `AppLocalizations` lands under `flutter_gen/gen_l10n/app_localizations.dart` and is imported as `package:flutter_gen/gen_l10n/app_localizations.dart`.

**`lib/core/extensions/`:**
- Purpose: Reusable extensions on Flutter/Dart types.
- Contains: `context_extension.dart` exposing `context.localizations` (cast `AppLocalizations`) and `context.theme` (`Theme.of(this)`).

**`lib/core/utils/`:**
- Purpose: Generic, framework-agnostic helpers.
- Contains: `debouncer.dart` (`Debouncer({milliseconds = 100})` with `call(VoidCallback)` and `close()`).

**`lib/features/`:**
- Purpose: Vertical feature slices. Each subdirectory contains one feature with its own `data/`, `domain/`, `presentation/` subtree.
- Contains: One folder per feature, snake_case named (currently only `home_page/`).

**`lib/features/<feature>/data/`:**
- Purpose: Data acquisition layer per the README's Clean Architecture description.
- Contains:
  - `model/` — Plain Dart classes annotated `@Entity()` (ObjectBox) for persistence; may also hold DTOs for remote APIs.
  - `local_database/` — Local data source (`abstract` interface + `*Impl` annotated `@Injectable(as: ...)`); no business logic.
  - `remote/` — (Convention; not yet present in the example) Remote API data sources following the same pattern as `local_database/`.
  - `repository/` — Repository (`abstract` interface + `*Impl`) wrapping data sources, returning `Either<Failure, T>` and logging exceptions.

**`lib/features/<feature>/domain/`:**
- Purpose: Business logic layer.
- Contains:
  - `services/` (or single `*_service.dart` file) — Service abstractions + `*Impl` orchestrating one or more repositories.
  - `entities/` — (Convention per README) Pure business objects parsed from data-layer models. Currently the example feature reuses the `CounterModel` directly.

**`lib/features/<feature>/presentation/`:**
- Purpose: UI layer for the feature.
- Contains:
  - `<feature>_page.dart` — `@RoutePage()` page widget (`StatelessWidget`) that wires `BlocProvider<HomeCubit>(create: (_) => getIt<HomeCubit>()..init())`.
  - `cubit/` — `<Feature>Cubit` extending `Cubit<<Feature>State>`, annotated `@injectable`; co-located `<feature>_state.dart` declared as `part of '*_cubit.dart'`.
  - `widgets/` — (Convention) Reusable widgets used by this feature only. Not present in the example feature.

## Key File Locations

**Entry Points:**
- `lib/main.dart`: `Future<void> main()` — initializes binding, runs `StartUpService.initServices()`, builds `AppRouter`, calls `runApp(MyApp(...))`.
- `lib/app.dart`: `MyApp` `StatelessWidget` — `MaterialApp.router` with router config, localization delegates, supported locales (`pl`, `en`), and `AppThemes.light`.
- `lib/startup_service.dart`: `StartUpService.initServices()` — orchestrates Firebase (currently TODO), DI, ObjectBox.

**Configuration:**
- `pubspec.yaml`: Dependencies, asset declarations (`assets/images/`, `assets/sounds/`, `assets/images/webp/`), `flutter.generate: true` (enables gen_l10n), `objectbox.output_dir: core/local_database`.
- `pubspec.lock`: Locked dependency versions.
- `analysis_options.yaml`: Lints — extends `package:flutter_lints/flutter.yaml`; no custom rules currently enabled.
- `l10n.yaml`: `arb-dir: lib/core/localization`, `template-arb-file: app_pl.arb`, `output-localization-file: app_localizations.dart`.
- `.fvmrc`: Pinned Flutter version for FVM.
- `.metadata`: Flutter project metadata (managed by Flutter tooling).
- `android/app/build.gradle`: Android `namespace` (must be updated per project per README).
- `ios/Runner/Info.plist`: iOS `CFBundleIdentifier` (must be updated per project per README).

**Core Logic:**
- `lib/core/injectable/injection.dart`: DI singleton bootstrap.
- `lib/core/local_database/object_box.dart`: ObjectBox `Store` lifecycle.
- `lib/core/router/router.dart`: Route declarations and navigation observer.
- `lib/core/errors/failures.dart`: Typed `Failure` hierarchy.

**Design System:**
- `lib/core/presentation/app_themes.dart`: Material 3 `ThemeData` from `AppColors.primary` seed.
- `lib/core/presentation/app_colors.dart`: `AppColors.primary` (currently `Color(0xFF3643BA)`).
- `lib/core/presentation/app_dimensions.dart`: `radiusSmall`, `radiusMedium`, `spacingSmall`, `spacingBase`, `spacingMedium`, `spacingLarge`, `spacingExtraLarge`, `snackBarHeight`.
- `lib/core/presentation/app_fonts.dart`, `app_styles.dart`, `app_images.dart`: Empty `abstract class` placeholders ready to be populated per project.

**Example Feature:**
- `lib/features/home_page/presentation/home_page.dart`: Reference page implementation.
- `lib/features/home_page/presentation/cubit/home_cubit.dart` + `home_state.dart`: Reference Cubit + state.
- `lib/features/home_page/domain/counter_service.dart`: Reference service.
- `lib/features/home_page/data/repository/counter_repository.dart`: Reference repository with `Either<Failure, T>` error handling.
- `lib/features/home_page/data/local_database/counter_local_database.dart`: Reference local data source over ObjectBox `Box<T>`.
- `lib/features/home_page/data/model/counter_model.dart`: Reference `@Entity()` model.

**Testing:**
- No test files present in the skeleton (`test/` directory is absent). `flutter_test` is declared in `pubspec.yaml` `dev_dependencies`. Project convention is to be defined when tests are first added.

**Generated (do not edit, regenerate via `flutter pub run build_runner build --delete-conflicting-outputs`):**
- `lib/core/router/router.gr.dart`
- `lib/core/injectable/injection.config.dart`
- `lib/core/local_database/objectbox.g.dart`
- `lib/core/local_database/objectbox-model.json`
- `flutter_gen/gen_l10n/app_localizations.dart` (built via `flutter gen-l10n` / triggered by `flutter pub get` when `flutter.generate: true`)

## Naming Conventions

**Files:**
- All Dart files: `snake_case.dart` (e.g. `counter_repository.dart`, `home_cubit.dart`, `app_themes.dart`).
- Generated files: `<source>.g.dart`, `<source>.gr.dart`, `<source>.config.dart` (untouchable; managed by build_runner).
- State files paired with cubit: `<feature>_state.dart` declared as `part of '<feature>_cubit.dart'`.

**Directories:**
- All directories: `snake_case` (e.g. `home_page`, `local_database`, `app_themes` would be a file not a dir).
- Feature folders: singular noun describing the feature (`home_page`, not `home_pages`).
- Layer folders inside a feature: exactly `data`, `domain`, `presentation` (lowercase, no plural).
- Sub-layer folders: `model/`, `local_database/`, `repository/`, `services/` (or single `*_service.dart` if one), `entities/`, `cubit/`, `widgets/`.

**Classes & Identifiers (per README):**
- Classes: `PascalCase` nouns (`ApiClient`, `CounterRepository`, `HomeCubit`, `MyHomePage`).
- Methods: `camelCase` verbs (`getAllPromotions`, `validateCode`, `initObjectBox`, `setCounter`).
- Variables: `camelCase` nouns (`apiClient`, `userInput`, `debounceTimeInMilliSeconds`).
- Booleans: question prefix (`is`, `should`, `has`) — e.g. `isValid`, `isFirstTimeLogin`, `shouldFetchNewData`.
- Private members: leading underscore (`_store`, `_localDataBase`, `_counterStream`, `_logger`, `_configureFirebase()`).
- Abstract + Impl pair: `Foo` (abstract) + `FooImpl implements Foo` (concrete `@Injectable(as: Foo)`).
- ARB localization keys: `<feature>_<element>` (`homePage_title`, `homePage_incrementButton`, `homePage_error`).
- Status enums: `<Feature>PageStatus` with values `loading`, `success`, `error`, `empty`.
- Navigation enums: `<Feature>PageNavigation` with `empty` plus per-feature destinations.

## Where to Add New Code

**New Feature:**
1. Create `lib/features/<feature_name>/` (snake_case noun matching the feature concept).
2. Inside, create the three layer folders:
   - `data/model/<entity>_model.dart` — `@Entity()` ObjectBox class (or DTO for remote).
   - `data/local_database/<entity>_local_database.dart` — `abstract class <Entity>LocalDataBase` + `@Injectable(as: <Entity>LocalDataBase)` impl using `ObjectBox.getBox<...>()`.
   - `data/remote/<entity>_remote_data_source.dart` — (if remote needed) same pattern.
   - `data/repository/<entity>_repository.dart` — `abstract class <Entity>Repository` + `@Injectable(as: <Entity>Repository)` impl returning `Either<Failure, T>`.
   - `domain/<entity>_service.dart` (or `domain/services/<entity>_service.dart` if multiple) — `abstract class <Entity>Service` + `@Injectable(as: <Entity>Service)` impl.
   - `presentation/<feature>_page.dart` — `@RoutePage()` `StatelessWidget` wrapping `BlocProvider(create: (_) => getIt<<Feature>Cubit>()..init())`.
   - `presentation/cubit/<feature>_cubit.dart` — `@injectable class <Feature>Cubit extends Cubit<<Feature>State>` with `part '<feature>_state.dart';`.
   - `presentation/cubit/<feature>_state.dart` — `part of '<feature>_cubit.dart';` declaring immutable `<Feature>State` + `<Feature>PageStatus` / `<Feature>PageNavigation` enums.
   - `presentation/widgets/<reusable>.dart` — (optional) feature-specific reusable widgets.
3. Register the route in `lib/core/router/router.dart` `routes` list (`AutoRoute(page: <Feature>Route.page, path: '/<path>')`).
4. Add ARB keys to `lib/core/localization/app_en.arb` and `app_pl.arb` using `<feature>_<element>` naming.
5. Run `flutter pub run build_runner build --delete-conflicting-outputs` to regenerate `injection.config.dart`, `router.gr.dart`, and `objectbox.g.dart`.

**New Component / Module (within an existing feature):**
- Single-file repositories/services/data sources: keep alongside existing siblings in the same `data/` or `domain/` subfolder.
- Multiple services in one feature: create `lib/features/<feature>/domain/services/` and split per file.
- Reusable feature widgets: `lib/features/<feature>/presentation/widgets/<widget>.dart`.

**Shared Utilities:**
- Generic, framework-agnostic helpers: `lib/core/utils/<helper>.dart` (e.g. `lib/core/utils/debouncer.dart`).
- Cross-feature widgets: not a current convention — add a `lib/core/presentation/widgets/` directory if needed.
- New `BuildContext` extensions: `lib/core/extensions/context_extension.dart` (extend the existing extension) or a new `<topic>_extension.dart` next to it.
- New `Failure` types: add a factory constructor to `Failure` and a subclass in `lib/core/errors/failures.dart`.

**New Asset:**
1. Drop the file into `assets/images/`, `assets/images/webp/`, or `assets/sounds/` (already declared in `pubspec.yaml`).
2. Add a `static const` path constant to `lib/core/presentation/app_images.dart` (or a sibling `app_sounds.dart` if introducing sound constants).

**New Translation:**
1. Add the key to BOTH `lib/core/localization/app_en.arb` and `lib/core/localization/app_pl.arb` (template is `app_pl.arb` per `l10n.yaml`).
2. Use snake-cased `<feature>_<element>` keys.
3. Run `flutter pub get` (or `flutter gen-l10n`) to regenerate `flutter_gen/gen_l10n/app_localizations.dart`.
4. Read in widgets via `context.localizations.<key>`.

## Special Directories

**`build/`:**
- Purpose: Flutter build outputs (intermediate + final artefacts).
- Generated: Yes (by `flutter build` / `flutter run`).
- Committed: No (gitignored).

**`.dart_tool/`:**
- Purpose: Dart toolchain working directory (package config, build_runner cache).
- Generated: Yes.
- Committed: No.

**`.fvm/` (if present):**
- Purpose: FVM-managed Flutter SDK symlink. `.fvmrc` pins the version.
- Generated: Yes (by `fvm install`).
- Committed: No.

**`assets/`:**
- Purpose: Static assets (images, sounds). Subdirectories enumerated in `pubspec.yaml` under `flutter.assets`.
- Generated: No.
- Committed: Yes.

**Native platform folders (`android/`, `ios/`, `linux/`, `macos/`, `windows/`, `web/`):**
- Purpose: Native project scaffolds for each target platform.
- Generated: Initially generated by `flutter create`; thereafter customized (manifest, Info.plist, namespace, signing, splash screen, etc.).
- Committed: Yes. README notes the alternative of deleting `android/` and `ios/` and rerunning `flutter create .` to regenerate them with a fresh package name.

**Generated Dart files (in-tree):**
- `*.g.dart`, `*.gr.dart`, `*.config.dart`, `lib/core/local_database/objectbox-model.json`.
- Generated: Yes (by `build_runner`).
- Committed: Yes (current convention — these files are tracked alongside their sources).
- Never edit by hand. Regenerate with `flutter pub run build_runner build --delete-conflicting-outputs`.

**`flutter_gen/` (virtual package):**
- Purpose: Houses generated `AppLocalizations` and other gen output.
- Generated: Yes (by `flutter gen-l10n` / `flutter pub get` when `flutter.generate: true`).
- Committed: No (lives in `.dart_tool/flutter_gen` typically).

**`.planning/`:**
- Purpose: Project planning docs (this directory and its subdirectories `.planning/codebase/`).
- Generated: No (manually maintained).
- Committed: Per project preference (currently appears tracked).

---

*Structure analysis: 2026-04-16*
