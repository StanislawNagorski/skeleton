import 'package:injectable/injectable.dart';
import 'package:skeleton/features/home_page/data/model/counter_model.dart';

// TODO(plan-02): Replace with Drift DAO. ObjectBox removed in Phase 2.

/// Data source for counter persistence.
abstract class CounterLocalDataBase {
  Future<CounterModel?> getCounter();
  Future<void> setCounter(CounterModel counter);
  Stream<CounterModel?> watchCounter();
}

@Injectable(as: CounterLocalDataBase)
class CounterLocalDataBaseImpl implements CounterLocalDataBase {
  CounterModel? _inMemoryCounter;

  @override
  Future<CounterModel?> getCounter() async => _inMemoryCounter;

  @override
  Future<void> setCounter(CounterModel counter) async {
    _inMemoryCounter = counter;
  }

  @override
  Stream<CounterModel?> watchCounter() =>
      Stream<CounterModel?>.value(_inMemoryCounter);
}
