import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'localization/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pl'),
  ];

  /// No description provided for @homePage_title.
  ///
  /// In en, this message translates to:
  /// **'Skeleton App'**
  String get homePage_title;

  /// No description provided for @homePage_centeredText.
  ///
  /// In en, this message translates to:
  /// **'You have pushed the button this many times:'**
  String get homePage_centeredText;

  /// No description provided for @homePage_incrementButton.
  ///
  /// In en, this message translates to:
  /// **'Increment'**
  String get homePage_incrementButton;

  /// No description provided for @homePage_decrementButton.
  ///
  /// In en, this message translates to:
  /// **'Decrement'**
  String get homePage_decrementButton;

  /// No description provided for @homePage_error.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get homePage_error;

  /// No description provided for @homePage_riveDemoButton.
  ///
  /// In en, this message translates to:
  /// **'RIVE Demo'**
  String get homePage_riveDemoButton;

  /// No description provided for @onboarding_slide1Title.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get onboarding_slide1Title;

  /// No description provided for @onboarding_slide1Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your new app is ready to go. Let\'s take a quick tour.'**
  String get onboarding_slide1Subtitle;

  /// No description provided for @onboarding_slide2Title.
  ///
  /// In en, this message translates to:
  /// **'Discover Features'**
  String get onboarding_slide2Title;

  /// No description provided for @onboarding_slide2Subtitle.
  ///
  /// In en, this message translates to:
  /// **'Everything you need, built with clean architecture.'**
  String get onboarding_slide2Subtitle;

  /// No description provided for @onboarding_slide3Title.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboarding_slide3Title;

  /// No description provided for @onboarding_slide3Subtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all set. Dive in and make it yours.'**
  String get onboarding_slide3Subtitle;

  /// No description provided for @onboarding_skipButton.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboarding_skipButton;

  /// No description provided for @onboarding_nextButton.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboarding_nextButton;

  /// No description provided for @onboarding_getStartedButton.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboarding_getStartedButton;

  /// No description provided for @coachMark_counterTitle.
  ///
  /// In en, this message translates to:
  /// **'This is your counter'**
  String get coachMark_counterTitle;

  /// No description provided for @coachMark_counterBody.
  ///
  /// In en, this message translates to:
  /// **'Tap the button below to increment it.'**
  String get coachMark_counterBody;

  /// No description provided for @coachMark_fabTitle.
  ///
  /// In en, this message translates to:
  /// **'Increment'**
  String get coachMark_fabTitle;

  /// No description provided for @coachMark_fabBody.
  ///
  /// In en, this message translates to:
  /// **'Tap this button to increase the counter.'**
  String get coachMark_fabBody;

  /// No description provided for @riveDemo_title.
  ///
  /// In en, this message translates to:
  /// **'RIVE Demo'**
  String get riveDemo_title;

  /// No description provided for @riveDemo_toggleLabel.
  ///
  /// In en, this message translates to:
  /// **'Toggle animation state'**
  String get riveDemo_toggleLabel;

  /// No description provided for @riveDemo_description.
  ///
  /// In en, this message translates to:
  /// **'This toggle sends a boolean input to the RIVE state machine.'**
  String get riveDemo_description;

  /// No description provided for @riveDemo_animationLoadError.
  ///
  /// In en, this message translates to:
  /// **'Failed to load animation: {error}'**
  String riveDemo_animationLoadError(Object error);

  /// No description provided for @onboarding_skipSemanticLabel.
  ///
  /// In en, this message translates to:
  /// **'Skip onboarding'**
  String get onboarding_skipSemanticLabel;

  /// No description provided for @login_placeholderText.
  ///
  /// In en, this message translates to:
  /// **'Login screen — built per app'**
  String get login_placeholderText;

  /// No description provided for @app_title.
  ///
  /// In en, this message translates to:
  /// **'Skeleton App'**
  String get app_title;

  /// No description provided for @auth_userNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email.'**
  String get auth_userNotFound;

  /// No description provided for @auth_wrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password.'**
  String get auth_wrongPassword;

  /// No description provided for @auth_invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address.'**
  String get auth_invalidEmail;

  /// No description provided for @auth_userDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get auth_userDisabled;

  /// No description provided for @auth_emailAlreadyInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email.'**
  String get auth_emailAlreadyInUse;

  /// No description provided for @auth_weakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak.'**
  String get auth_weakPassword;

  /// No description provided for @auth_tooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again later.'**
  String get auth_tooManyRequests;

  /// No description provided for @auth_operationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'This sign-in method is not enabled.'**
  String get auth_operationNotAllowed;

  /// No description provided for @auth_invalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Invalid credentials.'**
  String get auth_invalidCredential;

  /// No description provided for @auth_genericError.
  ///
  /// In en, this message translates to:
  /// **'Authentication error: {code}'**
  String auth_genericError(String code);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'pl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pl':
      return AppLocalizationsPl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
