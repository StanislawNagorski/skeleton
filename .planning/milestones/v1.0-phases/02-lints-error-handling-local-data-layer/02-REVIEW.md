---
phase: 02-lints-error-handling-local-data-layer
reviewed: 2026-04-17T12:00:00Z
depth: standard
files_reviewed: 27
files_reviewed_list:
  - lib/app.dart
  - lib/core/database/app_database.dart
  - lib/core/database/database_module.dart
  - lib/core/database/tables/counter_entries.dart
  - lib/core/errors/failures.dart
  - lib/core/errors/result.dart
  - lib/core/injectable/injection.dart
  - lib/core/preferences/preferences_service.dart
  - lib/core/preferences/preferences_service_impl.dart
  - lib/core/presentation/app_colors.dart
  - lib/core/presentation/app_dimensions.dart
  - lib/core/presentation/app_images.dart
  - lib/core/presentation/app_themes.dart
  - lib/core/router/router.dart
  - lib/core/secure_storage/secure_storage_service.dart
  - lib/core/secure_storage/secure_storage_service_impl.dart
  - lib/core/utils/debouncer.dart
  - lib/features/home_page/data/local_database/counter_local_database.dart
  - lib/features/home_page/data/model/counter_model.dart
  - lib/features/home_page/data/repository/counter_repository.dart
  - lib/features/home_page/domain/counter_service.dart
  - lib/features/home_page/presentation/cubit/home_cubit.dart
  - lib/features/home_page/presentation/cubit/home_state.dart
  - lib/features/home_page/presentation/home_page.dart
  - lib/main.dart
  - lib/startup_service.dart
findings:
  critical: 0
  warning: 5
  info: 4
  total: 9
status: issues_found
---

# Phase 2: Code Review Report

**Reviewed:** 2026-04-17T12:00:00Z
**Depth:** standard
**Files Reviewed:** 27
**Status:** issues_found

## Summary

The codebase has been significantly cleaned up from the prior ObjectBox + dartz architecture to a Drift + sealed-class Result pattern. The new `Result<T>` / `AppFailure` hierarchy is well-designed and leverages Dart 3 sealed classes correctly. The Drift database layer, preferences service, and secure storage service are cleanly abstracted with proper interface/impl separation.

Key concerns: the `increment`/`decrement` methods in `HomeCubit` silently discard `setCounter` failures with `unawaited`, the `watchCounter` stream in the repository has a `try/catch` that can never trigger (the `.map` callback receives a nullable value, not an exception), and the `setCounter` upsert logic may create duplicate rows instead of updating the existing one.

## Warnings

### WR-01: `increment`/`decrement` silently discard write failures

**File:** `lib/features/home_page/presentation/cubit/home_cubit.dart:48-65`
**Issue:** Both `increment()` and `decrement()` wrap the `setCounter` call in `unawaited()`, which means any `Failure` result from the repository is silently discarded. If the write fails (e.g., database locked, disk full), the UI shows the optimistic counter value from the stream but the user gets no feedback that the write was lost. The stream will re-emit the old value, causing the counter to visually "jump back" without explanation.
**Fix:** At minimum, await the result and emit an error state on failure:
```dart
void increment() {
  final updatedData = state.counter.copyWith(
    value: state.counter.value + 1,
  );
  _counterService.setCounter(counter: updatedData).then((result) {
    if (result is Failure) {
      emit(state.copyWith(status: HomePageStatus.error));
    }
  });
}
```

### WR-02: `watchCounter` try/catch in `.map` is unreachable dead code

**File:** `lib/features/home_page/data/repository/counter_repository.dart:62-79`
**Issue:** The `try/catch` inside the `.map((entry) { ... })` callback wraps only a null check and `CounterModel` constructor call -- neither of which can throw an `Exception`. The `catch` block at line 73 is dead code. If the underlying Drift stream emits an error, it will propagate as a stream error (not through `.map`), bypassing this catch entirely. This means stream-level database errors are unhandled.
**Fix:** Use `handleError` or `transform` to catch stream errors:
```dart
@override
Stream<Result<CounterModel>> watchCounter() {
  return _localDataBase.watchCounter().map((entry) {
    if (entry == null) {
      return const Failure<CounterModel>(
        LocalDataNotFound('Counter not found'),
      );
    }
    return Success(
      CounterModel(id: entry.id, value: entry.value),
    );
  }).handleError((Object e) {
    _logger.e('Local data source stream error: $e');
    return Failure<CounterModel>(
      LocalDataSource(e.toString()),
    );
  });
}
```

### WR-03: `setCounter` upsert may create duplicate rows

