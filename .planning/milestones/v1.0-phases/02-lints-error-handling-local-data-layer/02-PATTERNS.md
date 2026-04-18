# Phase 2: Lints, Error Handling, Local Data Layer - Pattern Map

**Mapped:** 2026-04-17
**Files analyzed:** 18 (8 modified, 6 new, 4 deleted)
**Analogs found:** 14 / 14

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `analysis_options.yaml` | config | N/A | `analysis_options.yaml` (self) | exact |
| `pubspec.yaml` | config | N/A | `pubspec.yaml` (self) | exact |
| `lib/core/errors/result.dart` | model | transform | `lib/core/errors/failures.dart` | role-match |
| `lib/core/errors/failures.dart` | model | transform | `lib/core/errors/failures.dart` (self) | exact |
| `lib/core/database/app_database.dart` | service | CRUD | `lib/core/local_database/object_box.dart` | role-match |
| `lib/core/database/tables/counter_entries.dart` | model | CRUD | `lib/features/home_page/data/model/counter_model.dart` | role-match |
| `lib/core/preferences/preferences_service.dart` | service | CRUD | `lib/features/home_page/data/local_database/counter_local_database.dart` | role-match |
| `lib/core/preferences/preferences_service_impl.dart` | service | CRUD | `lib/features/home_page/data/local_database/counter_local_database.dart` | role-match |
| `lib/core/secure_storage/secure_storage_service.dart` | service | CRUD | `lib/features/home_page/data/local_database/counter_local_database.dart` | role-match |
| `lib/core/secure_storage/secure_storage_service_impl.dart` | service | CRUD | `lib/features/home_page/data/local_database/counter_local_database.dart` | role-match |
| `lib/features/home_page/data/model/counter_model.dart` | model | transform | `lib/features/home_page/data/model/counter_model.dart` (self) | exact |
| `lib/features/home_page/data/local_database/counter_local_database.dart` | service | streaming | `lib/features/home_page/data/local_database/counter_local_database.dart` (self) | exact |
| `lib/features/home_page/data/repository/counter_repository.dart` | service | streaming | `lib/features/home_page/data/repository/counter_repository.dart` (self) | exact |
| `lib/features/home_page/domain/counter_service.dart` | service | streaming | `lib/features/home_page/domain/counter_service.dart` (self) | exact |
| `lib/features/home_page/presentation/cubit/home_cubit.dart` | controller | event-driven | `lib/features/home_page/presentation/cubit/home_cubit.dart` (self) | exact |
| `lib/startup_service.dart` | service | request-response | `lib/startup_service.dart` (self) | exact |

### Files to Delete

| File | Reason |
|------|--------|
| `lib/core/local_database/object_box.dart` | Replaced by Drift `AppDatabase` |
| `lib/core/local_database/objectbox.g.dart` | Generated ObjectBox code, no longer needed |
| `objectbox-model.json` | ObjectBox schema file, no longer needed |
| `lib/core/local_database/` (directory) | Entire directory removed after contents deleted |

## Pattern Assignments

### `analysis_options.yaml` (config, N/A)

**Analog:** self (complete replacement)

**Current content** (lines 1-29):
```yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # avoid_print: false  # Uncomment to disable the `avoid_print` rule
    # prefer_single_quotes: true  # Uncomment to enable the `prefer_single_quotes` rule
```

**Target pattern:** Replace `include:` line, add `analyzer:` block with `errors:` and `exclude:`. See RESEARCH.md "analysis_options.yaml (complete replacement)" code example for exact content.

---

### `lib/core/errors/result.dart` (model, transform) -- NEW FILE

**Analog:** `lib/core/errors/failures.dart` (same directory, same layer)

**Import pattern** (from analog, line 1 -- none needed):
```dart
// result.dart is zero-dependency pure Dart -- no imports
```

**Core pattern** -- sealed class with subtypes in same file:
The existing `failures.dart` uses plain class inheritance (lines 1-15):
```dart
class Failure {
  const Failure(this.message);
  factory Failure.localDataNotFound(String? message) => LocalDataNotFoundFailure(message);
  factory Failure.localDataSource(String? message) => LocalDataSourceFailure(message);
  final String? message;
}

class LocalDataNotFoundFailure extends Failure {
  const LocalDataNotFoundFailure(super.message);
}
```

**New pattern:** Replace with Dart 3 `sealed class` + `final class` subtypes. All subtypes MUST be in the same file for exhaustiveness checking. See RESEARCH.md "Pattern 1: Sealed Result<T> + AppFailure" for exact definitions.

---

### `lib/core/errors/failures.dart` (model, transform) -- REWRITE

**Analog:** self (current content replaced)

