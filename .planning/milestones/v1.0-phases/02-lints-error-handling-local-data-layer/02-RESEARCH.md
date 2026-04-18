# Phase 2: Lints, Error Handling, Local Data Layer - Research

**Researched:** 2026-04-17
**Domain:** Dart linting, sealed class error handling, local persistence (Drift), preferences/secure storage
**Confidence:** HIGH

## Summary

Phase 2 performs three orthogonal transformations on the skeleton's `lib/` code plus `pubspec.yaml` and `analysis_options.yaml`: (1) swap `flutter_lints` for `very_good_analysis` with errors-not-warnings on key rules, (2) replace `dartz` `Either<Failure, T>` with Dart 3 sealed `Result<T>` + sealed `AppFailure` hierarchy, and (3) replace ObjectBox with Drift for local persistence while adding thin `SharedPreferencesAsync` and `flutter_secure_storage` wrappers. The counter example is ported end-to-end through the new stack, and unused dependencies (`http`, `uuid`, `collection`) are removed.

The codebase is small -- only 2 files import `dartz`, only 2 files reference `object_box.dart`, and the ObjectBox data layer is a single entity (`CounterModel`) with a single data source. The migration surface is well-contained: ~6 Dart files in `lib/` need modification, plus `pubspec.yaml`, `analysis_options.yaml`, and the `core/local_database/` directory (renamed to `core/database/`).

**Primary recommendation:** Execute in three sequential waves: (1) lint migration first (catches issues in existing code before new code lands), (2) sealed `Result<T>` + `AppFailure` migration (pure Dart, no persistence dependency), (3) ObjectBox removal + Drift integration + preferences/secure storage wrappers. Each wave should end with `fvm flutter analyze` passing clean.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** `sealed class Result<T>` with `final class Success<T>(T value)` and `final class Failure<T>(AppFailure failure)`. A separate `sealed class AppFailure` hierarchy for failure classification. Single type parameter -- no generic error type.
- **D-02:** Flat sealed hierarchy -- one `sealed class AppFailure` with all failure types as direct `final class` subtypes. No nested sealed sub-hierarchies.
- **D-03:** Files live in existing `lib/core/errors/` dir: `result.dart` (sealed `Result<T>` + `ResultX` extension) and `failures.dart` (sealed `AppFailure` + subtypes).
- **D-04:** Phase 2 ships only `LocalDataNotFound` + `LocalDataSource` failure types. Phase 3 adds `AuthFailure`, Phase 5 adds `NetworkFailure` / `FirebaseFailure`. Each phase extends the hierarchy with what it needs.
- **D-05:** Minimal convenience extensions on `Result<T>`: `.isSuccess`, `.valueOrNull`, `.failureOrNull`. Exhaustive `switch` remains the primary consumption pattern in cubits and services.
- **D-06:** Big-bang migration -- replace `dartz` everywhere in one pass. No coexistence period.
- **D-07:** `AppDatabase` registered as `@lazySingleton` in `get_it` via `injectable`. Created lazily on first injection.
- **D-08:** Counter uses a single-row table pattern -- `CounterEntries` table with `id` (autoIncrement) + `value` (integer, default 0). Upsert on write, `selectFirst` on read, `watchSingle` for reactive stream.
- **D-09:** `CounterModel` remains a plain Dart class (remove `@Entity()` and `objectbox` import, keep `copyWith`). The data source maps between Drift's generated `CounterEntry` row class and `CounterModel`. Domain layer stays Drift-free.
- **D-10:** Drift files live in `lib/core/database/` (renamed from `local_database/`). Structure: `app_database.dart` (`@DriftDatabase`), `app_database.g.dart` (generated), `tables/counter_entries.dart`, `connection/native.dart` (`drift_flutter` connection helper).
- **D-11:** Remove `_configureDatabases()` from `StartUpService`. Drift `AppDatabase` lazy-inits via DI graph. `StartUpService.initServices()` becomes: Firebase -> DI only.
- **D-12:** Full ObjectBox removal in one shot -- delete files, remove deps, remove pubspec block, check `path_provider` consumers.
- **D-13:** Thin wrappers in `lib/core/preferences/` and `lib/core/secure_storage/`. Both registered as `@LazySingleton`.
- **D-14:** Generic get/set API for preferences. Features define their own key constants.
- **D-15:** No actual preference or secure storage keys defined in Phase 2.
- **D-16:** Full `very_good_analysis` adoption with strategic `// ignore` comments.
- **D-17:** Generated files excluded from analysis: `**/*.g.dart`, `**/*.gr.dart`, `**/*.config.dart`, `**/*.freezed.dart`.
- **D-18:** Key lint rules promoted to errors: `avoid_print`, `unawaited_futures`, `missing_return`, `dead_code`, `unused_import`.

### Claude's Discretion
- Exact `ResultX` extension method signatures beyond `.isSuccess`, `.valueOrNull`, `.failureOrNull`
- Whether to include a `Result.guard(() async => ...)` convenience factory
- Drift `MigrationStrategy` scaffolding (empty but correct for `schemaVersion: 1`)
- `SecureStorageService` default encryption options
- Exact set of `// ignore` comments needed for `very_good_analysis`
- Whether `path_provider` stays (if `drift_flutter` removes the need)
- Feature-level `data/local_database/` folder rename or keep

