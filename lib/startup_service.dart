import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';


import 'core/injectable/injection.dart';


abstract class StartUpService {
  static Future<void> initServices() async {
    await _configureFirebase();
    await _configureDependencies();
    await _configureDatabases();
  }

  static Future<void> _configureDatabases() async {
    //TODO: init local database
  }

  static Future<void> _configureDependencies() async {
    await configureDependenciesApp();
  }

  static Future<void> _configureFirebase() async {
    //TODO: Add your Firebase by files or CLI
    // await Firebase.initializeApp(
    //   name: 'AppName',
    //   options: DefaultFirebaseOptions.currentPlatform,
    // );
    //TODO: uncomment after adding firebase
    // _configureCrashlytics();
    // await _configureAppCheck();
  }

  static void _configureCrashlytics() {
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(kReleaseMode);
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  static Future<void> _configureAppCheck() async {
    await FirebaseAppCheck.instance.activate(
      androidProvider: kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
      appleProvider: kReleaseMode ? AppleProvider.deviceCheck : AppleProvider.debug,
    );
  }

}
