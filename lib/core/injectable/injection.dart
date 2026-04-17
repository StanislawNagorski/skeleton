import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:skeleton/core/injectable/injection.config.dart';

/// Configures dependency injection generator.
///
/// Run build runner every time when adding new dependencies:
/// ```sh
/// flutter pub run build_runner build
/// flutter pub run build_runner build --delete-conflicting-outputs
/// ```
final GetIt getIt = GetIt.instance;

@InjectableInit(
  initializerName: r'$initGetIt',
  preferRelativeImports: true,
  asExtension: false,
)
/// Invoke at app start.
Future<void> configureDependenciesApp() async => $initGetIt(getIt);
