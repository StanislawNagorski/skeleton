import 'package:injectable/injectable.dart';

import '../../../core/errors/result.dart';
import '../data/model/counter_model.dart';
import '../data/repository/counter_repository.dart';

/// Connects with counter repositories and handles non-UI business
/// logic.
abstract class CounterService {
  /// Reads the current counter value.
  Future<Result<CounterModel>> getCounter();

  /// Persists the counter value.
  Future<Result<void>> setCounter({required CounterModel counter});

  /// Watches counter changes reactively.
  Stream<Result<CounterModel>> watchCounter();
}

/// Implementation that delegates to [CounterRepository].
@LazySingleton(as: CounterService)
class CounterServiceImpl implements CounterService {
  /// Creates a [CounterServiceImpl] backed by the given
  /// [repository].
  CounterServiceImpl(this._repository);

  final CounterRepository _repository;

  @override
  Future<Result<CounterModel>> getCounter() async =>
      _repository.getCounter();

  @override
  Future<Result<void>> setCounter({
    required CounterModel counter,
  }) =>
      _repository.setCounter(counter: counter);

  @override
  Stream<Result<CounterModel>> watchCounter() =>
      _repository.watchCounter();
}
