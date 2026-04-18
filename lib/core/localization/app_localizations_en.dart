// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get homePage_title => 'Skeleton App';

  @override
  String get homePage_centeredText =>
      'You have pushed the button this many times:';

  @override
  String get homePage_incrementButton => 'Increment';

  @override
  String get homePage_decrementButton => 'Decrement';

  @override
  String get homePage_error => 'An error occurred';

  @override
  String get homePage_riveDemoButton => 'RIVE Demo';

  @override
  String get onboarding_slide1Title => 'Welcome';

  @override
  String get onboarding_slide1Subtitle =>
      'Your new app is ready to go. Let\'s take a quick tour.';

  @override
  String get onboarding_slide2Title => 'Discover Features';

  @override
  String get onboarding_slide2Subtitle =>
      'Everything you need, built with clean architecture.';

  @override
  String get onboarding_slide3Title => 'Get Started';

  @override
  String get onboarding_slide3Subtitle =>
      'You\'re all set. Dive in and make it yours.';

  @override
  String get onboarding_skipButton => 'Skip';

  @override
  String get onboarding_nextButton => 'Next';

  @override
  String get onboarding_getStartedButton => 'Get Started';

  @override
  String get coachMark_counterTitle => 'This is your counter';

  @override
  String get coachMark_counterBody => 'Tap the button below to increment it.';

  @override
  String get coachMark_fabTitle => 'Increment';

  @override
  String get coachMark_fabBody => 'Tap this button to increase the counter.';

  @override
  String get riveDemo_title => 'RIVE Demo';

  @override
  String get riveDemo_toggleLabel => 'Toggle animation state';

  @override
  String get riveDemo_description =>
      'This toggle sends a boolean input to the RIVE state machine.';

  @override
  String riveDemo_animationLoadError(Object error) {
    return 'Failed to load animation: $error';
  }

  @override
  String get onboarding_skipSemanticLabel => 'Skip onboarding';

  @override
  String get login_placeholderText => 'Login screen — built per app';

  @override
  String get app_title => 'Skeleton App';

  @override
  String get auth_userNotFound => 'No account found with this email.';

  @override
  String get auth_wrongPassword => 'Incorrect password.';

  @override
  String get auth_invalidEmail => 'Invalid email address.';

  @override
  String get auth_userDisabled => 'This account has been disabled.';

  @override
  String get auth_emailAlreadyInUse =>
      'An account already exists with this email.';

  @override
  String get auth_weakPassword => 'Password is too weak.';

  @override
  String get auth_tooManyRequests => 'Too many attempts. Try again later.';

  @override
  String get auth_operationNotAllowed => 'This sign-in method is not enabled.';

  @override
  String get auth_invalidCredential => 'Invalid credentials.';

  @override
  String auth_genericError(String code) {
    return 'Authentication error: $code';
  }
}
