import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:skeleton/features/home_page/data/model/counter_model.dart';

import '../../../../core/errors/failures.dart';
import '../local_database/counter_local_database.dart';

//Repository purpose is to handle errors while fetching data from the data sources
abstract class CounterRepository {
  Future<Either<Failure, CounterModel>> getCounter();
  Future<Either<Failure, void>> setCounter({required CounterModel counter});
  Stream<Either<Failure, CounterModel>> watchCounter();
}

@Injectable(as: CounterRepository)
class CounterRepositoryImpl implements CounterRepository {
  CounterRepositoryImpl(this._localDataBase);

  final CounterLocalDataBase _localDataBase;
  final Logger _logger = Logger();

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

  @override
  Future<Either<Failure, void>> setCounter({required CounterModel counter}) async {
    try {
      await _localDataBase.setCounter(counter);
      return Right(null);
    } catch (e) {
      _logger.e('Local data source exception: $e');
      return Left(Failure.localDataSource(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, CounterModel>> watchCounter() =>
      _localDataBase.watchCounter().map((counter) {
        try {
          if (counter == null) {
            _logger.e('Counter not found locally');
            return Left(Failure.localDataNotFound('Counter not found'));
          }
          return Right(counter);
        } catch (e) {
          _logger.e('Local data source exception: $e');
          return Left(Failure.localDataSource(e.toString()));
        }
      });
}