**Current content** (lines 1-15):
```dart
class Failure {
  const Failure(this.message);
  factory Failure.localDataNotFound(String? message) => LocalDataNotFoundFailure(message);
  factory Failure.localDataSource(String? message) => LocalDataSourceFailure(message);
  final String? message;
}

class LocalDataNotFoundFailure extends Failure {
  const LocalDataNotFoundFailure(super.message);
}

class LocalDataSourceFailure extends Failure {
  const LocalDataSourceFailure(super.message);
}
```

**Target pattern:** Replace with `sealed class AppFailure` + `final class` subtypes. Field type changes from `String?` to `String` (non-nullable). Factory constructors removed -- use subtypes directly.

---

### `lib/core/database/app_database.dart` (service, CRUD) -- NEW FILE

**Analog:** `lib/core/local_database/object_box.dart`

**Current ObjectBox singleton pattern** (lines 7-34):
```dart
abstract class ObjectBox {
  static Store? _store;

  static Future<void> initObjectBox() async {
    if (_store != null) return;
    final docsDir = await p.getApplicationDocumentsDirectory();
    _store = await openStore(directory: docsDir.path);
  }

  static Box<T> getBox<T>() {
    return store.box<T>();
  }

  static Store get store {
    if (_store == null) {
      throw Exception("ObjectBox not initialized. Call initObjectBox() first.");
    }
    return _store!;
  }
}
```

**Target pattern:** Replace static singleton with `@lazySingleton`-annotated class. Uses `part 'app_database.g.dart'` for generated code. Uses `driftDatabase(name: ...)` from `drift_flutter` for connection. See RESEARCH.md "Pattern 2" for exact structure.

**DI registration pattern** (from `lib/core/injectable/injection.dart` lines 15-21):
```dart
@InjectableInit(
  initializerName: r'$initGetIt',
  preferRelativeImports: true,
  asExtension: false,
)
Future<void> configureDependenciesApp() async => $initGetIt(getIt);
```
The `@lazySingleton` annotation on `AppDatabase` class body integrates with this existing DI setup -- no manual registration needed.

---

### `lib/core/database/tables/counter_entries.dart` (model, CRUD) -- NEW FILE

**Analog:** `lib/features/home_page/data/model/counter_model.dart`

**Current model** (lines 1-18):
```dart
import 'package:objectbox/objectbox.dart';

@Entity()
class CounterModel {
  CounterModel({this.id = 0, required this.value});

  @Id()
  int id;
  final int value;

  CounterModel copyWith({
    int? id,
    int? value,
  }) => CounterModel(
      id: id ?? this.id,
      value: value ?? this.value,
    );
}
```

**Target pattern:** Drift `Table` class with `IntColumn` definitions. This is a schema definition, not a model class. See RESEARCH.md "Pattern 2" `CounterEntries` table definition.

---

### `lib/core/preferences/preferences_service.dart` (service, CRUD) -- NEW FILE

**Analog:** `lib/features/home_page/data/local_database/counter_local_database.dart`

**Abstract interface pattern** (analog lines 7-11):
```dart
//Purpose of data source is to fetch data, there should be no business logic here
abstract class CounterLocalDataBase {
  Future<CounterModel?> getCounter();
  Future<void> setCounter(CounterModel counter);
  Stream<CounterModel?> watchCounter();
}
```

**Target pattern:** Same abstract class convention. Generic get/set API per D-14. No feature-specific keys.

---

### `lib/core/preferences/preferences_service_impl.dart` (service, CRUD) -- NEW FILE

**Analog:** `lib/features/home_page/data/local_database/counter_local_database.dart`

**Impl + DI registration pattern** (analog lines 13-14):
```dart
@Injectable(as: CounterLocalDataBase)
class CounterLocalDataBaseImpl implements CounterLocalDataBase {
```

**Target pattern:** Change `@Injectable` to `@LazySingleton` per D-13. Wraps `SharedPreferencesAsync` instance.

---

### `lib/core/secure_storage/secure_storage_service.dart` (service, CRUD) -- NEW FILE

**Analog:** Same abstract class pattern as `preferences_service.dart` above.

**Target pattern:** Abstract class with `read`, `write`, `delete`, `deleteAll` methods.

---

### `lib/core/secure_storage/secure_storage_service_impl.dart` (service, CRUD) -- NEW FILE

**Analog:** Same impl pattern as `preferences_service_impl.dart` above.

**Target pattern:** `@LazySingleton(as: SecureStorageService)`. Wraps `FlutterSecureStorage` with platform-specific options.

---

### `lib/features/home_page/data/model/counter_model.dart` (model, transform) -- MODIFY

**Analog:** self

**Current content** (lines 1-18):
```dart
import 'package:objectbox/objectbox.dart';

@Entity()
class CounterModel {
  CounterModel({this.id = 0, required this.value});

  @Id()
  int id;
  final int value;
```

