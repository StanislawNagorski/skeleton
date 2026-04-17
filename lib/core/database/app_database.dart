import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:injectable/injectable.dart';

import 'tables/counter_entries.dart';

part 'app_database.g.dart';

/// Central Drift database registered as a lazy singleton in the DI
/// graph.
///
/// Tables are registered here. Feature-level data sources receive this
/// instance via constructor injection.
@lazySingleton
@DriftDatabase(tables: [CounterEntries])
class AppDatabase extends _$AppDatabase {
  /// Production constructor -- uses platform-appropriate SQLite file.
  AppDatabase() : super(_openConnection());

  /// Testing constructor -- accepts any [QueryExecutor] (e.g.,
  /// `NativeDatabase.memory()`).
  @visibleForTesting
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'skeleton_db');
  }
}
