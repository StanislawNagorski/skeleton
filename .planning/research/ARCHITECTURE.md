# Architecture Research — Flutter Mobile Skeleton 2026

**Researched:** 2026-04-16
**Scope:** Architecture dimension of the 2026 skeleton refresh
**Overall confidence:** HIGH (Context7 for auto_route + drift; official Firebase/Flutter docs; verified multi-source patterns)

---

## Summary

The refresh is a **rebase, not a rewrite**. Clean Architecture (data/domain/presentation per feature), Cubit, `get_it`+`injectable`, and `auto_route` all survive verbatim — the surgical changes are: (a) native scaffolding regenerated from a fresh `flutter create`, (b) ObjectBox replaced by Drift, (c) `dartz Either<Failure, T>` replaced by a Dart 3 sealed `Result<T>` hierarchy, (d) Firebase wired end-to-end instead of stubbed, (e) two flavors (`dev`/`prod`) introduced across Android product-flavors + iOS schemes + per-flavor FlutterFire configs, and (f) onboarding + coach-mark + RIVE splash added as first-class features that every downstream app already gets for free.

The mechanical backbone of the refresh is a **temp-dir `flutter create` → copy native dirs back → reapply lib/ + configs → regenerate code** sequence, which doubles as the repeatable upgrade protocol for the *next* Flutter major. The bootstrap script (`tool/bootstrap.dart`) then re-runs per downstream project to rename bundle identifiers, package names, display names, and to reinstall the correct `google-services.json`/`GoogleService-Info.plist` pair.

