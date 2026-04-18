// ignore_for_file: discarded_futures

import 'dart:isolate';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:rive/rive.dart';

import 'package:skeleton/core/injectable/injection.dart';
import 'package:skeleton/firebase_options.dart';

/// Bootstraps the app: Firebase init (with dev fallback), error
/// reporting, App Check, and dependency injection.
abstract class StartUpService {
  static final Logger _logger = Logger();

  /// Full startup sequence per D-03:
  ///
  /// 1. WidgetsFlutterBinding.ensureInitialized() -- called by main()
  /// 2. Firebase.initializeApp(options: currentPlatform)
  /// 3. If success: env='prod', wire Crashlytics + App Check
  /// 4. If failure: env='dev' (FakeAuthService, no Firebase deps)
  /// 5. configureDependenciesApp(environment: env)
  static Future<void> initServices() async {
    var environment = 'dev';

    // UX-06: Initialize RIVE native C++ runtime before any RIVE widget loads.
    await RiveNative.init();

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      environment = 'prod';
      _configureCrashlytics();
      await _configureAppCheck();
    } on Object catch (e) {
      // No Firebase config files -- running in dev mode (D-01).
      // The stub firebase_options.dart throws UnsupportedError (an
      // Error, not Exception), so we catch Object to handle both.
      // FakeAuthService will be registered; no Firebase services
      // in DI.
      _logger.w('Firebase not configured: $e. '
          'Running in dev mode.');
    }

    await configureDependenciesApp(environment: environment);
  }

  /// Wires the Crashlytics error handler trio per D-07/D-08.
  ///
  /// - Handler 1: Flutter framework errors via FlutterError.onError
  /// - Handler 2: Async Dart errors via
  ///   PlatformDispatcher.instance.onError
  /// - Handler 3: Spawned isolate errors via
  ///   Isolate.current.addErrorListener
  ///
  /// Collection disabled in debug (D-07): debug crashes stay in
  /// console only.
  static void _configureCrashlytics() {
    // D-07: No dashboard noise from dev sessions.
    FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(kReleaseMode);

    // Handler 1: Flutter framework errors (synchronous).
    FlutterError.onError =
        FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Handler 2: Async Dart errors not caught by the Flutter
    // framework.
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance
          .recordError(error, stack, fatal: true);
      return true;
    };

    // Handler 3: Errors in spawned isolates (D-08).
    // Catches errors from downstream app isolates (image
    // processing, Drift heavy queries, etc.).
    Isolate.current.addErrorListener(
      RawReceivePort((dynamic pair) async {
        final errorAndStack = pair as List<dynamic>;
        await FirebaseCrashlytics.instance.recordError(
          errorAndStack[0],
          StackTrace.fromString(
            errorAndStack[1] as String,
          ),
          fatal: true,
        );
      }).sendPort,
    );
  }

  /// App Check release-only activation per D-09/D-10.
  ///
  /// Dev builds skip entirely -- no debug provider, no debug-token
  /// registration friction. Firebase endpoints are unprotected
  /// in dev.
  static Future<void> _configureAppCheck() async {
    if (!kReleaseMode) return; // D-10: Skip entirely in dev.

    await FirebaseAppCheck.instance.activate(
      // D-09: appAttest (not deviceCheck) on Apple.
      providerApple: const AppleAppAttestProvider(),
    );
  }
}
