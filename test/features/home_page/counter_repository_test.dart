// TEMPLATE: Copy this file for new feature repository tests.
// Replace AppDatabase tables + CounterLocalDataBaseImpl + CounterRepositoryImpl
// with your feature's equivalents.
//
// Key pattern: real Drift queries against in-memory SQLite -- no mocking of the
// database layer. This tests actual SQL statements, upsert behavior, and stream
// reactivity. Mocking happens at the service/cubit boundary instead.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeleton/core/database/app_database.dart';
import 'package:skeleton/core/errors/failures.dart';
import 'package:skeleton/core/errors/result.dart';
import 'package:skeleton/features/home_page/data/local_database/counter_local_database.dart';
import 'package:skeleton/features/home_page/data/model/counter_model.dart';
import 'package:skeleton/features/home_page/data/repository/counter_repository.dart';

void main() {
  // -- Setup: real Drift database with in-memory SQLite --
  // No mocks needed. Each test gets a fresh, empty database.
  late AppDatabase db;
  late CounterLocalDataBaseImpl dataSource;
  late CounterRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    dataSource = CounterLocalDataBaseImpl(db);
    repository = CounterRepositoryImpl(dataSource);
  });

  tearDown(() async {
    await db.close();
  });

  group('CounterRepository', () {
    // -- Empty state --
    test('getCounter returns Failure(LocalDataNotFound) when no data exists',
        () async {
      final result = await repository.getCounter();

      expect(result, isA<Failure<CounterModel>>());
      expect(
        (result as Failure<CounterModel>).failure,
        isA<LocalDataNotFound>(),
      );
    });

    // -- Set then get --
    test('setCounter then getCounter returns Success with correct value',
        () async {
      await repository.setCounter(
        counter: const CounterModel(value: 42),
      );

      final result = await repository.getCounter();

      expect(result, isA<Success<CounterModel>>());
      expect((result as Success<CounterModel>).value.value, 42);
    });

    // -- Upsert behavior --
    test('setCounter upserts -- second call overwrites first', () async {
      await repository.setCounter(
        counter: const CounterModel(value: 10),
      );
      await repository.setCounter(
        counter: const CounterModel(value: 20),
      );

      final result = await repository.getCounter();

      expect(result, isA<Success<CounterModel>>());
      expect((result as Success<CounterModel>).value.value, 20);
    });

    // -- Reactive watch stream --
    test('watchCounter emits updated values after setCounter calls', () async {
      // Start watching before any writes
      final stream = repository.watchCounter();

      // Expect the stream to emit: first LocalDataNotFound (empty),
      // then Success(1), then Success(2)
      final expectation = expectLater(
        stream,
        emitsInOrder([
          // Initial empty state
          isA<Failure<CounterModel>>(),
          // After first setCounter
          isA<Success<CounterModel>>().having(
            (r) => r.value.value,
            'value',
            1,
          ),
          // After second setCounter
          isA<Success<CounterModel>>().having(
            (r) => r.value.value,
            'value',
            2,
          ),
        ]),
      );

      // Give the stream a moment to register
      await Future<void>.delayed(const Duration(milliseconds: 50));

      await repository.setCounter(
        counter: const CounterModel(value: 1),
      );

      await Future<void>.delayed(const Duration(milliseconds: 50));

      await repository.setCounter(
        counter: const CounterModel(value: 2),
      );

      await expectation;
    });
  });
}