**Target pattern:** Remove `import 'package:objectbox/objectbox.dart'`, remove `@Entity()`, remove `@Id()`. Make `id` final. Add `const` to constructor per D-09.

---

### `lib/features/home_page/data/local_database/counter_local_database.dart` (service, streaming) -- REWRITE

**Analog:** self (interface preserved, implementation replaced)

**Current implementation** (lines 13-29):
```dart
@Injectable(as: CounterLocalDataBase)
class CounterLocalDataBaseImpl implements CounterLocalDataBase {

  final _counterBox = ObjectBox.getBox<CounterModel>();

  @override
  Future<CounterModel?> getCounter() async => _counterBox.getAll().first;

  @override
  Future<void> setCounter(CounterModel counter) async => _counterBox.put(counter);

  @override
  Stream<CounterModel?> watchCounter() => _counterBox
        .query()
        .watch(triggerImmediately: true)
        .asyncMap((query) async => query.findFirst());
}
```

**Target pattern:** Replace ObjectBox `Box<T>` with Drift `AppDatabase` injection. Change `@Injectable` to `@LazySingleton`. Constructor injection of `AppDatabase`. Return Drift `CounterEntry` (generated type) instead of `CounterModel` -- repository handles mapping. See RESEARCH.md "Pattern 3" for Drift query syntax.

---

### `lib/features/home_page/data/repository/counter_repository.dart` (service, streaming) -- MIGRATE

**Analog:** self

**Current Either-based pattern** (lines 1-7, 24-35):
```dart
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:skeleton/features/home_page/data/model/counter_model.dart';

import '../../../../core/errors/failures.dart';
import '../local_database/counter_local_database.dart';

// ...

  @override
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

**Target pattern:**
- Replace `import 'package:dartz/dartz.dart'` with `import '../../../../core/errors/result.dart'`
- Replace `Either<Failure, T>` with `Result<T>` in all signatures
- Replace `Left(Failure.localDataNotFound(...))` with `Failure(LocalDataNotFound(...))`
- Replace `Left(Failure.localDataSource(...))` with `Failure(LocalDataSource(...))`
- Replace `Right(counter)` with `Success(counter)`
- Replace `Right(null)` with `Success(null)` for `Result<void>`
- Add mapping from Drift `CounterEntry` to `CounterModel` in getCounter/watchCounter
- Change `@Injectable` to `@LazySingleton`

**Error handling pattern preserved** (lines 31-34):
```dart
    } catch (e) {
      _logger.e('Local data source exception: $e');
      return Left(Failure.localDataSource(e.toString()));
    }
```
This pattern stays identical in structure, only the return types change.

---

### `lib/features/home_page/domain/counter_service.dart` (service, streaming) -- MIGRATE

**Analog:** self

**Current pattern** (lines 1-6, 9-13):
```dart
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../core/errors/failures.dart';
import '../data/model/counter_model.dart';
import '../data/repository/counter_repository.dart';

abstract class CounterService {
  Future<Either<Failure, CounterModel>> getCounter();
  Future<Either<Failure, void>> setCounter({required CounterModel counter});
  Stream<Either<Failure, CounterModel>> watchCounter();
}
```

**Target pattern:**
- Replace `dartz` import with `result.dart` import
- Replace `Either<Failure, T>` with `Result<T>` in all signatures
- Change `@Injectable` to `@LazySingleton` per D-07 convention (stateless services = lazy singleton)

---

### `lib/features/home_page/presentation/cubit/home_cubit.dart` (controller, event-driven) -- MIGRATE

**Analog:** self

**Current `.fold()` pattern** (lines 23-36):
```dart
    _counterStream = _counterService.watchCounter().listen(
      (data) {
        data.fold(
          (failure) {
            emit(state.copyWith(status: HomePageStatus.error));
          },
          (data) {
            emit(state.copyWith(
              status: HomePageStatus.success,
              counter: data,
            ));
          },
        );
        emit(state.copyWith(status: HomePageStatus.empty));
      },
    );
```

**Target pattern:** Replace `.fold()` with `switch` pattern matching:
```dart
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
```

**Current `_getCounter` pattern** (lines 53-55):
```dart
  Future<CounterModel?> _getCounter() async => await _counterService.getCounter().then(
        (result) => result.fold((failure) => null, (data) => data),
      );
```

**Target pattern:** Replace with `result.valueOrNull`:
```dart
  Future<CounterModel?> _getCounter() async {
    final result = await _counterService.getCounter();
    return result.valueOrNull;
  }
```

**Bug fix (lines 15, 56):** Current `StreamSubscription? _counterStream` lacks `.cancel()` in `close()`. Add:
```dart
  @override
  Future<void> close() {
    _counterStream?.cancel();
    return super.close();
  }
