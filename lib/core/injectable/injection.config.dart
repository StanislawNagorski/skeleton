// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import '../../features/home_page/data/local_database/counter_local_database.dart'
    as _i448;
import '../../features/home_page/data/repository/counter_repository.dart'
    as _i825;
import '../../features/home_page/domain/counter_service.dart' as _i508;
import '../../features/home_page/presentation/cubit/home_cubit.dart' as _i203;

// initializes the registration of main-scope dependencies inside of GetIt
_i174.GetIt $initGetIt(
  _i174.GetIt getIt, {
  String? environment,
  _i526.EnvironmentFilter? environmentFilter,
}) {
  final gh = _i526.GetItHelper(
    getIt,
    environment,
    environmentFilter,
  );
  gh.factory<_i448.CounterLocalDataBase>(
      () => _i448.CounterLocalDataBaseImpl());
  gh.factory<_i825.CounterRepository>(
      () => _i825.CounterRepositoryImpl(gh<_i448.CounterLocalDataBase>()));
  gh.factory<_i508.CounterService>(
      () => _i508.CounterServiceImpl(gh<_i825.CounterRepository>()));
  gh.factory<_i203.HomeCubit>(
      () => _i203.HomeCubit(gh<_i508.CounterService>()));
  return getIt;
}
