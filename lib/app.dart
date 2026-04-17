import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:skeleton/core/auth/auth_service.dart';
import 'package:skeleton/core/localization/app_localizations.dart';
import 'package:skeleton/core/presentation/app_themes.dart';
import 'package:skeleton/core/router/router.dart';

class MyApp extends StatelessWidget {
  const MyApp({
    required this.appRouter,
    required this.authService,
    super.key,
  });

  final AppRouter appRouter;
  final AuthService authService;

  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Skeleton APP',
        routerConfig: appRouter.config(
          reevaluateListenable: ReevaluateListenable.stream(
            authService.authStateChanges,
          ),
          navigatorObservers: () => [AppRouterObserver()],
        ),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          AppLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('pl', ''),
          Locale('en', ''),
        ],
        theme: AppThemes.light,
      );
}