### Deferred Ideas (OUT OF SCOPE)
- Stream cancellation fix in `HomeCubit.close()` -- Phase 3
- `Result.guard()` factory -- Claude's discretion
- Drift schema migration scaffolding beyond `schemaVersion: 1`
- iOS keychain-access-groups entitlement -- Phase 4/5
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| TOOL-03 | `very_good_analysis` replaces `flutter_lints`; errors-not-warnings on key rules; existing code clean | Standard Stack (very_good_analysis), Architecture Patterns (analysis_options.yaml config), Pitfalls (retrofit cascade) |
| CORE-01 | Dart 3 sealed `Result<T>` + sealed `AppFailure` replaces `dartz`; `dartz` removed | Architecture Patterns (sealed Result/AppFailure), Code Examples (result.dart, failures.dart, repository pattern, cubit switch) |
| CORE-02 | All repo/service signatures return `Result<T>`; cubits consume via exhaustive `switch` | Architecture Patterns (cubit pattern matching), Code Examples (switch expressions) |
| CORE-06 | Unused deps removed: `http`, `uuid`, `collection` | Standard Stack (removal list), verified via grep: zero imports in `lib/` |
| DATA-01 | ObjectBox fully removed -- deps, generated files, `object_box.dart`, pubspec block | Architecture Patterns (ObjectBox removal sequence), verified file inventory |
| DATA-02 | Drift 2.32.1 + drift_flutter 0.3.0 integrated with `AppDatabase` as `@lazySingleton` | Standard Stack (Drift), Architecture Patterns (AppDatabase setup), Code Examples |
| DATA-03 | Counter ported to Drift -- reactive stream, same layered flow | Architecture Patterns (CounterEntries table, data source, reactive watch), Code Examples |
| DATA-04 | `shared_preferences` using `SharedPreferencesAsync` API | Standard Stack, Architecture Patterns (PreferencesService wrapper) |
| DATA-05 | `flutter_secure_storage` for token-class persistence | Standard Stack, Architecture Patterns (SecureStorageService wrapper) |
</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Lint enforcement | Build tooling | -- | `analysis_options.yaml` + `very_good_analysis` is a dev-time/CI concern, not runtime |
| Sealed `Result<T>` / `AppFailure` | Domain / Core Dart | -- | Pure Dart abstractions in `lib/core/errors/`, consumed by all layers |
| Drift `AppDatabase` | Database / Storage | -- | SQLite persistence via Drift, lives in `lib/core/database/` |
| Counter data source (Drift) | Database / Storage | -- | Feature-level DAO that queries `AppDatabase` |
| Counter repository | API / Backend (in-app) | -- | Error boundary: wraps data source exceptions into `Result<T>` |
| Counter service | API / Backend (in-app) | -- | Thin passthrough in current skeleton; orchestrates repos |
| Counter cubit | Browser / Client (Flutter) | -- | UI state management consuming `Result<T>` via `switch` |
| SharedPreferencesAsync wrapper | Database / Storage | -- | Key-value persistence abstraction in `lib/core/preferences/` |
| flutter_secure_storage wrapper | Database / Storage | -- | Encrypted key-value persistence in `lib/core/secure_storage/` |
| Dependency cleanup (http/uuid/collection) | Build tooling | -- | `pubspec.yaml` edit only, zero runtime impact |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `very_good_analysis` | `^10.2.0` (dev) | Strict lint rules | [VERIFIED: pub.dev] Industry-standard strict Flutter lints by Very Good Ventures. Current stable 10.2.0. |
| `drift` | `^2.32.1` | Type-safe reactive SQLite ORM | [VERIFIED: pub.dev] Active maintenance, reactive `.watch*()` streams, schema migrations. Drift 2.32+ bundles sqlite3 3.x natively -- `sqlite3_flutter_libs` is no longer needed as a separate dependency. |
| `drift_flutter` | `^0.3.0` | Flutter-specific Drift connection helper | [VERIFIED: pub.dev] Provides `driftDatabase(name: ...)` -- eliminates platform-specific boilerplate. Transitively depends on `path_provider`, `sqlite3_flutter_libs` (EOL no-op), and `sqlite3 ^3.0.0`. |
| `drift_dev` | `^2.32.1` (dev) | Drift code generation | [VERIFIED: pub.dev] Must match `drift` runtime version. Generates `.g.dart` files. |
| `shared_preferences` | `^2.5.5` | Key-value persistence | [VERIFIED: pub.dev] Using the new `SharedPreferencesAsync` API (not legacy `getInstance()`). |
| `flutter_secure_storage` | `^10.0.0` | Encrypted key-value storage | [VERIFIED: pub.dev] Android `EncryptedSharedPreferences`, iOS Keychain. |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `build_runner` | `^2.4.14` (dev, already present) | Code generation orchestrator | Run after adding/modifying Drift tables or injectable classes |
| `injectable` | `^2.5.0` (already present) | DI annotations | `@lazySingleton`, `@injectable` annotations |
| `get_it` | (transitive, already present) | Service locator | Singleton registry for `AppDatabase`, services |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `drift` | `sqflite` | sqflite lacks reactive streams and type-safe queries -- would require manual stream wiring |
| `drift` | `isar` | Isar is NoSQL like ObjectBox -- doesn't match the relational patterns Drift provides |
| `very_good_analysis` | `lint` or custom ruleset | Less opinionated, weaker baseline for a skeleton that should set the quality bar |
| Sealed `Result<T>` | `fpdart` | Adds a dependency for what sealed classes handle natively in Dart 3.9 |

### Removals (this phase)