The single most consequential new boundary is `AuthService` — an abstract contract over `firebase_auth` that exposes a `Stream<AuthUser?>` (feeding `auto_route`'s `reevaluateListenable`) and sealed `AuthResult` values (feeding Cubits). Every downstream app builds its login UX on top of it, so the contract has to be right *before* flavors or onboarding are plugged in.

Build order implications: **[1] rebase + lib/ port must ship first and alone** (it changes every other file's ground truth); **[2] Drift + sealed Failure + Firebase core can proceed in parallel** (no cross-dependencies); **[3] Auth + flavors + FlutterFire per-flavor must follow Firebase core** (they all plug into initialization); **[4] onboarding + coach marks + RIVE splash come last** (they depend on routing + shared_preferences + Auth).

---

## Rebase Mechanics (repeatable process)

This is the procedure that must survive into the next Flutter major. Treat it as a versioned runbook in `README.md` after the refresh ships.

**Confidence:** HIGH — `flutter create --platforms=android,ios .` over an existing directory is the Flutter-team-sanctioned way to regenerate native scaffolding (`docs.flutter.dev/platform-integration`).

### Step 0 — Pre-rebase baseline (everything goes back if this stays clean)

```bash
git checkout -b 2026-update                         # branch already exists
git status                                          # must be clean
fvm use stable                                      # or: `fvm install stable && fvm use stable`
flutter --version                                   # record this in pubspec.yaml comment
```

### Step 1 — Capture what we want to preserve

Everything in this list is kept verbatim across the rebase:

- `lib/` (entire tree)
- `assets/` (if present)
- `pubspec.yaml` (we'll merge, not replace)
- `l10n.yaml`
- `analysis_options.yaml` (will be rewritten for `very_good_analysis`)
- `.planning/` (all research/roadmap/codebase docs)
- `README.md`, `.fvmrc`, `.metadata`
- Root config files: `.gitignore`, `.gitattributes` (if any)

Everything else under `android/`, `ios/`, `web/`, `macos/`, `linux/`, `windows/` gets **discarded**.

### Step 2 — Generate the reference scaffolding in a temp dir

```bash
TMP=$(mktemp -d)
cd "$TMP"
flutter create \
  --org com.example \
  --project-name skeleton \
  --platforms=android,ios \
  --ios-language=swift \
  --android-language=kotlin \
  skeleton_reference
```

This produces a pristine, current-Flutter-major `android/` and `ios/` tree. Everything in `lib/` there is throwaway.

### Step 3 — Swap native dirs in the skeleton

From the repo root:

```bash
rm -rf android ios web macos linux windows
cp -R "$TMP/skeleton_reference/android" ./android
cp -R "$TMP/skeleton_reference/ios"     ./ios
# web/, macos/, linux/, windows/ explicitly NOT copied
```

### Step 4 — Merge pubspec.yaml

Take the **Flutter-generated** `pubspec.yaml` from the temp dir as the structural base (it has current SDK constraints, up-to-date `flutter` lints, asset layout) and **paste the skeleton's dependency lists** on top. Don't cherry-pick line-by-line; keep the shape the tool produces and overlay our packages.

Manual edits needed after merge:

- Remove platform-only-support assets (if the scaffold added any)
- Re-add `objectbox: output_dir:` is **removed** (we're on Drift now)
- Add `build.targets` only if needed — default drift config works
- Flutter SDK constraint: take from the fresh `pubspec.yaml`

### Step 5 — Re-apply bespoke native edits in a scripted, re-playable way

These are the edits that must be re-applied *after* the native dirs are fresh. The bootstrap script (`tool/bootstrap.dart`) performs them deterministically — but the rebase also needs them applied to the *template* before the script runs. The list:

1. **Android `android/app/build.gradle(.kts)`**: add `flavorDimensions "app"` + `productFlavors { dev { ... } prod { ... } }`, `signingConfigs.release`, `buildTypes.release.signingConfig = signingConfigs.release`.
2. **Android `settings.gradle(.kts)`**: enable the Google Services plugin (`com.google.gms.google-services`), Crashlytics plugin (`com.google.firebase.crashlytics`), Performance plugin (`com.google.firebase.firebase-perf`).
3. **Android `android/app/build.gradle`**: `apply plugin:` the three Firebase plugins.
4. **iOS `ios/Podfile`**: set `platform :ios, '15.0'` (Firebase 11 floor) and the standard FlutterFire use_frameworks directives if needed.
5. **iOS Xcode project (`ios/Runner.xcodeproj`)**: create two schemes (`dev`, `prod`), each with its own `Debug`/`Release`/`Profile` configurations, wired to separate build settings files.
6. **iOS `Info.plist`**: add `CFBundleURLTypes` for Google Sign-In's reversed-client-id, Sign in with Apple capability (granted by entitlements file, not plist).
7. **`android/app/src/dev/google-services.json`** and **`android/app/src/prod/google-services.json`** placeholder files (real ones dropped per-project after running FlutterFire CLI).
8. **`ios/flavors/dev/GoogleService-Info.plist`** and **`ios/flavors/prod/GoogleService-Info.plist`** likewise.
9. **`lib/firebase_options_dev.dart`** and **`lib/firebase_options_prod.dart`** placeholders (empty, FlutterFire-CLI-regenerated per project).

### Step 6 — Restore `lib/` and re-run generators

`lib/` was never touched by Step 3 (we only replaced native dirs), so the migration of `lib/` from ObjectBox → Drift, `dartz` → sealed classes, etc. happens in subsequent phases, **not in the rebase phase**. The rebase phase's final action is:

```bash
fvm flutter pub get
fvm dart run build_runner build --delete-conflicting-outputs
fvm flutter pub global run gen_l10n     # or: `fvm flutter gen-l10n` if that's still wired
```

After this, `fvm flutter run --flavor dev` must succeed on both platforms *before* any subsequent phase starts.

### Repeatability guarantee

The reason this works for the next Flutter major too:

1. Step 1 (pre-baseline + clean branch) is platform-agnostic.
2. Step 2 uses `flutter create` — the Flutter team's official regeneration tool; it will stay available.
3. Step 3 is a pure filesystem swap — no framework dependency.
4. Step 5 is documented in `README.md` as a checklist; each item has a clear success criterion.
5. `tool/bootstrap.dart` is **version-pinned** to its own Dart source; it doesn't depend on a Flutter-major-era API.

**Pitfall flag:** the Step 5 edits drift *across Flutter majors* (Gradle DSL changes from Groovy to Kotlin, Podfile minimum iOS version bumps, plugin versions). Each future rebase needs a short "delta" section appended to the runbook noting what changed.

---

## File Layout (lib/core, lib/features, tool/, android/, ios/)

```
skeleton/
├── android/
│   └── app/
│       ├── src/
│       │   ├── main/             # shared manifest + MainActivity
│       │   ├── dev/
│       │   │   ├── AndroidManifest.xml            # overrides android:label per flavor
│       │   │   ├── google-services.json           # dev Firebase config (per-project)
│       │   │   └── res/mipmap-*/ic_launcher.png   # dev launcher icon
│       │   └── prod/
│       │       ├── AndroidManifest.xml
│       │       ├── google-services.json
│       │       └── res/mipmap-*/ic_launcher.png
│       └── build.gradle(.kts)                     # flavors + firebase plugins
├── ios/
│   ├── Runner/                                    # shared Info.plist stub
│   ├── flavors/
│   │   ├── dev/
│   │   │   ├── GoogleService-Info.plist
│   │   │   └── Info.plist                         # display name override
│   │   └── prod/
│   │       ├── GoogleService-Info.plist
│   │       └── Info.plist
│   └── Runner.xcodeproj/                          # two schemes: dev, prod
├── lib/
│   ├── main_dev.dart                              # entry: imports firebase_options_dev.dart
│   ├── main_prod.dart                             # entry: imports firebase_options_prod.dart
│   ├── bootstrap.dart                             # shared runZonedGuarded bootstrap (NOT the tool/ script)
│   ├── app.dart                                   # MyApp widget (unchanged in shape)
│   ├── firebase_options_dev.dart                  # generated by flutterfire configure
│   ├── firebase_options_prod.dart                 # generated by flutterfire configure
│   ├── core/
│   │   ├── injectable/
│   │   │   ├── injection.dart
│   │   │   └── injection.config.dart              # GENERATED
│   │   ├── database/                              # RENAMED from local_database/
│   │   │   ├── app_database.dart                  # @DriftDatabase class
│   │   │   ├── app_database.g.dart                # GENERATED
│   │   │   └── database.steps.dart                # GENERATED (step-by-step migrations)
│   │   ├── router/
│   │   │   ├── app_router.dart
│   │   │   ├── app_router.gr.dart                 # GENERATED
│   │   │   └── guards/
│   │   │       ├── onboarding_guard.dart
│   │   │       └── auth_guard.dart
│   │   ├── errors/
│   │   │   ├── failure.dart                       # sealed class Failure
│   │   │   └── result.dart                        # typedef Result<T> = (Failure?, T?); OR sealed Result
│   │   ├── auth/                                  # NEW — cross-feature auth contract
│   │   │   ├── auth_service.dart                  # abstract AuthService
│   │   │   ├── firebase_auth_service.dart         # @LazySingleton(as: AuthService)
│   │   │   ├── auth_user.dart                     # domain entity (not Firebase User)
│   │   │   └── auth_result.dart                   # sealed AuthResult
│   │   ├── preferences/                           # NEW
│   │   │   ├── preferences_service.dart           # wraps shared_preferences
│   │   │   └── secure_storage_service.dart        # wraps flutter_secure_storage
│   │   ├── firebase/                              # NEW
│   │   │   └── firebase_bootstrap.dart            # Firebase.initializeApp, App Check, Crashlytics handlers
│   │   ├── coach_mark/                            # NEW
│   │   │   └── coach_mark_service.dart            # register(key, description) + showTour()
│   │   ├── presentation/                          # design tokens (unchanged)
│   │   ├── localization/                          # ARB files (unchanged)
│   │   ├── extensions/
│   │   └── utils/
│   └── features/
│       ├── splash/                                # NEW — RIVE animated splash
│       │   └── presentation/
│       │       ├── splash_page.dart               # @RoutePage(initial: true)
│       │       └── cubit/
│       ├── onboarding/                            # NEW
│       │   ├── data/                              # writes hasSeenOnboarding flag
│       │   ├── domain/
│       │   └── presentation/
│       │       ├── onboarding_page.dart           # PageView + dots + skip/next
│       │       ├── cubit/
│       │       └── widgets/
│       └── home_page/                             # MIGRATED from ObjectBox → Drift
│           ├── data/
│           │   ├── model/
│           │   │   └── counter_table.dart         # Drift Table class
│           │   ├── local_database/                # keep folder name; Drift DAO lives here
│           │   │   └── counter_local_database.dart
│           │   └── repository/
│           ├── domain/
│           └── presentation/
├── tool/
│   └── bootstrap.dart                             # CLI: rename bundle id, package, display name, icons
├── test/                                          # NEW — counter cubit + repository tests
│   └── features/home_page/
└── pubspec.yaml                                   # no objectbox.output_dir; + drift, drift_dev, build_runner, etc.
```

**Layout decisions worth flagging:**

- **`lib/main_dev.dart` + `lib/main_prod.dart`**: two separate entrypoints, each statically importing its matching `firebase_options_*.dart`. Chosen over runtime-branching because the FlutterFire CLI emits per-flavor option files and static imports make tree-shaking and Crashlytics symbolication simpler. (`codewithandrea.com/articles/flutter-firebase-multiple-flavors-flutterfire-cli`)
- **`lib/bootstrap.dart`**: shared `Future<void> bootstrap(FirebaseOptions options) async { ... runZonedGuarded(() => runApp(MyApp()), FirebaseCrashlytics.recordError); }`. Both `main_dev.dart` and `main_prod.dart` call it.
- **`lib/core/database/` (renamed from `local_database/`)**: Drift generates multiple files (`.g.dart`, `.steps.dart`) and "database" reads better when it's singular/central, not "local" (which implied "vs remote" in the ObjectBox world). The feature-level folder stays `data/local_database/` for DAO-per-feature because that maps the layer cleanly.
- **`lib/core/auth/`**: this belongs in `core/` not a feature, because the auth contract is consumed by (a) the router guards, (b) every feature that needs the current user, and (c) the bootstrap. A feature folder would create cyclical dependencies.
- **`tool/bootstrap.dart`**: Dart-based, not shell. Dart is the language we already have; it gives us cross-platform file I/O and testable functions; and `dart run` is the canonical way Dart CLIs ship.

---

## Initialization Sequence (main.dart → runApp)

Confidence: HIGH — Firebase official docs + FlutterFire overview.

```dart
// lib/main_dev.dart
import 'firebase_options_dev.dart';
import 'bootstrap.dart';

Future<void> main() => bootstrap(DefaultFirebaseOptions.currentPlatform);
```

```dart
// lib/bootstrap.dart
Future<void> bootstrap(FirebaseOptions options) async {
  await runZonedGuarded(() async {
    // 1. Binding — mandatory first, before any platform channel call.
    WidgetsFlutterBinding.ensureInitialized();

    // 2. Firebase core — must complete before any FirebaseX.instance reference.
    await Firebase.initializeApp(options: options);

    // 3. App Check — protects Firestore/Storage/etc. Activate BEFORE any service that uses them.
    await FirebaseAppCheck.instance.activate(
      androidProvider: kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
      appleProvider: kReleaseMode ? AppleProvider.deviceCheck : AppleProvider.debug,
    );

    // 4. Crashlytics error handlers — AFTER Firebase.initializeApp so FirebaseCrashlytics.instance exists.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // 5. DI — registers singletons/factories. Must run BEFORE any getIt<T>() call.
    await configureDependencies();

    // 6. Drift — opened lazily inside the DI graph (see Local Database Integration).
    // 7. RIVE cache — no explicit init needed; `rive` package handles it on first widget build.

    // 8. Native splash teardown — coordinate with the RIVE splash handoff.
    FlutterNativeSplash.remove();   // only when RIVE splash widget is ready to paint

    // 9. runApp
    runApp(const MyApp());
  }, (error, stack) {
    // Catches anything runZonedGuarded can see; Flutter-framework errors already go
    // through FlutterError.onError above.
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}
```

**Ordering rationale:**

1. `WidgetsFlutterBinding.ensureInitialized()` is mandatory before any `MethodChannel` call (Firebase uses channels internally).
2. `Firebase.initializeApp` must precede every `FirebaseX.instance` read. App Check and Crashlytics both read instances.
3. App Check goes **before** Crashlytics only because App Check is async and we want it resolved early; either order works in practice, but this is cleaner.
4. Crashlytics handlers must be **installed before `runApp`**, otherwise early errors are swallowed.
5. `configureDependencies()` must run before `runApp` because the first screen's `BlocProvider.create` calls `getIt<T>()`.
6. `FlutterNativeSplash.remove()` is deliberately **not** called here — it's called by the RIVE splash widget once the RIVE artboard is painted. See [RIVE Splash Integration](#rive-splash-integration).

**Why `runZonedGuarded`:** catches async errors outside Flutter's zone (e.g. `Future.delayed(...).then(throwsError)`). `FlutterError.onError` and `PlatformDispatcher.instance.onError` together cover most Flutter-framework cases, but `runZonedGuarded` is the belt-and-braces that Firebase's official examples recommend.

---

## Dependency Injection Topology (get_it + injectable)

Confidence: HIGH — existing skeleton pattern + `injectable` docs.

The DI graph gains three categories of binding in the refresh:

| Scope | Annotation | Used For |
|-------|------------|----------|
| `@lazySingleton` | One instance, created on first resolve | `AppDatabase` (Drift), `AuthService`, `PreferencesService`, `SecureStorageService`, `CoachMarkService`, all service implementations |
| `@injectable` → registered as factory | New instance per resolve | Cubits (current pattern) |
| `@singleton` | One instance, created at DI init | *Avoid unless eager init is required*; DIs that call platform channels should be `@lazySingleton` |

```dart
// lib/core/database/app_database.dart
@lazySingleton
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'skeleton_app'));  // drift_flutter helper
}

// lib/core/auth/firebase_auth_service.dart
@LazySingleton(as: AuthService)
class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._firebaseAuth);
  final FirebaseAuth _firebaseAuth;
}

// lib/core/injectable/injection.dart
@InjectableInit(
  initializerName: r'$initGetIt',
  preferRelativeImports: true,
  asExtension: false,
)
Future<void> configureDependencies() async {
  // Register external instances BEFORE $initGetIt so @injectable classes can depend on them.
  final prefs = await SharedPreferences.getInstance();
  getIt.registerSingleton<SharedPreferences>(prefs);
  getIt.registerSingleton<FirebaseAuth>(FirebaseAuth.instance);
  getIt.registerSingleton<FirebaseFirestore>(FirebaseFirestore.instance);

  $initGetIt(getIt);
}
```

**Key pattern — "external" registrations first:** `SharedPreferences.getInstance()` is async and returns a plugin-resolved singleton. Register it manually before `$initGetIt(getIt)` runs, so any `@LazySingleton` that takes `SharedPreferences` in its constructor can resolve. Same for `FirebaseAuth.instance`, `FirebaseFirestore.instance`, etc. This is the idiomatic `injectable` pattern.

**Cubit registration:** stays `@injectable` (factory). Every `BlocProvider(create: (_) => getIt<HomeCubit>()..init())` gets a fresh instance per page.

---

## Routing + Guards (auto_route + onboarding + auth)

Confidence: HIGH — Context7 auto_route docs, direct extraction.

### Route tree

```dart
// lib/core/router/app_router.dart
@AutoRouterConfig()
class AppRouter extends RootStackRouter {
  AppRouter(this._authService, this._preferencesService);
  final AuthService _authService;
  final PreferencesService _preferencesService;

  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, path: '/', initial: true),
    AutoRoute(
      page: OnboardingRoute.page,
      path: '/onboarding',
    ),
    AutoRoute(
      page: HomeRoute.page,
      path: '/home',
      guards: [OnboardingGuard(_preferencesService), AuthGuard(_authService)],
    ),
    // redirect unknown paths
    RedirectRoute(path: '*', redirectTo: '/'),
  ];
}
```

### Onboarding guard

```dart
class OnboardingGuard extends AutoRouteGuard {
  OnboardingGuard(this._prefs);
  final PreferencesService _prefs;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (_prefs.hasSeenOnboarding) {
      resolver.next(true);
    } else {
      resolver.redirect(const OnboardingRoute());
    }
  }
}
```

### Auth guard

```dart
class AuthGuard extends AutoRouteGuard {
  AuthGuard(this._authService);
  final AuthService _authService;

  @override
  void onNavigation(NavigationResolver resolver, StackRouter router) {
    if (_authService.currentUser != null) {
      resolver.next(true);
    } else {
      // NOTE: the skeleton ships no login UI. Downstream apps supply their own
      // LoginRoute and either add it to guards[] or wrap this guard.
      resolver.next(false);
    }
  }
}
```

### Re-evaluation on auth change

```dart
// lib/app.dart
MaterialApp.router(
  routerConfig: appRouter.config(
    reevaluateListenable: ReevaluateListenable.stream(
      _authService.authStateChanges, // Stream<AuthUser?>
    ),
    navigatorObservers: () => [AppRouterObserver()],
  ),
);
```

The `reevaluateListenable` pattern is **directly documented in Context7** and is the idiomatic way to re-run all guards whenever auth state flips (login, logout, token refresh failure). The skeleton supplies a stream-adapter because `AuthService` exposes a `Stream<AuthUser?>`, not a `ChangeNotifier`.

### Onboarding flag write

Inside `OnboardingCubit.onFinish()`:

```dart
await _prefs.setHasSeenOnboarding(true);
emit(state.copyWith(navigation: OnboardingNavigation.goHome));
// Page listens and calls `context.router.replaceAll([const HomeRoute()])`.
```

---

## Local Database Integration (drift + get_it)

Confidence: HIGH — Context7 drift docs + `drift_flutter` pub docs.

### Package selection

- **`drift` ^2.x** — core types, annotations
- **`drift_flutter` ^0.2.x** — supplies `driftDatabase(name: ...)` helper that uses `path_provider`'s app-documents directory and bundles SQLite on Android/iOS without `sqlite3_flutter_libs` (drift ≥ 2.32 bundles it via `sqlite3` 3.x)
- **`drift_dev` ^2.x** (dev) + **`build_runner` ^2.x** (dev)

### Schema definition

```dart
// lib/features/home_page/data/model/counter_table.dart
@UseRowClass(Counter)
class CounterTable extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get value => integer().withDefault(const Constant(0))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

class Counter {
  const Counter({required this.id, required this.value, required this.updatedAt});
  final int id;
  final int value;
  final DateTime updatedAt;
}
```

### Database class (singleton via DI)

```dart
// lib/core/database/app_database.dart
@DriftDatabase(tables: [CounterTable])
@lazySingleton
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'skeleton_app'));

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async { await m.createAll(); },
    onUpgrade: stepByStep(
      // from1To2: (m, schema) async { ... },   // filled as schema evolves
    ),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
```

### DAO per feature

```dart
// lib/features/home_page/data/local_database/counter_local_database.dart
abstract class CounterLocalDataBase {
  Stream<Counter?> watchCounter();
  Future<void> setCounter(Counter counter);
}

@LazySingleton(as: CounterLocalDataBase)
class CounterLocalDataBaseImpl implements CounterLocalDataBase {
  CounterLocalDataBaseImpl(this._db);
  final AppDatabase _db;

  @override
  Stream<Counter?> watchCounter() =>
      (_db.select(_db.counterTable)..limit(1))
          .watchSingleOrNull();

  @override
  Future<void> setCounter(Counter counter) async {
    await _db.into(_db.counterTable).insertOnConflictUpdate(
      CounterTableCompanion.insert(value: Value(counter.value)),
    );
  }
}
```

### Migration strategy

- **`schemaVersion`** bumps every time a `Table` changes.
- **`dart run drift_dev make-migrations`** generates `database.steps.dart` with a snapshot per version.
- **`stepByStep`** composes `from1To2`, `from2To3`, ... into a strategy that can upgrade any older installed version to the latest.
- **Testing pattern:** `drift_dev` ships a schema-test utility that verifies every step produces the expected schema — downstream apps run these in CI. Not shipped in the skeleton, but a README pointer to it is.

### Why Drift not `sqflite` or alternatives

- Reactive queries (`.watch*()`) — direct analog to ObjectBox's streams
- Type-safe Dart-to-SQL — no raw string queries
- Schema migrations with a tested step framework
- Bundles up-to-date SQLite on Android/iOS out of the box since drift 2.32 (no `sqlite3_flutter_libs` dance)

---

## Firebase Integration (per-flavor, App Check, Crashlytics handler)

Confidence: HIGH — Firebase official docs + FlutterFire CLI docs.

### Per-flavor configuration — the one-time setup

```bash
# dev flavor
flutterfire configure \
  --project=<dev-firebase-project-id> \
  --out=lib/firebase_options_dev.dart \
  --ios-bundle-id=com.example.skeleton.dev \
  --ios-out=ios/flavors/dev/GoogleService-Info.plist \
  --android-package-name=com.example.skeleton.dev \
  --android-out=android/app/src/dev/google-services.json

# prod flavor
flutterfire configure \
  --project=<prod-firebase-project-id> \
  --out=lib/firebase_options_prod.dart \
  --ios-bundle-id=com.example.skeleton \
  --ios-out=ios/flavors/prod/GoogleService-Info.plist \
  --android-package-name=com.example.skeleton \
  --android-out=android/app/src/prod/google-services.json
```

### Android — `android/app/build.gradle(.kts)`

```kotlin
android {
    namespace "com.example.skeleton"
    // ...

    flavorDimensions += "env"

    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Skeleton Dev")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Skeleton")
        }
    }
}

apply plugin: "com.google.gms.google-services"
apply plugin: "com.google.firebase.crashlytics"
apply plugin: "com.google.firebase.firebase-perf"
```

The Google Services plugin **automatically picks** `android/app/src/<flavor>/google-services.json` for each flavor's build. No per-flavor Dart code needed on Android beyond the matching `firebase_options_<flavor>.dart` import.

### iOS — Xcode schemes

1. In Xcode: `Product → Scheme → Manage Schemes`, duplicate `Runner` into `dev` and `prod`.
2. For each scheme, go to `Build Settings → User-Defined` and add `FIREBASE_CONFIG_FILE` pointing to `${SRCROOT}/flavors/dev/GoogleService-Info.plist` (or prod).
3. In `Runner → Build Phases → Run Script`, add a script that copies the resolved `FIREBASE_CONFIG_FILE` into `${TARGET_BUILD_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist`.

```bash
# ios/Runner/copy-firebase-config.sh
cp "${FIREBASE_CONFIG_FILE}" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"
```

This is the canonical pattern from `codewithandrea.com/articles/flutter-firebase-multiple-flavors-flutterfire-cli`.

### Dart-side initialization

See [Initialization Sequence](#initialization-sequence-maindart--runapp). Each `main_<flavor>.dart` is a three-line file that imports its options and calls `bootstrap()`.

### App Check activation

```dart
await FirebaseAppCheck.instance.activate(
  androidProvider: kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
  appleProvider: kReleaseMode ? AppleProvider.deviceCheck : AppleProvider.debug,
);
```

**Debug providers** must be used on emulators/simulators and during development (otherwise you can't get App-Check-protected services to work). The resulting debug token is printed to console; paste it into the Firebase Console's App Check settings. Document this in README.

### Crashlytics wiring

Already shown in the bootstrap code. Key rule: `FlutterError.onError` and `PlatformDispatcher.instance.onError` must both be assigned — they cover different error paths. `runZonedGuarded` catches the rest.

**Release vs debug:** Crashlytics collects crashes in release builds by default but is opt-in in debug (`setCrashlyticsCollectionEnabled(false)` during dev if it gets noisy, though most teams leave it on).

---

## Auth Abstraction (AuthService sealed results + streams)

Confidence: HIGH — combines multiple credible sources (Code with Andrea's service-class pattern, Firebase Auth social provider docs, Context7 auto_route reevaluateListenable).

The `AuthService` contract is the most important new boundary in the refresh. Every downstream app builds its login UX against it.

### Domain types

```dart
// lib/core/auth/auth_user.dart
class AuthUser {
  const AuthUser({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.isEmailVerified,
  });
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isEmailVerified;
}
```

`AuthUser` is a **pure Dart type**, not a re-exported `firebase_auth.User`. Consumers (Cubits, guards) import nothing from `firebase_auth`.

### Sealed result type

```dart
// lib/core/auth/auth_result.dart
sealed class AuthResult {
  const AuthResult();
}

class AuthSuccess extends AuthResult {
  const AuthSuccess(this.user);
  final AuthUser user;
}

class AuthFailure extends AuthResult {
  const AuthFailure(this.failure);
  final Failure failure;
}

class AuthCancelled extends AuthResult {
  const AuthCancelled();
}
```

`AuthCancelled` is a first-class state because Google/Apple sign-in routinely cancel (user backs out of the native sheet), and that's neither success nor error.

### Abstract service

```dart
// lib/core/auth/auth_service.dart
abstract class AuthService {
  Stream<AuthUser?> get authStateChanges;
  AuthUser? get currentUser;

  Future<AuthResult> signInWithEmail({required String email, required String password});
  Future<AuthResult> signUpWithEmail({required String email, required String password});
  Future<AuthResult> signInWithGoogle();
  Future<AuthResult> signInWithApple();
  Future<void> signOut();
  Future<AuthResult> sendPasswordReset({required String email});
}
```

### Firebase implementation

```dart
// lib/core/auth/firebase_auth_service.dart
@LazySingleton(as: AuthService)
class FirebaseAuthService implements AuthService {
  FirebaseAuthService(this._firebaseAuth);
  final FirebaseAuth _firebaseAuth;

  @override
  Stream<AuthUser?> get authStateChanges => _firebaseAuth.authStateChanges().map(_mapUser);

  @override
  AuthUser? get currentUser => _mapUser(_firebaseAuth.currentUser);

  @override
  Future<AuthResult> signInWithEmail({required String email, required String password}) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return AuthSuccess(_mapUser(credential.user)!);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(Failure.auth(e.code, e.message));
    }
  }

  // ... other methods follow the same pattern

  AuthUser? _mapUser(User? user) => user == null ? null : AuthUser(
    uid: user.uid,
    email: user.email,
    displayName: user.displayName,
    photoUrl: user.photoURL,
    isEmailVerified: user.emailVerified,
  );
}
```

### Native provider wiring

- **Google Sign-In (Android):** SHA-1 and SHA-256 fingerprints added to Firebase Console per-flavor. `google-services.json` contains the resulting OAuth client ID.
- **Google Sign-In (iOS):** `CFBundleURLTypes` in `ios/flavors/<flavor>/Info.plist` contains the reversed-client-id from `GoogleService-Info.plist`.
- **Apple Sign-In (iOS only):** requires capability enabled in Xcode (Signing & Capabilities → `+` → Sign in with Apple). Entitlements file auto-updated.

The skeleton ships **zero login UI** — only the `AuthService` contract and its Firebase implementation. Downstream apps build their login screen and call `getIt<AuthService>().signInWithGoogle()`, `.signInWithApple()`, etc.

---

## Error Handling (Dart 3 sealed Failure hierarchy)

Confidence: HIGH — Dart language spec on sealed classes + current community consensus (multiple 2024-2026 articles).

### The shape

```dart
// lib/core/errors/failure.dart
sealed class Failure {
  const Failure(this.message);
  final String message;

  const factory Failure.localDataNotFound(String message) = LocalDataNotFoundFailure;
  const factory Failure.localDataSource(String message) = LocalDataSourceFailure;
  const factory Failure.remote(String message, {int? statusCode}) = RemoteFailure;
  const factory Failure.network(String message) = NetworkFailure;
  const factory Failure.auth(String code, String? message) = AuthFailure;
  const factory Failure.unexpected(String message) = UnexpectedFailure;
}

final class LocalDataNotFoundFailure extends Failure {
  const LocalDataNotFoundFailure(super.message);
}
final class LocalDataSourceFailure extends Failure {
  const LocalDataSourceFailure(super.message);
}
final class RemoteFailure extends Failure {
  const RemoteFailure(super.message, {this.statusCode});
  final int? statusCode;
}
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message);
}
final class AuthFailure extends Failure {
  const AuthFailure(this.code, String? message) : super(message ?? 'Auth error');
  final String code;
}
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message);
}
```

**Why `final class` on subtypes:** prevents third parties from subclassing, so the `switch` below is provably exhaustive. Dart's `sealed` keyword on the parent enforces the compiler check.

### The Result envelope

```dart
// lib/core/errors/result.dart
sealed class Result<T> {
  const Result();
}
final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}
final class Failed<T> extends Result<T> {
  const Failed(this.failure);
  final Failure failure;
}
```

(Named `Failed` to avoid clashing with `Failure`.)

### Repository pattern (replaces `Either<Failure, T>`)

```dart
Future<Result<Counter>> getCounter() async {
  try {
    final counter = await _localDataBase.getCounter();
    if (counter == null) {
      return const Failed(Failure.localDataNotFound('Counter not seeded'));
    }
    return Success(counter);
  } catch (e, s) {
    _logger.e('Local data source exception', error: e, stackTrace: s);
    return Failed(Failure.localDataSource(e.toString()));
  }
}

Stream<Result<Counter>> watchCounter() {
  return _localDataBase.watchCounter().map((counter) {
    if (counter == null) return const Failed(Failure.localDataNotFound('None'));
    return Success(counter);
  }).handleError((e, s) {
    _logger.e('Stream error', error: e, stackTrace: s);
    return Failed(Failure.localDataSource(e.toString()));
  });
}
```

### Cubit pattern matching

```dart
// home_cubit.dart
void _onCounterChange(Result<Counter> result) {
  switch (result) {
    case Success(:final value):
      emit(state.copyWith(status: HomePageStatus.success, counter: value));
    case Failed(:final failure):
      emit(state.copyWith(status: HomePageStatus.error, errorMessage: failure.message));
  }
}
```

And for failure-type specific handling:

```dart
void _onAuthResult(AuthResult result) {
  switch (result) {
    case AuthSuccess(:final user):
      emit(state.copyWith(status: LoginStatus.success, user: user));
    case AuthFailure(:final failure) when failure is AuthFailure && failure.code == 'user-not-found':
      emit(state.copyWith(status: LoginStatus.error, errorMessage: 'No account found'));
    case AuthFailure(:final failure):
      emit(state.copyWith(status: LoginStatus.error, errorMessage: failure.message));
    case AuthCancelled():
      emit(state.copyWith(status: LoginStatus.idle));
  }
}
```

The compiler **rejects non-exhaustive switches** on sealed types — so a new `AuthResult` subtype forces every consumer to handle it or explicitly `default:`.

### Why this over `dartz`

- `dartz` is effectively unmaintained in 2026 (confirmed by the rationale in `PROJECT.md`).
- Sealed classes give `fold`-equivalent ergonomics natively through pattern matching.
- Tooling: IntelliSense completes case patterns; the analyzer flags missing branches as errors; refactoring across 50 files becomes mechanical.
- No `.fold((l) => ..., (r) => ...)` lambda noise in call sites.

---

## RIVE Splash Integration

Confidence: MEDIUM — multiple community sources agree on the two-stage pattern; `flutter_native_splash` docs confirm the `remove()` lifecycle API.

### The two-stage handoff

1. **Stage 1 (native splash):** `flutter_native_splash` generates platform-native launch screens (Android launch theme, iOS launch storyboard) from an image. Paints instantly, before Flutter engine is up. Config lives in `pubspec.yaml` under `flutter_native_splash:` and is regenerated via `dart run flutter_native_splash:create`.

2. **Stage 2 (RIVE splash):** `SplashPage` is the initial route. It loads a `.riv` artboard, plays the animation, and on completion decides where to navigate (onboarding or home — the `OnboardingGuard` on `/home` handles the branch automatically).

### Wiring

```dart
// pubspec.yaml
flutter_native_splash:
  color: "#3643BA"  # AppColors.primary hex
  image: assets/images/native_splash_logo.png
  android_12:
    image: assets/images/native_splash_logo_android12.png
    color: "#3643BA"
```

```dart
// lib/features/splash/presentation/splash_page.dart
@RoutePage()
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  StateMachineController? _controller;

  @override
  void initState() {
    super.initState();
    // Remove the native splash once we've painted a frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
    });
  }

  void _onRiveInit(Artboard artboard) {
    _controller = StateMachineController.fromArtboard(artboard, 'Splash')!;
    artboard.addController(_controller!);
    // Listen for the end trigger / state
    _controller!.isActiveChanged.addListener(() {
      if (!_controller!.isActive) {
        context.router.replaceAll([const HomeRoute()]);   // guards redirect to onboarding if needed
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: RiveAnimation.asset(
          'assets/rive/splash.riv',
          onInit: _onRiveInit,
        ),
      ),
    );
  }
}
```

### Why `FlutterNativeSplash.remove()` in `SplashPage` not `bootstrap.dart`

If we removed it in `bootstrap.dart` before `runApp`, the user sees a white flash between native splash dismissal and the first Flutter frame. Holding the native splash until the RIVE widget paints its first frame (`addPostFrameCallback`) produces a visually seamless handoff.

### Ownership

- `SplashPage` owns the **stage-1-to-stage-2 handoff** (`FlutterNativeSplash.remove()`).
- `SplashPage` owns the **stage-2-to-app handoff** (listens to RIVE state-machine end trigger, calls `context.router.replaceAll([HomeRoute()])`).
- Guards on `HomeRoute` handle the onboarding/auth branching — `SplashPage` is unaware of it.

---

## Onboarding Flow Wiring

Confidence: HIGH — standard `PageView` + `shared_preferences` pattern; combined with auto_route guard pattern from Context7.

### The flow

1. App launches → native splash → RIVE splash → `SplashPage` navigates to `HomeRoute`.
2. `OnboardingGuard` on `HomeRoute` checks `PreferencesService.hasSeenOnboarding`. If false → `resolver.redirect(const OnboardingRoute())`.
3. User swipes through 3 slides (`PageView` with dot indicator and skip/next buttons).
4. On tap "Get Started" (last slide) or "Skip" (any slide): `OnboardingCubit.finish()` writes `hasSeenOnboarding = true` and emits navigation intent.
5. Page `BlocListener` sees navigation intent → `context.router.replaceAll([const HomeRoute()])`.
6. `HomeRoute` guard re-runs; this time `hasSeenOnboarding == true` → proceeds.

### PreferencesService (the guard's data source)

```dart
abstract class PreferencesService {
  bool get hasSeenOnboarding;
  Future<void> setHasSeenOnboarding(bool value);
}

@LazySingleton(as: PreferencesService)
class PreferencesServiceImpl implements PreferencesService {
  PreferencesServiceImpl(this._prefs);
  final SharedPreferences _prefs;
  static const _kHasSeenOnboarding = 'has_seen_onboarding';

  @override
  bool get hasSeenOnboarding => _prefs.getBool(_kHasSeenOnboarding) ?? false;

  @override
  Future<void> setHasSeenOnboarding(bool value) => _prefs.setBool(_kHasSeenOnboarding, value);
}
```

The `@LazySingleton` means `PreferencesService` is resolved once per app run, and the guard reads `hasSeenOnboarding` synchronously on every navigation — no async work needed.

---

## Coach Mark Service Wiring

Confidence: MEDIUM — `tutorial_coach_mark` API confirmed; the "service wrapper" pattern is our own synthesis from community examples.

### The abstraction

```dart
// lib/core/coach_mark/coach_mark_service.dart
abstract class CoachMarkService {
  void register({
    required String tourId,
    required GlobalKey key,
    required String description,
  });
  Future<void> showTour({required String tourId});
  void clear({required String tourId});
}

@LazySingleton(as: CoachMarkService)
class TutorialCoachMarkServiceImpl implements CoachMarkService {
  final Map<String, List<_Target>> _tours = {};

  @override
  void register({required String tourId, required GlobalKey key, required String description}) {
    _tours.putIfAbsent(tourId, () => []).add(_Target(key, description));
  }

  @override
  Future<void> showTour({required String tourId}) async {
    final targets = _tours[tourId];
    if (targets == null || targets.isEmpty) return;

    final tutorial = TutorialCoachMark(
      targets: targets.map((t) => TargetFocus(
        identify: t.key.toString(),
        keyTarget: t.key,
        contents: [TargetContent(child: Text(t.description))],
      )).toList(),
      onClickOverlay: (_) {},
      onFinish: () {},
    );
    tutorial.show(context: _findRootContext());
  }

  @override
  void clear({required String tourId}) => _tours.remove(tourId);
}
```

### Usage in a feature

```dart
class MyHomePage extends StatefulWidget {
  // ...
}

class _MyHomePageState extends State<MyHomePage> {
  final _fabKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    final coach = getIt<CoachMarkService>();
    coach.register(
      tourId: 'home',
      key: _fabKey,
      description: context.l10n.tutorial_incrementFab,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!getIt<PreferencesService>().hasSeenHomeTour) {
        await coach.showTour(tourId: 'home');
        await getIt<PreferencesService>().setHasSeenHomeTour(true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        key: _fabKey,
        onPressed: () => context.read<HomeCubit>().increment(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
```

**Key design decision:** targets register with a `tourId`, so a single feature can have multiple independent tours. The "seen" flag also lives in `PreferencesService` (one key per tour), keeping tour state colocated with other app preferences.

---

## Flavors Configuration (Android buildTypes + iOS schemes)

Confidence: HIGH — Flutter official docs + FlutterFire CLI docs.

### Android — `build.gradle` additions

```kotlin
android {
    defaultConfig {
        applicationId "com.example.skeleton"
        // ... minSdk, targetSdk, etc. from flutter create defaults
    }

    flavorDimensions += "env"
    productFlavors {
        create("dev") {
            dimension = "env"
            applicationIdSuffix = ".dev"
            versionNameSuffix = "-dev"
            resValue("string", "app_name", "Skeleton Dev")
        }
        create("prod") {
            dimension = "env"
            resValue("string", "app_name", "Skeleton")
        }
    }
}
```

The `applicationIdSuffix = ".dev"` means dev builds install as `com.example.skeleton.dev` and can coexist on-device with prod's `com.example.skeleton`. This is the **killer feature** of flavors — running both side by side.

Per-flavor `google-services.json` lives in `android/app/src/<flavor>/google-services.json` and is auto-picked by the Google Services Gradle plugin.

### iOS — Xcode schemes

For each flavor (`dev`, `prod`):

1. **Scheme:** `Product → Scheme → New Scheme → name = dev`. Repeat for prod.
2. **Configurations:** `Project → Info`, duplicate the three default configurations (`Debug`, `Release`, `Profile`) into `Debug-dev`, `Release-dev`, `Profile-dev`, `Debug-prod`, etc.
3. **User-defined build setting:** `FIREBASE_CONFIG_FILE = ${SRCROOT}/flavors/$(FLAVOR)/GoogleService-Info.plist` where `FLAVOR` is another user-defined per-configuration setting.
4. **Build phase script:** `cp "${FIREBASE_CONFIG_FILE}" "${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"`.
5. **Display name per scheme:** `INFOPLIST_KEY_CFBundleDisplayName = Skeleton Dev` for dev scheme, `Skeleton` for prod scheme — set as a build setting, not in Info.plist directly.
6. **Bundle ID per scheme:** `PRODUCT_BUNDLE_IDENTIFIER = com.example.skeleton.dev` for dev scheme, `com.example.skeleton` for prod scheme.

### Running

```bash
fvm flutter run --flavor dev -t lib/main_dev.dart
fvm flutter run --flavor prod -t lib/main_prod.dart
```

The `-t` flag picks the entrypoint; `--flavor` picks the Android product flavor and (via the `--flavor` to Xcode scheme mapping) the iOS scheme.

### Why not a single-entrypoint `--dart-define`-driven approach

Considered and rejected. Reasons:
- `firebase_options.dart` is statically imported; runtime branching on `String.fromEnvironment('FLAVOR')` would require either a runtime `Map` of options (fragile) or still two files (defeats the point).
- Crashlytics symbolication is cleaner with two entrypoints because the dSYM/mapping upload tooling keys off bundle ID.
- FlutterFire CLI expects this shape — going off the paved path costs reproducibility.

---

## Bootstrap Script Architecture

Confidence: MEDIUM — synthesized from `rename` package and `change_app_package_name` patterns; no single authoritative "best practices" source but the pattern is well-established.

### Invocation

```bash
dart run tool/bootstrap.dart \
  --name "MyAwesomeApp" \
  --bundle "com.mycompany.myawesomeapp" \
  --org "My Company"
```

### Responsibilities

1. **Validate inputs** (bundle ID format, name uniqueness, etc.)
2. **Confirm with user** ("About to rewrite 42 files; continue? [y/N]")
3. **Apply renames atomically** — all-or-nothing rollback on failure
4. **Run `flutter pub get`** + `build_runner` at the end

### The rename matrix

| Surface | File | Replacement |
|---------|------|-------------|
| Dart package | `pubspec.yaml` (`name:` field) | `skeleton` → snake_case(name) |
| Dart imports | all `lib/**/*.dart` | `package:skeleton/` → `package:<snake_name>/` |
| Android namespace | `android/app/build.gradle` | `com.example.skeleton` → bundle |
| Android applicationId | `android/app/build.gradle` | `com.example.skeleton` → bundle |
| Android package dir | `android/app/src/main/kotlin/com/example/skeleton/` | rename dirs |
| Android MainActivity | `MainActivity.kt` | `package com.example.skeleton` → `package <bundle>` |
| Android AndroidManifest | `android/app/src/main/AndroidManifest.xml` | `android:label` |
| Android res strings | `android/app/src/main/res/values/strings.xml` | `app_name` |
| iOS bundle id | `ios/Runner.xcodeproj/project.pbxproj` | `PRODUCT_BUNDLE_IDENTIFIER` per config |
| iOS display name | `ios/Runner/Info.plist` | `CFBundleDisplayName` + `CFBundleName` |
| iOS flavor plists | `ios/flavors/<flavor>/Info.plist` | per-flavor display name |
| Launcher icons | `android/app/src/<flavor>/res/mipmap-*/ic_launcher.png` | replace from `assets/icons/<flavor>.png` if provided |
| iOS launcher icons | `ios/Runner/Assets.xcassets/AppIcon.appiconset/` | ditto |
| Firebase options | `lib/firebase_options_*.dart` | placeholder warning to re-run `flutterfire configure` |

### Step-by-step (not atomic) — deliberate choice

The script prints each step as it runs, so if it fails at step 9 of 15 the user knows exactly where to pick up. A truly atomic rewrite would require staging in a temp clone of the repo; given this is a one-shot bootstrap, the step-by-step with clear error messages is both simpler and more debuggable.

**But**: the script **always runs `git status` at start** and refuses to proceed if the working tree has uncommitted changes. That way `git reset --hard HEAD` is the universal recovery, which is atomic at the repo level.

### File-level atomicity

Each file write goes through:

```dart
Future<void> atomicWrite(File file, String contents) async {
  final temp = File('${file.path}.tmp');
  await temp.writeAsString(contents);
  await temp.rename(file.path);
}
```

This guards against half-written files on crash.

### Launcher icons

Handled via `flutter_launcher_icons` (declared as dev dep); the bootstrap script just invokes `dart run flutter_launcher_icons` after dropping the user-provided icon file into the expected path.

### Post-rename tasks the script prints (but does NOT run)

- `flutterfire configure` for the new Firebase project(s) — interactive, can't be scripted
- Adding SHA keys to Firebase Console — manual
- Enabling Apple Sign-In capability in Xcode — GUI

---

## Build Order (phase dependencies)

The roadmap's phase structure falls out of these dependencies. Blockers are listed explicitly.

### Dependency graph

```
                    ┌─────────────────────────────┐
                    │ P1: Rebase native scaffolds │   ← MUST be first; changes
                    │     + pubspec merge         │      every file's ground truth
                    └─────────────┬───────────────┘
                                  │
         ┌────────────────────────┼────────────────────────┐
         ▼                        ▼                        ▼
 ┌───────────────┐        ┌───────────────┐        ┌───────────────┐
 │ P2a: Sealed    │        │ P2b: Drift     │        │ P2c: Firebase  │
 │ Failure +      │        │ migration of   │        │ core + App     │
 │ Result<T>      │        │ counter        │        │ Check +        │
 │                │        │ example        │        │ Crashlytics    │
 └───────┬───────┘        └───────────────┘        └───────┬───────┘
         │                                                 │
         │                                                 │
         │                 ┌───────────────────────────────┤
         │                 │                               │
         │                 ▼                               ▼
         │         ┌───────────────┐               ┌───────────────┐
         │         │ P3a: Flavors   │               │ P3b: Auth      │
         │         │ (Android+iOS)  │               │ service +      │
         │         │ + per-flavor   │               │ Firebase Auth  │
         │         │ FlutterFire    │               │ providers      │
         │         └───────┬───────┘               └───────┬───────┘
         │                 │                               │
         └─────────────────┤                               │
                           ▼                               ▼
                   ┌───────────────┐               ┌───────────────┐
                   │ P4a: Onboarding│               │ P4b: Coach mark│
                   │ + OnboardingG │               │ service        │
                   │ + prefs       │               │                │
                   └───────┬───────┘               └───────────────┘
                           │
                           ▼
                   ┌───────────────┐
                   │ P5: RIVE splash│
                   │ + splash page  │
                   └───────┬───────┘
                           │
                           ▼
                   ┌───────────────┐
                   │ P6: Bootstrap  │
                   │ script +       │
                   │ README         │
                   └───────────────┘
```

### Critical path

`P1 → P2c → P3a → P3b → P4a → P5 → P6` is the single longest dependency chain. Roughly:

- **P1** (rebase) has to land alone — nothing else can begin until the native dirs are current.
- **P2a/P2b/P2c** can be worked **in parallel** after P1 (no inter-dependencies: Sealed Failure is pure Dart, Drift is a pure `core/database/` swap, Firebase core is `bootstrap.dart` wiring).
- **P3a** depends on P2c (flavors plug Firebase options into two entrypoints).
- **P3b** depends on P2c (Auth needs Firebase init) — P3a and P3b are independent of each other.
- **P4a** depends on P3b (guard needs `AuthService` to co-exist; the onboarding guard alone doesn't, but the route setup is shared).
- **P4b** depends on P4a (coach marks use the same `PreferencesService`).
- **P5** depends on P4a (splash → onboarding/home routing relies on guard chain).
- **P6** depends on everything (bootstrap script rewrites all the surfaces).

### Parallelization opportunities

**High parallelism window:** after P1 lands, three developers can work on P2a/P2b/P2c simultaneously with zero merge conflicts (they touch disjoint files).

**Testing parallelism:** example test for counter (P2b tail-end task) can be written in parallel with P3a/P3b.

**Docs parallelism:** README update can happen in parallel with P6 bootstrap script, syncing on API names once the script is stable.

### Reversibility

Every phase is a single commit (or small series) on a feature branch off `2026-update`. Each phase:

1. Ships behind a compile check (`flutter run --flavor dev`)
2. Preserves test suite (tests must pass at end of each phase)
3. Merges to `2026-update` with a descriptive commit message

If a phase needs to be rolled back, `git revert <phase-commit>` on `2026-update` does it cleanly because phases never reach across each other's file boundaries.

### Research flags

| Phase | Likely needs deeper research |
|-------|------------------------------|
| P1 | LOW — mechanical procedure documented above |
| P2a | LOW — pure Dart refactor |
| P2b | MEDIUM — Drift schema design for future apps, migration testing |
| P2c | MEDIUM — Firebase Console per-flavor project setup is interactive; document expected prompts |
| P3a | HIGH — iOS Xcode scheme wiring is notoriously finicky; budget extra time |
| P3b | MEDIUM — Google + Apple native provider wiring (SHA keys, URL schemes, Apple capability) varies per provider |
| P4a | LOW — standard `PageView` + `shared_preferences` |
| P4b | LOW — `tutorial_coach_mark` is well-documented |
| P5 | MEDIUM — RIVE + native-splash handoff timing; design a test `.riv` file |
| P6 | HIGH — bootstrap script is bespoke; needs end-to-end test on a real renamed copy |

---

## Sources

### HIGH confidence (Context7 / official docs)

- [auto_route library — Route Guards (Context7)](https://pub.dev/documentation/auto_route/latest/auto_route/AutoRouteGuard-class.html) — Context7 ID `/milad-akarie/auto_route_library`
- [auto_route — reevaluateListenable](https://pub.dev/packages/auto_route) — Context7 extracted usage
- [drift — Migration strategy (Context7)](https://drift.simonbinder.eu/migrations/) — Context7 ID `/simolus3/drift`
- [drift_flutter — driftDatabase helper](https://pub.dev/packages/drift_flutter)
- [Firebase — Add Firebase to your Flutter app](https://firebase.google.com/docs/flutter/setup)
- [Firebase Crashlytics for Flutter — Get started](https://firebase.google.com/docs/crashlytics/flutter/get-started)
- [Flutter — Set up flavors for Android](https://docs.flutter.dev/deployment/flavors)
- [Flutter — Set up flavors for iOS and macOS](https://docs.flutter.dev/deployment/flavors-ios)
- [FlutterFire CLI](https://firebase.flutter.dev/docs/cli/)
- [Flutter — Build for and integrate with multiple platforms](https://docs.flutter.dev/platform-integration)

### MEDIUM confidence (community articles verified by multiple sources)

- [Code with Andrea — Flutter & Firebase with Multiple Flavors](https://codewithandrea.com/articles/flutter-firebase-multiple-flavors-flutterfire-cli/)
- [Code with Andrea — Designing an Authentication Service API](https://codewithandrea.com/articles/designing-an-authentication-service-api/)
- [Drift FAQ — Singleton pattern](https://drift.simonbinder.eu/faq/)
- [Drift — Local Database for Flutter Part 1: Intro, Setup, Migration](https://r1n1os.medium.com/drift-local-database-for-flutter-part-1-intro-setup-and-migration-09a64d44f6df)
- [flutter_native_splash README](https://pub.dev/packages/flutter_native_splash)
- [flutter_native_splash — smooth transition issue #692](https://github.com/jonbhanson/flutter_native_splash/issues/692)
- [tutorial_coach_mark — package docs](https://pub.dev/packages/tutorial_coach_mark)
- [Tomas Repcik — Stop using Freezed map/when; use sealed classes](https://tomasrepcik.dev/blog/2024/2024-03-27-freezed-pattern-matching/)
- [Dart 3 Sealed Classes feature specification](https://github.com/dart-lang/language/blob/main/accepted/future-releases/sealed-types/feature-specification.md)
- [Miquido — Flutter App Development Best Practices 2026](https://www.miquido.com/blog/flutter-app-best-practices/)

### LOW confidence (ecosystem color, single-source)

- [Sagnik Bhattacharya — Flutter Development Guide 2026](https://sagnikbhattacharya.com/blog/flutter-guide)
- [FilledStacks — Sign in with Google or Apple](https://www.filledstacks.com/post/sign-in-with-google-or-apple-sign-in-using-flutter/)
- [Rename CLI package](https://pub.dev/packages/rename)
- [change_app_package_name](https://pub.dev/packages/change_app_package_name)

---

*Architecture research: 2026-04-16 — Flutter 3.41+ / Dart 3.x / Firebase 11 / drift 2.32+*
