import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'package:skeleton/core/auth/auth_service.dart';
import 'package:skeleton/core/localization/app_localizations.dart';
import 'package:skeleton/core/presentation/app_themes.dart';
import 'package:skeleton/core/router/guards/onboarding_guard.dart';
import 'package:skeleton/core/router/router.dart';

class MyApp extends StatefulWidget {
  const MyApp({
    required this.appRouter,
    required this.authService,
    required this.onboardingGuard,
    super.key,
  });

  final AppRouter appRouter;
  final AuthService authService;
  final OnboardingGuard onboardingGuard;

  /// Global notifier that triggers router guard re-evaluation
  /// when onboarding completes. Fired by `OnboardingCubit`.
  static final ValueNotifier<bool> onboardingNotifier =
      ValueNotifier<bool>(false);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) => MaterialApp.router(
        title: 'Skeleton APP',
        routerConfig: widget.appRouter.config(
          reevaluateListenable: Listenable.merge([
            ReevaluateListenable.stream(
              widget.authService.authStateChanges,
            ),
            MyApp.onboardingNotifier,
          ]),
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
