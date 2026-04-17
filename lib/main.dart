import 'package:flutter/material.dart';
import 'package:skeleton/app.dart';
import 'package:skeleton/core/router/router.dart';
import 'package:skeleton/startup_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StartUpService.initServices();
  final appRouter = AppRouter();

  runApp(MyApp(
    appRouter: appRouter,
  ));
}
