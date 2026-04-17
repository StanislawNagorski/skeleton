import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:skeleton/core/errors/result.dart';
import 'package:skeleton/features/home_page/data/model/counter_model.dart';
import 'package:skeleton/features/home_page/domain/counter_service.dart';

part 'home_state.dart';

/// Manages counter page state.
@injectable
class HomeCubit extends Cubit<HomeState> {
  /// Creates a [HomeCubit] backed by the given [CounterService].
  HomeCubit(this._counterService) : super(HomeState.initial());

  final CounterService _counterService;
  StreamSubscription<Result<CounterModel>>? _counterStream;

  /// Initializes the counter -- creates a default if none exists,
  /// then subscribes to reactive updates.
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
            emit(
              state.copyWith(
                status: HomePageStatus.success,
                counter: value,
              ),
            );
          case Failure():
            emit(state.copyWith(status: HomePageStatus.error));
        }
      },
    );
  }

  /// Increments the counter by 1.
  void increment() {
    final updatedData = state.counter.copyWith(
      value: state.counter.value + 1,
    );
    unawaited(
      _counterService.setCounter(counter: updatedData),
    );
  }

  /// Decrements the counter by 1.
  void decrement() {
    final updatedData = state.counter.copyWith(
      value: state.counter.value - 1,
    );
    unawaited(
      _counterService.setCounter(counter: updatedData),
    );
  }

  Future<CounterModel?> _getCounter() async {
    final result = await _counterService.getCounter();
    return result.valueOrNull;
  }

  @override
  Future<void> close() async {
    await _counterStream?.cancel();
    return super.close();
  }
}
