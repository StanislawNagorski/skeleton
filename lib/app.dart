import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';


import 'core/presentation/app_themes.dart';
import 'core/router/router.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.appRouter});

  final AppRouter appRouter;


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) => MaterialApp.router(
      title: 'Skeleton APP',
      routerConfig: appRouter.config(
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