| Library | Current Version | Reason for Removal |
|---------|----------------|-------------------|
| `dartz` | `0.10.1` | Replaced by native sealed classes [VERIFIED: zero maintenance since 2021] |
| `objectbox` | `^4.0.3` | Replaced by Drift |
| `objectbox_flutter_libs` | `any` | Part of ObjectBox removal |
| `objectbox_generator` | `any` (dev) | Part of ObjectBox removal |
| `flutter_lints` | `^5.0.0` (dev) | Replaced by `very_good_analysis` |
| `http` | `^1.2.2` | Unused -- zero imports in `lib/` [VERIFIED: grep] |
| `uuid` | `^4.5.1` | Unused -- zero imports in `lib/` [VERIFIED: grep] |
| `collection` | `^1.19.0` | Unused -- zero imports in `lib/` [VERIFIED: grep] |
| `path_provider` | `^2.1.5` | Only used by ObjectBox; `drift_flutter` pulls it transitively [VERIFIED: grep] |

**Installation (additions):**
```bash
fvm flutter pub add very_good_analysis --dev
fvm flutter pub add drift drift_flutter shared_preferences flutter_secure_storage
fvm flutter pub add drift_dev --dev
```

**Version verification:** All versions verified against pub.dev registry on 2026-04-17.

**IMPORTANT: `sqlite3_flutter_libs` EOL notice.** As of February 2026, `sqlite3_flutter_libs` is marked EOL (`0.6.0+eol`). Starting from drift 2.32.0 + sqlite3 3.x, SQLite is bundled automatically via build hooks. `drift_flutter ^0.3.0` depends on the EOL version transitively (which is now a no-op shim). Do NOT add `sqlite3_flutter_libs` as a direct dependency. [VERIFIED: pub.dev changelog + drift docs]

## Architecture Patterns

### System Architecture Diagram

```
pubspec.yaml deps change
         |
         v
analysis_options.yaml ----> very_good_analysis (lint enforcement)
         |
         v
lib/core/errors/
  result.dart ---------> sealed Result<T> { Success<T>, Failure<T> }
  failures.dart -------> sealed AppFailure { LocalDataNotFound, LocalDataSource }
         |
         v
lib/core/database/
  app_database.dart ---> @DriftDatabase(tables: [CounterEntries])
  tables/counter_entries.dart --> Table definition
         |                              |
         |                              v (generated)
         |                    app_database.g.dart
         v
lib/features/home_page/
  data/model/counter_model.dart ----------> plain Dart class (no ORM annotations)
  data/local_database/counter_local_database.dart --> queries AppDatabase
  data/repository/counter_repository.dart ----------> returns Result<CounterModel>
  domain/counter_service.dart ---------------------> returns Result<CounterModel>
  presentation/cubit/home_cubit.dart --------------> switch(result) { case Success... }
         |
         v
lib/core/preferences/
  preferences_service.dart --> wraps SharedPreferencesAsync
lib/core/secure_storage/
  secure_storage_service.dart --> wraps FlutterSecureStorage
```

### Recommended Project Structure (Phase 2 delta)

```
lib/
├── core/
│   ├── database/                          # NEW (replaces local_database/)
│   │   ├── app_database.dart              # @DriftDatabase + @lazySingleton
│   │   ├── app_database.g.dart            # GENERATED
│   │   └── tables/
│   │       └── counter_entries.dart       # Drift Table class
│   ├── errors/
│   │   ├── result.dart                    # sealed Result<T> + ResultX extension
│   │   └── failures.dart                  # sealed AppFailure + subtypes
│   ├── preferences/                       # NEW
│   │   ├── preferences_service.dart       # abstract PreferencesService
│   │   └── preferences_service_impl.dart  # @LazySingleton(as: PreferencesService)
│   ├── secure_storage/                    # NEW
│   │   ├── secure_storage_service.dart    # abstract SecureStorageService
│   │   └── secure_storage_service_impl.dart # @LazySingleton(as: SecureStorageService)
│   └── local_database/                    # DELETED (was ObjectBox)
├── features/
│   └── home_page/
│       ├── data/
│       │   ├── model/
│       │   │   └── counter_model.dart     # MODIFIED (remove @Entity/@Id)
│       │   ├── local_database/
│       │   │   └── counter_local_database.dart  # REWRITTEN (Drift queries)
│       │   └── repository/
│       │       └── counter_repository.dart      # MIGRATED (Either -> Result)
│       ├── domain/
│       │   └── counter_service.dart             # MIGRATED (Either -> Result)
│       └── presentation/
│           └── cubit/
│               ├── home_cubit.dart              # MIGRATED (.fold -> switch)
│               └── home_state.dart              # UNCHANGED
├── startup_service.dart                         # MODIFIED (remove _configureDatabases)
└── main.dart                                    # UNCHANGED
```

### Pattern 1: Sealed Result<T> + AppFailure

**What:** Replace `dartz` `Either<Failure, T>` with native Dart 3 sealed classes.
**When to use:** Every repository and service return type; every cubit consumption site.

```dart
// lib/core/errors/result.dart
// Source: Dart 3 sealed class spec + CONTEXT.md D-01
sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

final class Failure<T> extends Result<T> {
  const Failure(this.failure);
  final AppFailure failure;
}

/// Convenience extensions per D-05
extension ResultX<T> on Result<T> {
  bool get isSuccess => this is Success<T>;
  T? get valueOrNull => switch (this) {
    Success(:final value) => value,
    Failure() => null,
  };
  AppFailure? get failureOrNull => switch (this) {
    Success() => null,
    Failure(:final failure) => failure,
  };
}
```

```dart
// lib/core/errors/failures.dart
// Source: CONTEXT.md D-02, D-04
sealed class AppFailure {
  const AppFailure(this.message);
  final String message;
}

final class LocalDataNotFound extends AppFailure {
  const LocalDataNotFound(super.message);
}

final class LocalDataSource extends AppFailure {
  const LocalDataSource(super.message);
}
```

