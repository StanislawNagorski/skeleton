# Testing Patterns

**Analysis Date:** 2026-04-16

## Current State

**There is no `test/` directory in the project.**

**There is no `integration_test/` directory in the project.**

**There are no `*_test.dart` files anywhere in the repository** (verified across `lib/`, project root, and platform folders).

**There is no `coverage/` directory.**

**There is no CI configuration** (`.github/workflows`, `bitrise.yml`, `codemagic.yaml`, etc. are absent).

The project ships as a Flutter skeleton/template intended to be copied for new apps - the testing layer has not yet been seeded. This document captures the **declared toolchain** plus the **patterns the codebase is set up to support**, so the first tests added can match Flutter conventions and the project's Clean Architecture.

## Test Framework

**Runner:**
- `flutter_test` (from Flutter SDK) - declared in `pubspec.yaml:54-55` under `dev_dependencies`:
  ```yaml
  dev_dependencies:
    flutter_test:
      sdk: flutter
  ```
- No `vitest`/`jest` analogue applies. Use `flutter test`.

**Assertion Library:**
- `package:flutter_test` (re-exports `package:test_api`'s `expect`, `Matcher`s, `group`, `setUp`, `tearDown`).

**Mocking Library:**
- **None declared.** Neither `mocktail` nor `mockito` is in `pubspec.yaml`.
- **Recommendation when adding the first tests:** add `mocktail: ^1.0.0` to `dev_dependencies`. Mocktail aligns with the project's null-safety + abstract-class-interface pattern and avoids `build_runner` overhead that `mockito` requires.

**Golden testing:** Not configured. `flutter_test` provides `matchesGoldenFile` out of the box; no extra dependency needed for basic golden tests. For more advanced workflows consider `golden_toolkit` or `alchemist` later.

**Run Commands:**
```bash
fvm flutter test                              # Run all tests (use FVM-pinned Flutter 3.29.0)
fvm flutter test --coverage                   # Generate coverage/lcov.info
fvm flutter test test/path/to/file_test.dart  # Run a single file
fvm flutter test --update-goldens             # Regenerate golden images
fvm flutter test integration_test             # Run integration tests
```

## Recommended Test File Organization

**Mirror the `lib/` tree under `test/`:**
```
test/
├── core/
│   ├── errors/
│   │   └── failures_test.dart
│   └── utils/
│       └── debouncer_test.dart
└── features/
    └── home_page/
        ├── data/
        │   ├── repository/
        │   │   └── counter_repository_test.dart
        │   └── local_database/
        │       └── counter_local_database_test.dart
        ├── domain/
        │   └── counter_service_test.dart
        └── presentation/
            ├── cubit/
            │   └── home_cubit_test.dart
            └── home_page_test.dart
```

**Naming:** `<source_filename>_test.dart` - the Flutter convention. `flutter test` discovers any file ending in `_test.dart` under `test/`.

**Integration tests** belong in a top-level `integration_test/` directory (sibling to `test/`), per `package:integration_test` conventions. Add the dependency when needed:
```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
```

## Recommended Test Structure

**Suite Organization** (matches Flutter idiom):
```dart
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CounterRepositoryImpl', () {
    late CounterLocalDataBase localDataBase;
    late CounterRepositoryImpl repository;

    setUp(() {
      localDataBase = _MockCounterLocalDataBase();
      repository = CounterRepositoryImpl(localDataBase);
    });

    group('getCounter', () {
      test('returns Right(CounterModel) when data source returns a counter', () async {
        when(() => localDataBase.getCounter())
            .thenAnswer((_) async => CounterModel(value: 5));

        final result = await repository.getCounter();

        expect(result.isRight(), isTrue);
        result.fold(
          (failure) => fail('Expected Right but got Left($failure)'),
          (model) => expect(model.value, 5),
        );
      });

      test('returns Left(LocalDataNotFoundFailure) when data source returns null', () async {
        when(() => localDataBase.getCounter()).thenAnswer((_) async => null);

        final result = await repository.getCounter();

        expect(result.isLeft(), isTrue);
        result.fold(
          (failure) => expect(failure, isA<LocalDataNotFoundFailure>()),
          (_) => fail('Expected Left'),
        );
      });
    });
  });
}
```

## Mocking Patterns

**Recommended framework:** `mocktail` (no codegen, plays well with abstract classes already used as DI contracts).

**Setup:**
```dart
import 'package:mocktail/mocktail.dart';

class _MockCounterLocalDataBase extends Mock implements CounterLocalDataBase {}
class _MockCounterService extends Mock implements CounterService {}
class _MockCounterRepository extends Mock implements CounterRepository {}
```

**Pattern - stubbing futures and streams:**
```dart
when(() => mockService.getCounter())
    .thenAnswer((_) async => Right(CounterModel(value: 0)));

when(() => mockService.watchCounter())
    .thenAnswer((_) => Stream.value(Right(CounterModel(value: 1))));
```

**Pattern - registering fallback values for `any()` matchers** with non-primitive types (mocktail requirement):
```dart
setUpAll(() {
  registerFallbackValue(CounterModel(value: 0));
});
```

**What to mock:**
- Repositories (when testing services or cubits)
- Services (when testing cubits)
- Data sources (when testing repositories)
- ObjectBox `Box<T>` and `Store` if exercising local database code directly (or use a real in-memory store - see below)

**What NOT to mock:**
- `Failure` and `CounterModel` and other plain data classes - construct them directly
- `dartz` `Either` - use `Left(...)`, `Right(...)` literally
- Pure utility classes (`Debouncer`) - test the real implementation

**For ObjectBox tests:** Open a real `Store` in a temporary directory rather than mocking - ObjectBox's API is hard to stub and an in-memory `Store` is cheap:
```dart
late Directory tmp;
late Store store;

setUp(() async {
  tmp = await Directory.systemTemp.createTemp('objectbox_test');
  store = openStore(directory: tmp.path);
});

tearDown(() async {
  store.close();
  await tmp.delete(recursive: true);
});
```

## Cubit Testing

**Recommended package:** `bloc_test: ^9.1.0` - first-class support for `flutter_bloc` cubits.

**Pattern:**
```dart
import 'package:bloc_test/bloc_test.dart';

blocTest<HomeCubit, HomeState>(
  'emits [success] when watchCounter yields a value',
  setUp: () {
    when(() => service.getCounter())
        .thenAnswer((_) async => Right(CounterModel(value: 0)));
    when(() => service.watchCounter())
        .thenAnswer((_) => Stream.value(Right(CounterModel(value: 5))));
  },
  build: () => HomeCubit(service),
  act: (cubit) => cubit.init(),
  expect: () => [
    isA<HomeState>().having((s) => s.status, 'status', HomePageStatus.success)
                    .having((s) => s.counter.value, 'counter.value', 5),
  ],
);
```

## Widget Testing

**Pattern using `flutter_test`'s `WidgetTester`:**
```dart
testWidgets('MyHomePage shows initial counter value 0', (tester) async {
  // Override DI registration for the test
  getIt.registerFactory<HomeCubit>(() => _FakeHomeCubit());

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: const [AppLocalizations.delegate],
      supportedLocales: const [Locale('en')],
      home: const MyHomePage(),
    ),
  );

  await tester.pumpAndSettle();

  expect(find.text('0'), findsOneWidget);

  await tester.tap(find.byIcon(Icons.add));
  await tester.pump();
});
```

**Important:** `MyHomePage` calls `getIt<HomeCubit>()` directly (`lib/features/home_page/presentation/home_page.dart:16`) - widget tests MUST register a fake/mock cubit on `getIt` (or call `getIt.reset()` between tests) before pumping the widget.

## Fixtures and Factories

**No fixtures directory exists yet.** Recommended convention when adding:
```
test/
└── _fixtures/
    └── counter_fixtures.dart
```

Plain Dart factory functions, not classes:
```dart
CounterModel counterModelFixture({int? id, int? value}) =>
    CounterModel(id: id ?? 0, value: value ?? 42);
```

## Coverage

**Requirements:** None enforced.

**Generate coverage report:**
```bash
fvm flutter test --coverage
```

This produces `coverage/lcov.info`. Visualize with:
```bash
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

**Excluded from coverage:** Files marked `// coverage:ignore-file` are skipped. Generated files already include this directive (`lib/core/injectable/injection.config.dart:8`).

**For per-line exclusion** within otherwise-tracked files, use `// coverage:ignore-line` or `// coverage:ignore-start` / `// coverage:ignore-end`.

## Test Types Guidance

**Unit Tests** (highest ROI):
- `CounterRepositoryImpl` - error mapping, success paths, stream `null` handling
- `CounterServiceImpl` - delegation correctness
- `Debouncer` - timing behaviour with `fakeAsync` from `package:fake_async`
- `Failure` factory constructors - subtype assertion

**Cubit Tests:**
- `HomeCubit.init()` - the empty-then-success/error transitions, the bug where `HomePageStatus.empty` is emitted after `success`/`error` (see CONCERNS.md)
- `HomeCubit.increment()` / `.decrement()` - service called with `value ± 1`

**Widget Tests:**
- `MyHomePage` - renders counter, increment/decrement FABs trigger cubit, error snack bar appears on `HomePageStatus.error`

**Integration Tests** (`integration_test/`):
- Full app launch through `StartUpService.initServices()` against a real ObjectBox store
- Counter persists across app restarts

**Golden Tests** (use `matchesGoldenFile`):
- `MyHomePage` rendered states (initial, after increment, error)
- Theme verification via `AppThemes.light`

## Common Patterns Reference

**Async Testing:**
```dart
test('awaits a Future', () async {
  final result = await someAsyncFunction();
  expect(result, isNotNull);
});
```

**Stream Testing:**
```dart
test('stream emits values in order', () {
  expect(
    cubit.stream,
    emitsInOrder([
      isA<HomeState>().having((s) => s.status, 'status', HomePageStatus.success),
    ]),
  );
});
```

**Error Testing:**
```dart
test('throws when not initialized', () {
  expect(() => ObjectBox.store, throwsA(isA<Exception>()));
});
```

**Time-based Testing** (recommended for `Debouncer`):
```dart
import 'package:fake_async/fake_async.dart';

test('Debouncer fires only the last action', () {
  fakeAsync((async) {
    final debouncer = Debouncer(milliseconds: 100);
    var counter = 0;
    debouncer(() => counter++);
    debouncer(() => counter++);
    async.elapse(const Duration(milliseconds: 200));
    expect(counter, 1);
  });
});
```

## Suggested First Test Suite to Seed the Project

Priority order (each provides high coverage of critical paths):
1. `test/core/errors/failures_test.dart` - trivial, validates Failure factories
2. `test/core/utils/debouncer_test.dart` - using `fake_async`
3. `test/features/home_page/data/repository/counter_repository_test.dart` - exercises Either-based error handling pattern that all future repositories will copy
4. `test/features/home_page/presentation/cubit/home_cubit_test.dart` - using `bloc_test`, locks in cubit contract before features are added
5. `test/features/home_page/presentation/home_page_test.dart` - widget test demonstrating `getIt` override pattern

---

*Testing analysis: 2026-04-16*