**File:** `lib/features/home_page/data/local_database/counter_local_database.dart:38-41`
**Issue:** `insertOnConflictUpdate` with `CounterEntriesCompanion.insert(value: Value(value))` creates a new companion without specifying `id`. Since `id` is `autoIncrement()`, each call inserts a new row with the next auto-increment ID. The "on conflict update" clause only triggers when the primary key conflicts, but a new auto-increment ID never conflicts. Over time this creates unbounded rows, and `getCounter()` (which uses `limit(1)`) will return an arbitrary one (likely the first, not the latest).
**Fix:** Use a fixed sentinel ID for the single-row pattern:
```dart
@override
Future<void> setCounter({required int value}) async {
  await _db.into(_db.counterEntries).insertOnConflictUpdate(
    CounterEntriesCompanion(
      id: const Value(1),
      value: Value(value),
    ),
  );
}
```

### WR-04: `_Page` reads cubit outside `BlocBuilder` -- stale closure risk

**File:** `lib/features/home_page/presentation/home_page.dart:92-101`
**Issue:** `context.read<HomeCubit>().increment` and `.decrement` are evaluated during `build()` of `_Page`, which is a `StatelessWidget` whose `build` context sits outside the `BlocBuilder`. The `onPressed` callbacks capture the cubit reference at build time, which is fine for `read` (it does not rebuild on state change). However, because `_Page` is `const` and placed as `child:` of `BlocListener`, it will only rebuild if its parent rebuilds. If the cubit is ever replaced (e.g., in tests or hot-reload scenarios), the stale reference persists. This is a minor risk in practice but worth noting for skeleton correctness.
**Fix:** Wrap the FAB row in a `Builder` or use `context.read` inside the `onPressed` callback directly:
```dart
onPressed: () => context.read<HomeCubit>().increment(),
```

### WR-05: No `@override` of `toString` / `==` / `hashCode` on `HomeState` or `CounterModel`

**File:** `lib/features/home_page/presentation/cubit/home_state.dart:3-31` and `lib/features/home_page/data/model/counter_model.dart:5-19`
**Issue:** `flutter_bloc` uses `==` to determine whether to emit a new state. Without overriding `==` and `hashCode`, every `copyWith` call creates a new instance that is always `!=` the previous one (reference equality). This means `BlocBuilder` rebuilds on every emission even when no fields changed. While `buildWhen` partially mitigates this on line 76-78 of `home_page.dart`, the `BlocListener` at line 18 has no `listenWhen` and will fire on every emission. This causes redundant snackbar triggers.
**Fix:** Add `Equatable` or manually override `==` and `hashCode`:
```dart
// In HomeState:
@override
bool operator ==(Object other) =>
    identical(this, other) ||
    other is HomeState &&
        status == other.status &&
        navigation == other.navigation &&
        counter == other.counter;

@override
int get hashCode => Object.hash(status, navigation, counter);
```

## Info

### IN-01: `AppImages` has a suppressed unused field lint

**File:** `lib/core/presentation/app_images.dart:3`
**Issue:** The `// ignore: unused_field` comment suppresses the lint for `_path`. This is intentional scaffolding, but the comment format is non-standard -- it should be `// ignore: unused_field` on the line above the field, not inline. Currently it is on line 3 while the field is on line 4, which is correct placement.
**Fix:** No action needed -- just noting for awareness. Consider using a `// TODO(bootstrap)` marker instead to signal it is scaffolding.

### IN-02: `startup_service.dart` blanket `ignore_for_file` suppressions

**File:** `lib/startup_service.dart:1-2`
**Issue:** `// ignore_for_file: unused_import, unused_element` and `// ignore_for_file: discarded_futures` suppress lints for the entire file. This is reasonable for scaffolded Firebase code that is intentionally commented out, but it will also suppress warnings for any future imports or methods added to this file that genuinely are unused.
**Fix:** Consider scoping ignores to specific lines rather than the whole file, or add a `// TODO(bootstrap)` comment explaining the scope.

### IN-03: `Debouncer.close()` is never called in the reviewed codebase

**File:** `lib/core/utils/debouncer.dart:19-22`
**Issue:** The `close()` method exists for cleanup, but no consumer in the reviewed files calls it. If a `Debouncer` is used in a widget or cubit that gets disposed, the timer could fire after disposal.
**Fix:** Ensure any future consumer calls `close()` in `dispose()` or `close()` lifecycle methods.

### IN-04: `CounterServiceImpl.getCounter` has redundant `async`

**File:** `lib/features/home_page/domain/counter_service.dart:28-29`
**Issue:** `getCounter()` is marked `async` but just returns `_repository.getCounter()` which already returns a `Future`. The `async` keyword adds an unnecessary extra microtask.
**Fix:**
```dart
@override
Future<Result<CounterModel>> getCounter() => _repository.getCounter();
```

---

_Reviewed: 2026-04-17T12:00:00Z_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
