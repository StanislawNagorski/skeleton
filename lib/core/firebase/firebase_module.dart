import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:injectable/injectable.dart';

/// Registers Firebase service instances in the `'prod'` DI
/// environment.
///
/// These are only available when Firebase is initialized (i.e. when
/// `flutterfire configure` has been run and config files are present).
/// The `'dev'` environment does not register these -- accessing them
/// without Firebase would throw.
@module
abstract class FirebaseModule {
  /// Firebase Analytics instance for event tracking.
  ///
  /// No events are wired in the skeleton -- analytics taxonomy
  /// is per-app. Registered so downstream features can inject it.
  @lazySingleton
  @Environment(Environment.prod)
  FirebaseAnalytics get analytics => FirebaseAnalytics.instance;

  /// Firebase Performance automatic tracing.
  ///
  /// Automatic tracing is enabled by default -- no manual traces
  /// are required for the skeleton counter example.
  @lazySingleton
  @Environment(Environment.prod)
  FirebasePerformance get performance =>
      FirebasePerformance.instance;

  /// Cloud Firestore with offline persistence enabled.
  ///
  /// Persistence is ON by default on mobile. Explicit settings
  /// for clarity and to document the skeleton's stance.
  @lazySingleton
  @Environment(Environment.prod)
  FirebaseFirestore get firestore => FirebaseFirestore.instance
    ..settings = const Settings(
      persistenceEnabled: true,
    );
}