```

**Note:** Also remove the stray `emit(state.copyWith(status: HomePageStatus.empty))` on line 36 -- it fires after every fold result, overriding the status just set. This is a bug in the existing code.

---

### `lib/startup_service.dart` (service, request-response) -- MODIFY

**Analog:** self

**Current database init** (lines 8, 15, 18-20):
```dart
import 'core/local_database/object_box.dart';

    await _configureDatabases();

  static Future<void> _configureDatabases() async {
    await ObjectBox.initObjectBox();
  }
```

**Target pattern:** Remove the `import`, remove the `await _configureDatabases()` call, remove the `_configureDatabases()` method entirely. Drift lazy-inits via DI (D-11).

---

### `pubspec.yaml` (config, N/A) -- MODIFY

**Analog:** self

**Additions:**
```yaml
dependencies:
  drift: ^2.32.1
  drift_flutter: ^0.3.0
  shared_preferences: ^2.5.5
  flutter_secure_storage: ^10.0.0

dev_dependencies:
  very_good_analysis: ^10.2.0
  drift_dev: ^2.32.1
```

**Removals:**
```yaml
# From dependencies:
  dartz: 0.10.1           # -> sealed Result<T>
  objectbox: ^4.0.3        # -> Drift
  objectbox_flutter_libs: any  # -> Drift
  http: ^1.2.2             # unused
  uuid: ^4.5.1             # unused
  collection: ^1.19.0      # unused
  path_provider: ^2.1.5    # only needed by ObjectBox, drift_flutter pulls transitively

# From dev_dependencies:
  flutter_lints: ^5.0.0    # -> very_good_analysis
  objectbox_generator: any # -> drift_dev

# Remove entire block:
objectbox:
  output_dir: core/local_database
```

## Shared Patterns

### Abstract + Impl with DI Registration
**Source:** `lib/features/home_page/data/local_database/counter_local_database.dart` lines 7-14
**Apply to:** All new service files (`PreferencesService`, `SecureStorageService`, `CounterLocalDataBase` rewrite)
```dart
abstract class CounterLocalDataBase {
  Future<CounterModel?> getCounter();
  Future<void> setCounter(CounterModel counter);
  Stream<CounterModel?> watchCounter();
}

@Injectable(as: CounterLocalDataBase)
class CounterLocalDataBaseImpl implements CounterLocalDataBase {
```
**Migration note:** Change `@Injectable` to `@LazySingleton` for all services/data sources. Only cubits remain `@injectable` (factory).

### Error Handling in Repositories
**Source:** `lib/features/home_page/data/repository/counter_repository.dart` lines 24-35
**Apply to:** All repository methods
```dart
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
**Migration:** Structure stays identical. Replace `Left(...)` with `Failure(...)`, `Right(...)` with `Success(...)`. Replace `Failure.localDataNotFound(...)` with `LocalDataNotFound(...)`.

### Logger Instance Convention
**Source:** `lib/features/home_page/data/repository/counter_repository.dart` line 21
**Apply to:** All repository implementations
```dart
  final Logger _logger = Logger();
```

### Cubit State Pattern (unchanged)
**Source:** `lib/features/home_page/presentation/cubit/home_state.dart` lines 1-42
**Apply to:** All cubits (pattern preserved, no changes in Phase 2)
```dart
part of 'home_cubit.dart';

class HomeState {
  const HomeState({
    required this.navigation,
    required this.status,
    required this.counter,
  });

  factory HomeState.initial() => HomeState(
        status: HomePageStatus.empty,
        navigation: HomePageNavigation.empty,
        counter: CounterModel(value: 0),
      );

  // ... copyWith pattern
}

enum HomePageStatus { loading, success, error, empty }
```

### Import Convention
**Source:** `lib/features/home_page/data/repository/counter_repository.dart` lines 1-7
**Apply to:** All files
```dart
// Absolute for cross-feature imports
import 'package:skeleton/features/home_page/data/model/counter_model.dart';
// Relative for same-feature sibling imports
import '../../../../core/errors/failures.dart';
import '../local_database/counter_local_database.dart';
```

## No Analog Found

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| `lib/core/database/tables/counter_entries.dart` | model | CRUD | No Drift table definitions exist yet. Pattern sourced from RESEARCH.md (Drift `Table` class). |
| `lib/core/database/app_database.dart` | service | CRUD | No `@DriftDatabase` class exists. The ObjectBox singleton is a role-match but the implementation pattern is completely different (annotation-driven + codegen vs static singleton). Pattern sourced from RESEARCH.md. |

## Metadata

**Analog search scope:** `lib/`, `analysis_options.yaml`, `pubspec.yaml`
**Files scanned:** 18
**Pattern extraction date:** 2026-04-17
