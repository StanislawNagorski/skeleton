import 'package:drift/drift.dart';

/// Single-row counter table.
///
/// Uses upsert pattern: one row with autoIncrement id, integer value
/// defaulting to 0.
class CounterEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get value => integer().withDefault(const Constant(0))();
}
