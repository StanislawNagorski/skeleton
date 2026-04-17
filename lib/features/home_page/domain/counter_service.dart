import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:skeleton/core/errors/failures.dart';
import 'package:skeleton/features/home_page/data/model/counter_model.dart';
import 'package:skeleton/features/home_page/data/repository/counter_repository.dart';

/// Service connects multiple repositories and holds non-UI business logic.
abstract class CounterService {
  Future<Either<AppFailure, CounterModel>> getCounter();
  Future<Either<AppFailure, void>> setCounter({
    required CounterModel counter,
  });
  Stream<Either<AppFailure, CounterModel>> watchCounter();
}

@Injectable(as: CounterService)
class CounterServiceImpl implements CounterService {
  CounterServiceImpl(this._repository);

  final CounterRepository _repository;

  @override
  Future<Either<AppFailure, CounterModel>> getCounter() async =>
      _repository.getCounter();

  @override
  Future<Either<AppFailure, void>> setCounter({
    required CounterModel counter,
  }) =>
      _repository.setCounter(counter: counter);

  @override
  Stream<Either<AppFailure, CounterModel>> watchCounter() =>
      _repository.watchCounter();
}
