import 'package:injectable/injectable.dart';
import 'package:logger/logger.dart';
import 'package:skeleton/core/errors/failures.dart';
import 'package:skeleton/core/errors/result.dart';
import 'package:skeleton/features/home_page/data/local_database/counter_local_database.dart';
import 'package:skeleton/features/home_page/data/model/counter_model.dart';

/// Handles errors from counter data sources and returns typed
/// [Result]s.
abstract class CounterRepository {
  /// Reads the current counter value.
  Future<Result<CounterModel>> getCounter();

  /// Persists the counter value.
  Future<Result<void>> setCounter({required CounterModel counter});

  /// Watches counter changes as a reactive stream of [Result]s.
  Stream<Result<CounterModel>> watchCounter();
}

/// Implementation backed by [CounterLocalDataBase].
@LazySingleton(as: CounterRepository)
class CounterRepositoryImpl implements CounterRepository {
  /// Creates a [CounterRepositoryImpl] with the given data source.
  CounterRepositoryImpl(this._localDataBase);

  final CounterLocalDataBase _localDataBase;
  final Logger _logger = Logger();

  @override
  Future<Result<CounterModel>> getCounter() async {
    try {
      final entry = await _localDataBase.getCounter();
      if (entry == null) {
        return const Failure(
          LocalDataNotFound('Counter not found'),
        );
      }
      return Success(
        CounterModel(id: entry.id, value: entry.value),
      );
    } on Exception catch (e) {
      _logger.e('Local data source exception: $e');
      return Failure(LocalDataSource(e.toString()));
    }
  }

  @override
  Future<Result<void>> setCounter({
    required CounterModel counter,
  }) async {
    try {
      await _localDataBase.setCounter(value: counter.value);
      return const Success(null);
    } on Exception catch (e) {
      _logger.e('Local data source exception: $e');
      return Failure(LocalDataSource(e.toString()));
    }
  }

  @override
  Stream<Result<CounterModel>> watchCounter() {
    return _localDataBase.watchCounter().map((entry) {
      try {
        if (entry == null) {
          return const Failure<CounterModel>(
            LocalDataNotFound('Counter not found'),
          );
        }
        return Success(
          CounterModel(id: entry.id, value: entry.value),
        );
      } on Exception catch (e) {
        _logger.e('Local data source exception: $e');
        return Failure<CounterModel>(
          LocalDataSource(e.toString()),
        );
      }
    });
  }
}