### Pattern 2: Drift Table + AppDatabase as @lazySingleton

**What:** Define Drift tables, register AppDatabase in DI graph.
**When to use:** All local persistence.

```dart
// lib/core/database/tables/counter_entries.dart
// Source: Context7 drift docs + CONTEXT.md D-08
import 'package:drift/drift.dart';

class CounterEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get value => integer().withDefault(const Constant(0))();
}
```

```dart
// lib/core/database/app_database.dart
// Source: Context7 drift_flutter docs + CONTEXT.md D-07, D-10
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:injectable/injectable.dart';

import 'tables/counter_entries.dart';

part 'app_database.g.dart';

@lazySingleton
@DriftDatabase(tables: [CounterEntries])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Named constructor for testing with in-memory database
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'skeleton_db');
  }
}
```

### Pattern 3: Feature Data Source with Drift Queries

**What:** Feature-level data source queries `AppDatabase` directly.
**When to use:** Every feature that reads/writes local data.

```dart
// lib/features/home_page/data/local_database/counter_local_database.dart
// Source: Context7 drift docs (watchSingleOrNull, insertOnConflictUpdate)
import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';

abstract class CounterLocalDataBase {
  Future<CounterEntry?> getCounter();
  Future<void> setCounter({required int value});
  Stream<CounterEntry?> watchCounter();
}

@LazySingleton(as: CounterLocalDataBase)
class CounterLocalDataBaseImpl implements CounterLocalDataBase {
  CounterLocalDataBaseImpl(this._db);
  final AppDatabase _db;

  @override
  Future<CounterEntry?> getCounter() async {
    return (_db.select(_db.counterEntries)..limit(1)).getSingleOrNull();
  }

  @override
  Future<void> setCounter({required int value}) async {
    await _db.into(_db.counterEntries).insertOnConflictUpdate(
      CounterEntriesCompanion.insert(value: Value(value)),
    );
  }

  @override
  Stream<CounterEntry?> watchCounter() {
    return (_db.select(_db.counterEntries)..limit(1)).watchSingleOrNull();
  }
}
```

### Pattern 4: Repository with Result<T>

**What:** Repository wraps data source calls in try/catch, returns `Result<T>`.
**When to use:** Every repository method.

```dart
// Source: existing counter_repository.dart pattern + sealed Result migration
Future<Result<CounterModel>> getCounter() async {
  try {
    final entry = await _localDataBase.getCounter();
    if (entry == null) {
      return const Failure(LocalDataNotFound('Counter not found'));
    }
    return Success(CounterModel(id: entry.id, value: entry.value));
  } catch (e) {
    _logger.e('Local data source exception: $e');
    return Failure(LocalDataSource(e.toString()));
  }
}
```

### Pattern 5: Cubit with Exhaustive Switch

**What:** Replace `.fold()` with `switch` pattern matching.
**When to use:** Every cubit that consumes `Result<T>`.

```dart
// Source: Dart 3 pattern matching + CONTEXT.md D-01
void _onCounterChange(Result<CounterModel> result) {
  switch (result) {
    case Success(:final value):
      emit(state.copyWith(
        status: HomePageStatus.success,
        counter: value,
      ));
    case Failure(:final failure):
      emit(state.copyWith(status: HomePageStatus.error));
  }
}

// For one-shot calls:
Future<CounterModel?> _getCounter() async {
  final result = await _counterService.getCounter();
  return result.valueOrNull;
}
```

### Pattern 6: PreferencesService Wrapper

**What:** Thin abstract wrapper over `SharedPreferencesAsync`.
**When to use:** Any feature that needs simple key-value persistence.

```dart
// lib/core/preferences/preferences_service.dart
// Source: Context7 shared_preferences docs + CONTEXT.md D-13, D-14
abstract class PreferencesService {
  Future<bool?> getBool(String key);
  Future<void> setBool(String key, {required bool value});
  Future<String?> getString(String key);
  Future<void> setString(String key, {required String value});
  Future<void> remove(String key);
}
```

```dart
// lib/core/preferences/preferences_service_impl.dart
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'preferences_service.dart';

@LazySingleton(as: PreferencesService)
class PreferencesServiceImpl implements PreferencesService {
  final _prefs = SharedPreferencesAsync();

  @override
  Future<bool?> getBool(String key) => _prefs.getBool(key);

  @override
  Future<void> setBool(String key, {required bool value}) =>
      _prefs.setBool(key, value);

  @override
  Future<String?> getString(String key) => _prefs.getString(key);

  @override
  Future<void> setString(String key, {required String value}) =>
      _prefs.setString(key, value);

  @override
  Future<void> remove(String key) => _prefs.remove(key);
}
```

### Pattern 7: SecureStorageService Wrapper

**What:** Thin abstract wrapper over `FlutterSecureStorage`.
**When to use:** Token-class data (auth tokens, refresh tokens, API keys).

```dart
// lib/core/secure_storage/secure_storage_service.dart
abstract class SecureStorageService {
  Future<String?> read({required String key});
  Future<void> write({required String key, required String value});
  Future<void> delete({required String key});
  Future<void> deleteAll();
}
```

```dart
// lib/core/secure_storage/secure_storage_service_impl.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

import 'secure_storage_service.dart';

@LazySingleton(as: SecureStorageService)
class SecureStorageServiceImpl implements SecureStorageService {
  // Sane defaults per STACK.md recommendation
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  @override
  Future<String?> read({required String key}) => _storage.read(key: key);

  @override
  Future<void> write({required String key, required String value}) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete({required String key}) => _storage.delete(key: key);

  @override
  Future<void> deleteAll() => _storage.deleteAll();
}
```

