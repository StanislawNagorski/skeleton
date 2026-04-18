import 'package:injectable/injectable.dart';

import 'package:skeleton/core/database/app_database.dart';

/// Injectable module for registering [AppDatabase] as a lazy
/// singleton.
///
/// Drift's `@DriftDatabase` annotation conflicts with injectable's
/// annotation scanner on generated `_$AppDatabase` superclass, so we
/// register via a module instead.
@module
abstract class DatabaseModule {
  /// Provides the singleton [AppDatabase] instance.
  @lazySingleton
  AppDatabase get appDatabase => AppDatabase();
}
