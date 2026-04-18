// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CounterEntriesTable extends CounterEntries
    with TableInfo<$CounterEntriesTable, CounterEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CounterEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<int> value = GeneratedColumn<int>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [id, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'counter_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<CounterEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CounterEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CounterEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $CounterEntriesTable createAlias(String alias) {
    return $CounterEntriesTable(attachedDatabase, alias);
  }
}

class CounterEntry extends DataClass implements Insertable<CounterEntry> {
  final int id;
  final int value;
  const CounterEntry({required this.id, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['value'] = Variable<int>(value);
    return map;
  }

  CounterEntriesCompanion toCompanion(bool nullToAbsent) {
    return CounterEntriesCompanion(id: Value(id), value: Value(value));
  }

  factory CounterEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CounterEntry(
      id: serializer.fromJson<int>(json['id']),
      value: serializer.fromJson<int>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'value': serializer.toJson<int>(value),
    };
  }

  CounterEntry copyWith({int? id, int? value}) =>
      CounterEntry(id: id ?? this.id, value: value ?? this.value);
  CounterEntry copyWithCompanion(CounterEntriesCompanion data) {
    return CounterEntry(
      id: data.id.present ? data.id.value : this.id,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CounterEntry(')
          ..write('id: $id, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CounterEntry &&
          other.id == this.id &&
          other.value == this.value);
}

class CounterEntriesCompanion extends UpdateCompanion<CounterEntry> {
  final Value<int> id;
  final Value<int> value;
  const CounterEntriesCompanion({
    this.id = const Value.absent(),
    this.value = const Value.absent(),
  });
  CounterEntriesCompanion.insert({
    this.id = const Value.absent(),
    this.value = const Value.absent(),
  });
  static Insertable<CounterEntry> custom({
    Expression<int>? id,
    Expression<int>? value,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (value != null) 'value': value,
    });
  }

  CounterEntriesCompanion copyWith({Value<int>? id, Value<int>? value}) {
    return CounterEntriesCompanion(
      id: id ?? this.id,
      value: value ?? this.value,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (value.present) {
      map['value'] = Variable<int>(value.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CounterEntriesCompanion(')
          ..write('id: $id, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CounterEntriesTable counterEntries = $CounterEntriesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [counterEntries];
}

typedef $$CounterEntriesTableCreateCompanionBuilder =
    CounterEntriesCompanion Function({Value<int> id, Value<int> value});
typedef $$CounterEntriesTableUpdateCompanionBuilder =
    CounterEntriesCompanion Function({Value<int> id, Value<int> value});

class $$CounterEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $CounterEntriesTable> {
  $$CounterEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CounterEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $CounterEntriesTable> {
  $$CounterEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CounterEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $CounterEntriesTable> {
  $$CounterEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$CounterEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CounterEntriesTable,
          CounterEntry,
          $$CounterEntriesTableFilterComposer,
          $$CounterEntriesTableOrderingComposer,
          $$CounterEntriesTableAnnotationComposer,
          $$CounterEntriesTableCreateCompanionBuilder,
          $$CounterEntriesTableUpdateCompanionBuilder,
          (
            CounterEntry,
            BaseReferences<_$AppDatabase, $CounterEntriesTable, CounterEntry>,
          ),
          CounterEntry,
          PrefetchHooks Function()
        > {
  $$CounterEntriesTableTableManager(
    _$AppDatabase db,
    $CounterEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CounterEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CounterEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CounterEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> value = const Value.absent(),
              }) => CounterEntriesCompanion(id: id, value: value),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> value = const Value.absent(),
              }) => CounterEntriesCompanion.insert(id: id, value: value),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CounterEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CounterEntriesTable,
      CounterEntry,
      $$CounterEntriesTableFilterComposer,
      $$CounterEntriesTableOrderingComposer,
      $$CounterEntriesTableAnnotationComposer,
      $$CounterEntriesTableCreateCompanionBuilder,
      $$CounterEntriesTableUpdateCompanionBuilder,
      (
        CounterEntry,
        BaseReferences<_$AppDatabase, $CounterEntriesTable, CounterEntry>,
      ),
      CounterEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CounterEntriesTableTableManager get counterEntries =>
      $$CounterEntriesTableTableManager(_db, _db.counterEntries);
}