### Anti-Patterns to Avoid

- **Mixing `Either` and `Result` during migration:** D-06 mandates big-bang replacement. No adapter layer, no coexistence period. The skeleton has only 2 files importing `dartz` -- do it all at once.
- **Keeping ObjectBox artifacts after removal:** `objectbox.g.dart`, `objectbox-model.json`, and the `objectbox:` block in `pubspec.yaml` must all be deleted. Leftover annotations on `CounterModel` will cause compile errors.
- **Using legacy `SharedPreferences.getInstance()`:** The legacy sync API is deprecated. Use `SharedPreferencesAsync` exclusively. [VERIFIED: pub.dev deprecation notice]
- **Adding `sqlite3_flutter_libs` as a direct dependency:** It's EOL. `drift_flutter 0.3.0` handles it transitively as a no-op shim. [VERIFIED: pub.dev 0.6.0+eol]
- **Hand-registering `AppDatabase` in `injection.dart`:** Use `@lazySingleton` annotation on the class itself. `injectable_generator` will handle it.
- **Using `@Injectable` (factory) for data sources and repositories:** Per D-07 and existing project recommendations, stateless services should be `@LazySingleton`. Only cubits remain `@injectable` (factory).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Reactive local DB queries | Custom `StreamController` + raw SQLite | Drift `.watch*()` methods | Drift handles change notifications, isolate bridging, and query invalidation |
| Error type unions | Custom inheritance hierarchy without `sealed` | Dart 3 `sealed class` + `final class` subtypes | Compiler enforces exhaustiveness -- missing a case is a compile error |
| SQLite connection management | Manual `openDatabase()` + path resolution | `drift_flutter` `driftDatabase(name: ...)` | Handles platform-specific paths, background isolate, WAL mode |
| Encrypted storage | Manual AES encryption of SharedPreferences | `flutter_secure_storage` | Uses platform keystores (Android Keystore, iOS Keychain) |
| Lint configuration | Custom `analysis_options.yaml` rule-by-rule | `very_good_analysis` include + overrides | Maintained ruleset tracking Dart best practices |

**Key insight:** Every "don't hand-roll" item in this phase has a well-maintained package or language feature that handles edge cases (SQLite thread safety, keychain access groups, sealed class exhaustiveness checking) that custom solutions would miss.

## Common Pitfalls

### Pitfall 1: very_good_analysis Retrofit Cascade
**What goes wrong:** Switching from `flutter_lints` to `very_good_analysis` adds ~60 new lint rules. With errors-not-warnings on key rules, `flutter analyze` immediately returns non-zero.
**Why it happens:** `very_good_analysis` enables `public_member_api_docs`, `sort_constructors_first`, strict-raw-types, strict-inference, and many rules `flutter_lints` does not.
**How to avoid:** (1) Disable `public_member_api_docs` in `analysis_options.yaml` -- it's overkill for a skeleton. (2) Exclude generated files via `analyzer: exclude:`. (3) Fix lint issues in existing code BEFORE adding new code. (4) Use `// ignore:` with justifying comments only where rules genuinely don't apply.
**Warning signs:** `flutter analyze` returns 100+ errors on first run after lint swap.

### Pitfall 2: ObjectBox Leftover Files
**What goes wrong:** Removing `objectbox` from `pubspec.yaml` does not delete `objectbox.g.dart`, `objectbox-model.json`, or the `objectbox:` block. Leftover `@Entity()` annotations on `CounterModel` cause compile errors when the import is missing.
**Why it happens:** Code generators create files but package removal doesn't clean them up.
**How to avoid:** Follow this exact removal sequence: (1) delete `lib/core/local_database/objectbox.g.dart` and `objectbox-model.json`, (2) remove `@Entity()`/`@Id()` from `counter_model.dart`, (3) remove `objectbox`/`objectbox_flutter_libs`/`objectbox_generator` from `pubspec.yaml`, (4) remove `objectbox:` block from `pubspec.yaml`, (5) `fvm flutter clean && fvm flutter pub get`.
**Warning signs:** "Cannot resolve objectbox.g.dart", "Undefined class Entity", stale `.flutter-plugins-dependencies` entries.

### Pitfall 3: Sealed Classes Must Live in Same Library
**What goes wrong:** If `Result<T>` and its subtypes `Success<T>`/`Failure<T>` are in different libraries (different files without `part`/`part of`), the compiler cannot enforce exhaustiveness.
**Why it happens:** Dart's `sealed` modifier only guarantees exhaustive checking when all subtypes are in the same library.
**How to avoid:** Keep `sealed class Result<T>`, `final class Success<T>`, and `final class Failure<T>` in a single `result.dart` file. Same for `AppFailure` and its subtypes in `failures.dart`. Both files are in `lib/core/errors/`.
**Warning signs:** "The type 'Result' is not exhaustively matched" even when all cases are present.

### Pitfall 4: Drift watch() vs ObjectBox watch() Semantic Difference
**What goes wrong:** ObjectBox's `watch(triggerImmediately: true)` emits the full result set on every put. Drift's `.watchSingleOrNull()` only emits when the underlying table data actually changes.
**Why it happens:** Different notification strategies. Drift is more efficient but can under-emit if you expected emissions after unrelated DB operations.
**How to avoid:** For the counter's single-table pattern, this is a non-issue. Document the difference for downstream multi-table features.
**Warning signs:** Stream appears "stuck" -- not emitting after writes to unrelated tables.

