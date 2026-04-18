// TEMPLATE: Copy this file for new feature cubit tests.
// Replace MockCounterService with your feature's service mock.
// Replace HomeCubit/HomeState with your feature's cubit/state.
//
// Pattern:
//   1. Create a Mock class extending Mock + implementing your service
//   2. Register fallback values for any types used with `any()`
//   3. Use blocTest<YourCubit, YourState>() for async state assertions
//   4. Use verify() to assert service calls were made

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:skeleton/core/errors/failures.dart';
import 'package:skeleton/core/errors/result.dart';
import 'package:skeleton/features/home_page/data/model/counter_model.dart';
import 'package:skeleton/features/home_page/domain/counter_service.dart';
import 'package:skeleton/features/home_page/presentation/cubit/home_cubit.dart';

// -- Mock setup --
// Extend Mock and implement the abstract service interface.
// mocktail generates stubs at runtime -- no build_runner needed.
class MockCounterService extends Mock implements CounterService {}

void main() {
  late MockCounterService mockService;

  setUp(() {
    mockService = MockCounterService();
    // Register fallback values so mocktail's `any()` matcher works
    // for typed arguments.
    registerFallbackValue(const CounterModel(value: 0));
  });

  group('HomeCubit', () {
    // -- Initial state --
    test('initial state has status=empty and counter.value=0', () {
      final cubit = HomeCubit(mockService);
      expect(cubit.state.status, HomePageStatus.empty);
      expect(cubit.state.counter.value, 0);
      addTearDown(cubit.close);
    });

    // -- init() success path --
    blocTest<HomeCubit, HomeState>(
      'emits [success] when init finds existing counter',
      build: () {
        when(() => mockService.getCounter()).thenAnswer(
          (_) async => const Success(CounterModel(value: 5)),
        );
        when(() => mockService.watchCounter()).thenAnswer(
          (_) => Stream.value(const Success(CounterModel(value: 5))),
        );
        return HomeCubit(mockService);
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        isA<HomeState>()
            .having((s) => s.status, 'status', HomePageStatus.success)
            .having((s) => s.counter.value, 'counter.value', 5),
      ],
    );

    // -- init() when no counter exists --
    blocTest<HomeCubit, HomeState>(
      'creates default counter when none exists, then watches',
      build: () {
        // getCounter returns failure (no data yet)
        when(() => mockService.getCounter()).thenAnswer(
          (_) async => const Failure(LocalDataNotFound('no counter')),
        );
        // setCounter succeeds (creates default)
        when(() => mockService.setCounter(counter: any(named: 'counter')))
            .thenAnswer((_) async => const Success(null));
        // watchCounter emits the newly created counter
        when(() => mockService.watchCounter()).thenAnswer(
          (_) => Stream.value(const Success(CounterModel(value: 0))),
        );
        return HomeCubit(mockService);
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        isA<HomeState>()
            .having((s) => s.status, 'status', HomePageStatus.success)
            .having((s) => s.counter.value, 'counter.value', 0),
      ],
      verify: (_) {
        // Verify setCounter was called once to create the default counter
        final captured = verify(
          () => mockService.setCounter(
            counter: captureAny(named: 'counter'),
          ),
        ).captured;
        expect(captured, hasLength(1));
        expect((captured.first as CounterModel).value, 0);
      },
    );

    // -- increment --
    blocTest<HomeCubit, HomeState>(
      'increment calls setCounter with value + 1',
      setUp: () {
        when(() => mockService.setCounter(counter: any(named: 'counter')))
            .thenAnswer((_) async => const Success(null));
      },
      build: () => HomeCubit(mockService),
      seed: () => const HomeState(
        status: HomePageStatus.success,
        navigation: HomePageNavigation.empty,
        counter: CounterModel(value: 5),
      ),
      act: (cubit) => cubit.increment(),
      verify: (_) {
        // Use any() matcher and capture the argument because CounterModel
        // does not override == (plain Dart class, not Equatable).
        final captured = verify(
          () => mockService.setCounter(
            counter: captureAny(named: 'counter'),
          ),
        ).captured;
        expect(captured, hasLength(1));
        expect((captured.first as CounterModel).value, 6);
      },
    );

    // -- decrement --
    blocTest<HomeCubit, HomeState>(
      'decrement calls setCounter with value - 1',
      setUp: () {
        when(() => mockService.setCounter(counter: any(named: 'counter')))
            .thenAnswer((_) async => const Success(null));
      },
      build: () => HomeCubit(mockService),
      seed: () => const HomeState(
        status: HomePageStatus.success,
        navigation: HomePageNavigation.empty,
        counter: CounterModel(value: 5),
      ),
      act: (cubit) => cubit.decrement(),
      verify: (_) {
        final captured = verify(
          () => mockService.setCounter(
            counter: captureAny(named: 'counter'),
          ),
        ).captured;
        expect(captured, hasLength(1));
        expect((captured.first as CounterModel).value, 4);
      },
    );

    // -- watch stream error --
    blocTest<HomeCubit, HomeState>(
      'emits [error] when watch stream emits Failure',
      build: () {
        when(() => mockService.getCounter()).thenAnswer(
          (_) async => const Success(CounterModel(value: 0)),
        );
        when(() => mockService.watchCounter()).thenAnswer(
          (_) => Stream.value(
            const Failure<CounterModel>(LocalDataSource('db error')),
          ),
        );
        return HomeCubit(mockService);
      },
      act: (cubit) => cubit.init(),
      expect: () => [
        isA<HomeState>()
            .having((s) => s.status, 'status', HomePageStatus.error),
      ],
    );
  });
}
