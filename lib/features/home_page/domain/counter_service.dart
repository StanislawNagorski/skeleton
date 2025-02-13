import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../core/errors/failures.dart';
import '../data/model/counter_model.dart';
import '../data/repository/counter_repository.dart';

//Purpose of service is to connect with multiple repositories, it can also handle some business logic which is not related to UI
abstract class CounterService {
  Future<Either<Failure, CounterModel>> getCounter();
  Future<Either<Failure, void>> setCounter({required CounterModel counter});
  Stream<Either<Failure, CounterModel>> watchCounter();
}

@Injectable(as: CounterService)
class CounterServiceImpl implements CounterService {
  CounterServiceImpl(this._repository);

  final CounterRepository _repository;

  @override
  Future<Either<Failure, CounterModel>> getCounter() async => _repository.getCounter();


  @override
  Future<Either<Failure, void>> setCounter({required CounterModel counter}) => _repository.setCounter(counter: counter);

  @override
  Stream<Either<Failure, CounterModel>> watchCounter() => _repository.watchCounter();
}