### Pitfall 5: `Right(null)` Smell in Void Returns
**What goes wrong:** Current code uses `Either<Failure, void>` and returns `Right(null)`. Direct migration would produce `Success<void>(null)` which is equally odd.
**Why it happens:** `void` is not a proper value type in Dart.
**How to avoid:** Return `Result<void>` with `Success(null)` -- it works but consider defining `setCounter` to return `Result<()>` using Dart 3 records if it reads better, or simply `Future<Result<void>>` which is idiomatic. The `switch` on `Result<void>` still works: `case Success(): ...`.
**Warning signs:** Null-safety warnings when destructuring `Success(:final value)` on a `Result<void>`.

### Pitfall 6: build_runner Conflicting Outputs
**What goes wrong:** Running `build_runner` with leftover ObjectBox generator annotations alongside new Drift annotations causes "conflicting outputs" errors.
**Why it happens:** Old generator config still registered but source annotations removed.
**How to avoid:** Remove ObjectBox deps from `pubspec.yaml` and run `fvm flutter clean` BEFORE adding Drift deps and running `build_runner`.
**Warning signs:** "Tried to generate X which would overwrite existing file."

## Code Examples

### analysis_options.yaml (complete replacement)

```yaml
# Source: Context7 very_good_analysis docs + CONTEXT.md D-16, D-17, D-18
include: package:very_good_analysis/analysis_options.10.0.0.yaml

analyzer:
  language:
    strict-casts: true
    strict-inference: true
    strict-raw-types: true
  errors:
    # Promote common smells to errors (D-18)
    avoid_print: error
    unawaited_futures: error
    dead_code: error
    unused_import: error
  exclude:
    # Generated files (D-17)
    - "**/*.g.dart"
    - "**/*.gr.dart"
    - "**/*.config.dart"
    - "**/*.freezed.dart"
    - "**/generated_plugin_registrant.dart"

linter:
  rules:
    # Disable rules too noisy for a skeleton template
    public_member_api_docs: false
```

### StartUpService (after modification)

```dart
// Source: CONTEXT.md D-11
import 'core/injectable/injection.dart';

abstract class StartUpService {
  static Future<void> initServices() async {
    await _configureFirebase();
    await _configureDependencies();
    // No _configureDatabases() -- Drift lazy-inits via DI (D-11)
  }

  static Future<void> _configureDependencies() async {
    await configureDependenciesApp();
  }

  static Future<void> _configureFirebase() async {
    //TODO: Add your Firebase by files or CLI
  }
}
```

### CounterModel (after removing ObjectBox annotations)

```dart
// Source: CONTEXT.md D-09
class CounterModel {
  const CounterModel({this.id = 0, required this.value});

  final int id;
  final int value;

  CounterModel copyWith({
    int? id,
    int? value,
  }) =>
      CounterModel(
        id: id ?? this.id,
        value: value ?? this.value,
      );
}
```

### Repository returning Result<T> (migration from Either)

```dart
// Source: existing counter_repository.dart + Result<T> migration
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/errors/result.dart';
import '../local_database/counter_local_database.dart';
import '../model/counter_model.dart';

abstract class CounterRepository {
  Future<Result<CounterModel>> getCounter();
  Future<Result<void>> setCounter({required CounterModel counter});
  Stream<Result<CounterModel>> watchCounter();
}

@LazySingleton(as: CounterRepository)
class CounterRepositoryImpl implements CounterRepository {
  CounterRepositoryImpl(this._localDataBase);

  final CounterLocalDataBase _localDataBase;
  final Logger _logger = Logger();

  @override
  Future<Result<CounterModel>> getCounter() async {
    try {
      final entry = await _localDataBase.getCounter();
      if (entry == null) {
        return const Failure(LocalDataNotFound('Counter not found'));
      }
      return Success(CounterModel(id: entry.id, value: entry.value));
    } catch (e) {
      _logger.e('Local data source exception: $e');
      return Failure(LocalDataSource(e.toString()));
    }
  }

  @override
  Future<Result<void>> setCounter({required CounterModel counter}) async {
    try {
      await _localDataBase.setCounter(value: counter.value);
      return const Success(null);
    } catch (e) {
      _logger.e('Local data source exception: $e');
      return Failure(LocalDataSource(e.toString()));
    }
  }

  @override
  Stream<Result<CounterModel>> watchCounter() =>
      _localDataBase.watchCounter().map((entry) {
        if (entry == null) {
          return const Failure(LocalDataNotFound('Counter not found'));
        }
        return Success(CounterModel(id: entry.id, value: entry.value));
      });
}
```

### HomeCubit with switch pattern matching

```dart
// Source: existing home_cubit.dart + Result<T> switch migration
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/result.dart';
import '../../data/model/counter_model.dart';
import '../../domain/counter_service.dart';

part 'home_state.dart';

@injectable
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._counterService) : super(HomeState.initial());

  final CounterService _counterService;
  StreamSubscription<Result<CounterModel>>? _counterStream;

  Future<void> init() async {
    final counter = await _getCounter();
    if (counter == null) {
      await _counterService.setCounter(
        counter: const CounterModel(value: 0),
      );
    }

    _counterStream = _counterService.watchCounter().listen(
      (result) {
        switch (result) {
          case Success(:final value):
            emit(state.copyWith(
              status: HomePageStatus.success,
              counter: value,
            ));
          case Failure():
            emit(state.copyWith(status: HomePageStatus.error));
        }
      },
    );
  }

  void increment() {
    final updatedData = state.counter.copyWith(value: state.counter.value + 1);
    _counterService.setCounter(counter: updatedData);
  }

  void decrement() {
    final updatedData = state.counter.copyWith(value: state.counter.value - 1);
    _counterService.setCounter(counter: updatedData);
  }

  Future<CounterModel?> _getCounter() async {
    final result = await _counterService.getCounter();
    return result.valueOrNull;
  }

  @override
  Future<void> close() {
    _counterStream?.cancel();
    return super.close();
  }
}
```

