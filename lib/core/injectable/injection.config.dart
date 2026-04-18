// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:firebase_analytics/firebase_analytics.dart' as _i398;
import 'package:firebase_performance/firebase_performance.dart' as _i346;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/home_page/data/local_database/counter_local_database.dart'
    as _i448;
import '../../features/home_page/data/repository/counter_repository.dart'
    as _i825;
import '../../features/home_page/domain/counter_service.dart' as _i508;
import '../../features/home_page/presentation/cubit/home_cubit.dart' as _i203;
import '../../features/rive_demo/presentation/cubit/rive_demo_cubit.dart'
    as _i992;
import '../auth/auth_service.dart' as _i88;
import '../auth/fake_auth_service.dart' as _i387;
import '../auth/firebase_auth_service.dart' as _i491;
import '../coach_mark/coach_mark_service.dart' as _i750;
import '../database/app_database.dart' as _i982;
import '../database/database_module.dart' as _i215;
import '../firebase/firebase_module.dart' as _i1055;
import '../preferences/preferences_service.dart' as _i929;
import '../preferences/preferences_service_impl.dart' as _i480;
import '../secure_storage/secure_storage_service.dart' as _i611;
import '../secure_storage/secure_storage_service_impl.dart' as _i220;

const String _dev = 'dev';
const String _prod = 'prod';

// initializes the registration of main-scope dependencies inside of GetIt
_i174.GetIt $initGetIt(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) {
  final gh = _i526.GetItHelper(getIt, environment, environmentFilter);
  final databaseModule = _$DatabaseModule();
  final firebaseModule = _$FirebaseModule();
  gh.factory<_i992.RiveDemoCubit>(() => _i992.RiveDemoCubit());
  gh.lazySingleton<_i982.AppDatabase>(() => databaseModule.appDatabase);
  gh.lazySingleton<_i611.SecureStorageService>(
    () => _i220.SecureStorageServiceImpl(),
  );
  gh.lazySingleton<_i929.PreferencesService>(
    () => _i480.PreferencesServiceImpl(),
  );
  gh.lazySingleton<_i88.AuthService>(
    () => _i387.FakeAuthService(),
    registerFor: {_dev},
  );
  gh.lazySingleton<_i398.FirebaseAnalytics>(
    () => firebaseModule.analytics,
    registerFor: {_prod},
  );
  gh.lazySingleton<_i346.FirebasePerformance>(
    () => firebaseModule.performance,
    registerFor: {_prod},
  );
  gh.lazySingleton<_i974.FirebaseFirestore>(
    () => firebaseModule.firestore,
    registerFor: {_prod},
  );
  gh.lazySingleton<_i750.CoachMarkService>(
    () => _i750.CoachMarkService(gh<_i929.PreferencesService>()),
  );
  gh.lazySingleton<_i448.CounterLocalDataBase>(
    () => _i448.CounterLocalDataBaseImpl(gh<_i982.AppDatabase>()),
  );
  gh.lazySingleton<_i88.AuthService>(
    () => _i491.FirebaseAuthService(),
    registerFor: {_prod},
    dispose: (i) => i.dispose(),
  );
  gh.lazySingleton<_i825.CounterRepository>(
    () => _i825.CounterRepositoryImpl(gh<_i448.CounterLocalDataBase>()),
  );
  gh.lazySingleton<_i508.CounterService>(
    () => _i508.CounterServiceImpl(gh<_i825.CounterRepository>()),
  );
  gh.factory<_i203.HomeCubit>(
    () => _i203.HomeCubit(gh<_i508.CounterService>()),
  );
  return getIt;
}

class _$DatabaseModule extends _i215.DatabaseModule {}

class _$FirebaseModule extends _i1055.FirebaseModule {}
