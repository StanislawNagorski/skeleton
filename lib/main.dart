import 'package:flutter/material.dart';

import 'package:skeleton/app.dart';
import 'package:skeleton/core/auth/auth_service.dart';
import 'package:skeleton/core/injectable/injection.dart';
import 'package:skeleton/core/preferences/preferences_keys.dart';
import 'package:skeleton/core/preferences/preferences_service.dart';
import 'package:skeleton/core/router/guards/onboarding_guard.dart';
import 'package:skeleton/core/router/router.dart';
import 'package:skeleton/startup_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StartUpService.initServices();

  final authService = getIt<AuthService>();
  final preferencesService = getIt<PreferencesService>();

  // Pre-read onboarding flag to avoid async I/O in the guard
  // (Pitfall 1: prevents white flash on cold start).
  final hasSeenOnboarding = await preferencesService.getBool(
        PreferencesKeys.hasSeenOnboarding,
      ) ??
      false;

  final onboardingGuard = OnboardingGuard(
    hasSeenOnboarding: hasSeenOnboarding,
  );
  final appRouter = AppRouter(
    authService,
    onboardingGuard: onboardingGuard,
  );

  runApp(
    MyApp(
      appRouter: appRouter,
      authService: authService,
      onboardingGuard: onboardingGuard,
    ),
  );
}
