import 'package:path_provider/path_provider.dart' as p;

import 'objectbox.g.dart';
export 'objectbox.g.dart';


abstract class ObjectBox {

  static Store? _store;

  static Future<void> initObjectBox() async {
    if (_store != null) return; // already initialized

    final docsDir = await p.getApplicationDocumentsDirectory();
    _store = await openStore(directory: docsDir.path);
  }

  static Box<T> getBox<T>() {
    return store.box<T>();
  }

  //get store if you want use transactions operations like:
  // ObjectBoxBuilder.store.runInTransaction(TxMode.write, () {
  // final counterBox = ObjectBoxBuilder.getBox<CounterModel>();
  // counterBox.put(CounterModel(value: 10));
  // counterBox.put(CounterModel(value: 20));
  // });
  //https://docs.objectbox.io/transactions
  static Store get store {
    if (_store == null) {
      throw Exception("ObjectBox not initialized. Call initObjectBox() first.");
    }
    return _store!;
  }

  static void close() {
    _store?.close();
    _store = null;
  }




}