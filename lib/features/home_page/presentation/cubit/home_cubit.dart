import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:skeleton/features/home_page/data/model/counter_model.dart';
import 'package:skeleton/features/home_page/domain/counter_service.dart';

part 'home_state.dart';

@injectable
class HomeCubit extends Cubit<HomeState> {
  HomeCubit(this._counterService) : super(HomeState.initial());

  final CounterService _counterService;
  StreamSubscription? _counterStream;

  Future<void> init() async {
    final counter = await _getCounter();
    if (counter == null) {
      await _counterService.setCounter(counter: CounterModel(value: 0));
    }

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
  }

  void increment() {
    final data = state.counter;
    final updatedData = data.copyWith(value: data.value + 1);
    _counterService.setCounter(counter: updatedData);
  }

  void decrement() {
    final data = state.counter;
    final updatedData = data.copyWith(value: data.value - 1);
    _counterService.setCounter(counter: updatedData);
  }

  Future<CounterModel?> _getCounter() async => await _counterService.getCounter().then(
        (result) => result.fold((failure) => null, (data) => data),
      );
}
