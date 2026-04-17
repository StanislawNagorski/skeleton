import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import 'package:skeleton/core/database/app_database.dart';

/// Data source for counter persistence.
///
/// Queries Drift [AppDatabase] directly. Returns Drift-generated
/// `CounterEntry` types -- mapping to domain `CounterModel` happens
/// in the repository layer.
abstract class CounterLocalDataBase {
  /// Returns the first counter entry, or `null` if none exists.
  Future<CounterEntry?> getCounter();

  /// Upserts a counter entry with the given [value].
  Future<void> setCounter({required int value});

  /// Watches the first counter entry reactively.
  Stream<CounterEntry?> watchCounter();
}

/// Drift-backed implementation of [CounterLocalDataBase].
@LazySingleton(as: CounterLocalDataBase)
class CounterLocalDataBaseImpl implements CounterLocalDataBase {
  /// Creates a [CounterLocalDataBaseImpl] with the injected
  /// [AppDatabase].
  CounterLocalDataBaseImpl(this._db);

  final AppDatabase _db;

  @override
  Future<CounterEntry?> getCounter() async {
    return (_db.select(_db.counterEntries)..limit(1))
        .getSingleOrNull();
  }

  @override
  Future<void> setCounter({required int value}) async {
    await _db.into(_db.counterEntries).insertOnConflictUpdate(
          CounterEntriesCompanion(
            id: const Value(1),
            value: Value(value),
          ),
        );
  }

  @override
  Stream<CounterEntry?> watchCounter() {
    return (_db.select(_db.counterEntries)..limit(1))
        .watchSingleOrNull();
  }
}
