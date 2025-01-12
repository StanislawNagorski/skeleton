import 'package:flutter/material.dart';
import 'package:skeleton/startup_service.dart';

import 'app.dart';
import 'core/router/router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StartUpService.initServices();
  final appRouter = AppRouter();

  runApp(MyApp(
    appRouter: appRouter,
  ));
}
