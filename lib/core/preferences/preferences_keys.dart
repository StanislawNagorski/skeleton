/// Centralized preference key constants.
///
/// All `PreferencesService` consumers reference keys from here
/// rather than scattering magic strings across features.
abstract class PreferencesKeys {
  static const String hasSeenOnboarding = 'hasSeenOnboarding';
  static const String tourHomeCompleted = 'tour_home_seen';
}
