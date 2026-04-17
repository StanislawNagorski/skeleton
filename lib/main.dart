import 'package:flutter/material.dart';

import 'package:skeleton/app.dart';
import 'package:skeleton/core/auth/auth_service.dart';
import 'package:skeleton/core/injectable/injection.dart';
import 'package:skeleton/core/router/router.dart';
import 'package:skeleton/startup_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StartUpService.initServices();
  final authService = getIt<AuthService>();
  final appRouter = AppRouter(authService);

  runApp(MyApp(
    appRouter: appRouter,
    authService: authService,
  ));
}