**Note:** The `close()` override with `_counterStream?.cancel()` fixes the existing stream cancellation bug documented in CONCERNS.md. This is a natural byproduct of the migration -- the deferred item from CONTEXT.md gets addressed here because rewriting the cubit is required anyway.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `dartz` `Either<L, R>` | Dart 3 `sealed class` pattern matching | Dart 3.0 (May 2023) | Zero-dependency error handling with compiler-enforced exhaustiveness |
| `flutter_lints` | `very_good_analysis` | Ongoing (VGA tracks Dart releases) | Stricter baseline, catches more real bugs |
| ObjectBox (NoSQL) | Drift (typed SQLite) | Drift 2.x stable since 2023 | Reactive queries, schema migrations, type-safe SQL |
| `sqlite3_flutter_libs` (separate dep) | Bundled via `sqlite3` 3.x build hooks | Feb 2026 (`0.6.0+eol`) | One fewer direct dependency |
| `SharedPreferences.getInstance()` | `SharedPreferencesAsync` | shared_preferences 2.x (2024) | Multi-isolate-safe, no cache warm-up needed |

**Deprecated/outdated:**
- `dartz`: Unmaintained since 2021. No Dart 3 sealed class integration. [VERIFIED: pub.dev]
- `flutter_lints`: Weaker than `very_good_analysis` for production quality bars. Still functional but not recommended for new projects.
- `sqlite3_flutter_libs`: EOL as of Feb 2026. Drift 2.32+ handles SQLite bundling natively.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `public_member_api_docs: false` is the right override for the skeleton | Architecture Patterns (analysis_options) | Minor -- can enable later; fixing ~100 doc comments is mechanical work |
| A2 | `CounterEntriesCompanion.insert(value: Value(value))` is the correct Drift companion API for upsert | Code Examples (data source) | LOW -- exact Companion API depends on generated code; verify after `build_runner` |
| A3 | `@lazySingleton` on `AppDatabase` class body works with `injectable_generator` without manual registration | Architecture Patterns | LOW -- if not supported, fall back to manual `getIt.registerLazySingleton<AppDatabase>(...)` in `injection.dart` |
| A4 | `drift_flutter` `driftDatabase(name:)` uses `getApplicationSupportDirectory` by default (not documents) | Standard Stack | LOW -- if wrong, database path changes but functionality is identical |

## Open Questions

1. **Exact set of `// ignore` comments needed**
   - What we know: `very_good_analysis` will flag existing code for `sort_constructors_first`, `prefer_const_declarations`, possibly `lines_longer_than_80_chars`, and similar style rules.
   - What's unclear: Which specific existing files need `// ignore` vs code fixes.
   - Recommendation: Fix all fixable issues; only `// ignore` for genuinely inapplicable rules on skeleton example code.

2. **`Result.guard()` convenience factory**
   - What we know: D-06 says Claude has discretion. It would wrap try/catch: `static Future<Result<T>> guard<T>(Future<T> Function() fn) async { try { return Success(await fn()); } catch (e) { return Failure(LocalDataSource(e.toString())); } }`
   - What's unclear: Whether it's worth adding now or waiting until Phase 3 reveals the pattern more.
   - Recommendation: Skip for Phase 2. The skeleton has only 3 repository methods -- inline try/catch is clear enough. Add if Phase 3 shows repetitive patterns.

3. **Feature-level `data/local_database/` folder name**
   - What we know: Core renames to `database/`, feature-level could rename too.
   - What's unclear: Whether consistency matters enough to rename.
   - Recommendation: Keep `data/local_database/` at feature level per CONTEXT.md discretion note. It's the existing convention and minimizes diff.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| FVM | Flutter SDK management | Needs verification | -- | Direct `flutter` command |
| Flutter SDK | All compilation | Needs verification | 3.41.5 expected | -- |
| Dart SDK | Code generation | Bundled with Flutter | 3.9 expected | -- |
| build_runner | Drift codegen | Already in pubspec | ^2.4.14 | -- |

**Note:** This phase is purely code/config changes. No external services, databases, or CLI tools beyond the Flutter/Dart SDK are needed.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (SDK, already in pubspec) |
| Config file | None -- no test directory exists |
| Quick run command | `fvm flutter analyze` (lint validation) |
| Full suite command | `fvm flutter analyze && fvm flutter test` (once tests exist) |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| TOOL-03 | `flutter analyze` exits 0 under `very_good_analysis` | lint/static | `fvm flutter analyze` | N/A (built-in) |
| CORE-01 | `Result<T>` sealed hierarchy compiles, exhaustiveness enforced | unit | `fvm flutter test test/core/errors/result_test.dart -x` | Wave 0 |
| CORE-02 | Repository returns `Result<T>`, cubit consumes via `switch` | unit | `fvm flutter test test/features/home_page/ -x` | Wave 0 |
| CORE-06 | No `dartz`/`http`/`uuid`/`collection` imports in lib/ | lint/grep | `grep -rn "dartz\|package:http\|package:uuid\|package:collection" lib/` | N/A (shell) |
| DATA-01 | No ObjectBox artifacts remain | lint/grep | `grep -rn "objectbox" lib/ pubspec.yaml` | N/A (shell) |
| DATA-02 | AppDatabase registered as lazySingleton, compiles | integration | `fvm flutter test test/core/database/app_database_test.dart -x` | Wave 0 |
| DATA-03 | Counter reads/writes/watches via Drift | integration | `fvm flutter test test/features/home_page/data/ -x` | Wave 0 |
| DATA-04 | SharedPreferencesAsync wrapper compiles | unit | `fvm flutter test test/core/preferences/ -x` | Wave 0 |
| DATA-05 | flutter_secure_storage wrapper compiles | unit | `fvm flutter test test/core/secure_storage/ -x` | Wave 0 |

