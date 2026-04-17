import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:skeleton/core/errors/failures.dart';
import 'package:skeleton/features/home_page/data/local_database/counter_local_database.dart';
import 'package:skeleton/features/home_page/data/model/counter_model.dart';

/// Repository handles errors while fetching data from data sources.
abstract class CounterRepository {
  Future<Either<AppFailure, CounterModel>> getCounter();
  Future<Either<AppFailure, void>> setCounter({
    required CounterModel counter,
  });
  Stream<Either<AppFailure, CounterModel>> watchCounter();
}

@Injectable(as: CounterRepository)
class CounterRepositoryImpl implements CounterRepository {
  CounterRepositoryImpl(this._localDataBase);

  final CounterLocalDataBase _localDataBase;
  final Logger _logger = Logger();

  @override
  Future<Either<AppFailure, CounterModel>> getCounter() async {
    try {
      final counter = await _localDataBase.getCounter();
      if (counter == null) {
        return const Left(
          LocalDataNotFound('Counter not found'),
        );
      }
      return Right(counter);
    } on Exception catch (e) {
      _logger.e('Local data source exception: $e');
      return Left(LocalDataSource(e.toString()));
    }
  }

  @override
  Future<Either<AppFailure, void>> setCounter({
    required CounterModel counter,
  }) async {
    try {
      await _localDataBase.setCounter(counter);
      return const Right(null);
    } on Exception catch (e) {
      _logger.e('Local data source exception: $e');
      return Left(LocalDataSource(e.toString()));
    }
  }

  @override
  Stream<Either<AppFailure, CounterModel>> watchCounter() =>
      _localDataBase.watchCounter().map((counter) {
        try {
          if (counter == null) {
            _logger.e('Counter not found locally');
            return const Left(
              LocalDataNotFound('Counter not found'),
            );
          }
          return Right(counter);
        } on Exception catch (e) {
          _logger.e('Local data source exception: $e');
          return Left(LocalDataSource(e.toString()));
        }
      });
}
