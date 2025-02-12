import 'package:injectable/injectable.dart';
import 'package:skeleton/features/home_page/data/model/counter_model.dart';

import '../../../../core/local_database/object_box.dart';

//Purpose of data source is to fetch data, there should be no business logic here
abstract class CounterLocalDataBase {
  Future<CounterModel?> getCounter(int id);
  Future<void> setCounter(CounterModel counter);
  Stream<CounterModel?> watchCounter(int id);
}

@Injectable(as: CounterLocalDataBase)
class CounterLocalDataBaseImpl implements CounterLocalDataBase {

  final _counterBox = ObjectBox.getBox<CounterModel>();

  @override
  Future<CounterModel?> getCounter(int id) async => _counterBox.get(id);

  @override
  Future<void> setCounter(CounterModel counter) async => _counterBox.put(counter);

  @override
  Stream<CounterModel?> watchCounter(int id) => _counterBox
        .query(CounterModel_.id.equals(id))
        .watch(triggerImmediately: true)
        .map((query) => query.findFirst());

}