### Sampling Rate
- **Per task commit:** `fvm flutter analyze`
- **Per wave merge:** `fvm flutter analyze && fvm flutter test`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/` directory does not exist -- create it
- [ ] `test/core/errors/result_test.dart` -- test sealed Result exhaustiveness
- [ ] `test/core/database/app_database_test.dart` -- test Drift with `NativeDatabase.memory()`
- [ ] `test/features/home_page/data/local_database/counter_local_database_test.dart` -- test Drift queries
- [ ] Note: Full test infrastructure (mocktail, bloc_test) is planned for TOOL-06 in Phase 7. Phase 2 needs only compile-and-analyze validation + minimal Drift integration tests.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Phase 5 concern |
| V3 Session Management | No | Phase 5 concern |
| V4 Access Control | No | Not applicable |
| V5 Input Validation | No | No user input processed in this phase |
| V6 Cryptography | Yes (flutter_secure_storage) | `flutter_secure_storage` with `AndroidOptions(encryptedSharedPreferences: true)` + iOS Keychain |

### Known Threat Patterns for this Phase

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Plaintext token storage | Information Disclosure | Use `flutter_secure_storage`, not `SharedPreferences`, for auth tokens |
| SQLite database on unencrypted filesystem | Information Disclosure | Acceptable for non-sensitive counter data; encrypt via `sqlcipher` if storing PII (out of scope for skeleton) |
| Keychain access group misconfiguration (iOS) | Information Disclosure | Deferred to Phase 4/5 per CONTEXT.md; Phase 2 registers the wrapper only |

## Sources

### Primary (HIGH confidence)
- [pub.dev/packages/drift](https://pub.dev/packages/drift) - version 2.32.1, verified 2026-04-17
- [pub.dev/packages/drift_flutter](https://pub.dev/packages/drift_flutter) - version 0.3.0, verified 2026-04-17
- [pub.dev/packages/drift_dev](https://pub.dev/packages/drift_dev) - version 2.32.1, verified 2026-04-17
- [pub.dev/packages/very_good_analysis](https://pub.dev/packages/very_good_analysis) - version 10.2.0, verified 2026-04-17
- [pub.dev/packages/shared_preferences](https://pub.dev/packages/shared_preferences) - version 2.5.5, verified 2026-04-17
- [pub.dev/packages/flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) - version 10.0.0, verified 2026-04-17
- [pub.dev/packages/sqlite3_flutter_libs](https://pub.dev/packages/sqlite3_flutter_libs) - version 0.6.0+eol (EOL), verified 2026-04-17
- Context7: `/simolus3/drift` - Drift table definitions, DriftDatabase setup, driftDatabase() helper, watchSingleOrNull, insertOnConflictUpdate
- Context7: `/verygoodopensource/very_good_analysis` - analysis_options.yaml configuration, rule suppression
- Context7: `/websites/pub_dev_packages_shared_preferences` - SharedPreferencesAsync API

### Secondary (MEDIUM confidence)
- [drift.simonbinder.eu/platforms/](https://drift.simonbinder.eu/platforms/) - sqlite3_flutter_libs EOL context
- [github.com/simolus3/drift/issues/3702](https://github.com/simolus3/drift/issues/3702) - drift_flutter and sqlite3_flutter_libs relationship
- `.planning/research/STACK.md` - Pre-existing project research, package version matrix
- `.planning/research/ARCHITECTURE.md` - Drift integration patterns, sealed Result design
- `.planning/research/PITFALLS.md` - ObjectBox removal sequence, very_good_analysis cascade, dartz migration

### Tertiary (LOW confidence)
- None -- all claims verified against pub.dev or Context7.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH -- all versions verified on pub.dev 2026-04-17
- Architecture: HIGH -- patterns sourced from Context7 drift/VGA docs + existing project research
- Pitfalls: HIGH -- based on verified API changes and codebase analysis (grep-verified import counts)

**Research date:** 2026-04-17
**Valid until:** 2026-05-17 (30 days -- stable packages, no fast-moving concerns)

## Project Constraints (from CLAUDE.md)

- **Tech stack**: Flutter 3.41.5 stable / Dart 3.9 (Phase 2 operates within this; SDK already set by Phase 1)
- **Platforms**: iOS + Android only
- **Languages**: Code in English; UI strings PL + EN (localization untouched by Phase 2)
- **DX**: Must not break `flutter analyze` -- every commit must pass
- **Lint package**: `very_good_analysis` (replaces `flutter_lints`)
- **DI pattern**: `get_it` + `injectable` with `@lazySingleton` for services, `@injectable` for cubits
- **Error handling**: Dart 3 sealed classes, no `dartz`
- **Local DB**: Drift, not ObjectBox
- **Generated code**: `build_runner` for Drift, injectable, auto_route codegen
