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
  /// In pl, this message translates to:
  /// **'Szkieletor Aplikacja'**
  String get homePage_title;

  /// No description provided for @homePage_centeredText.
  ///
  /// In pl, this message translates to:
  /// **'Nacisnąłeś przycisk tyle razy:'**
  String get homePage_centeredText;

  /// No description provided for @homePage_incrementButton.
  ///
  /// In pl, this message translates to:
  /// **'Zwiększ'**
  String get homePage_incrementButton;

  /// No description provided for @homePage_decrementButton.
  ///
  /// In pl, this message translates to:
  /// **'Zmniejsz'**
  String get homePage_decrementButton;

  /// No description provided for @homePage_error.
  ///
  /// In pl, this message translates to:
  /// **'Wystąpił błąd'**
  String get homePage_error;

  /// No description provided for @homePage_riveDemoButton.
  ///
  /// In pl, this message translates to:
  /// **'Demo RIVE'**
  String get homePage_riveDemoButton;

  /// No description provided for @onboarding_slide1Title.
  ///
  /// In pl, this message translates to:
  /// **'Witaj'**
  String get onboarding_slide1Title;

  /// No description provided for @onboarding_slide1Subtitle.
  ///
  /// In pl, this message translates to:
  /// **'Twoja nowa aplikacja jest gotowa. Zobaczmy co potrafi.'**
  String get onboarding_slide1Subtitle;

  /// No description provided for @onboarding_slide2Title.
  ///
  /// In pl, this message translates to:
  /// **'Odkryj funkcje'**
  String get onboarding_slide2Title;

  /// No description provided for @onboarding_slide2Subtitle.
  ///
  /// In pl, this message translates to:
  /// **'Wszystko czego potrzebujesz, zbudowane z czystą architekturą.'**
  String get onboarding_slide2Subtitle;

  /// No description provided for @onboarding_slide3Title.
  ///
  /// In pl, this message translates to:
  /// **'Zaczynamy'**
  String get onboarding_slide3Title;

  /// No description provided for @onboarding_slide3Subtitle.
  ///
  /// In pl, this message translates to:
  /// **'Wszystko gotowe. Zanurz się i dostosuj do siebie.'**
  String get onboarding_slide3Subtitle;

  /// No description provided for @onboarding_skipButton.
  ///
  /// In pl, this message translates to:
  /// **'Pomiń'**
  String get onboarding_skipButton;

  /// No description provided for @onboarding_nextButton.
  ///
  /// In pl, this message translates to:
  /// **'Dalej'**
  String get onboarding_nextButton;

  /// No description provided for @onboarding_getStartedButton.
  ///
  /// In pl, this message translates to:
  /// **'Zaczynamy'**
  String get onboarding_getStartedButton;

  /// No description provided for @coachMark_counterTitle.
  ///
  /// In pl, this message translates to:
  /// **'To jest Twój licznik'**
  String get coachMark_counterTitle;

  /// No description provided for @coachMark_counterBody.
  ///
  /// In pl, this message translates to:
  /// **'Naciśnij przycisk poniżej, aby go zwiększyć.'**
  String get coachMark_counterBody;

  /// No description provided for @coachMark_fabTitle.
  ///
  /// In pl, this message translates to:
  /// **'Zwiększ'**
  String get coachMark_fabTitle;

  /// No description provided for @coachMark_fabBody.
  ///
  /// In pl, this message translates to:
  /// **'Naciśnij ten przycisk, aby zwiększyć licznik.'**
  String get coachMark_fabBody;

  /// No description provided for @riveDemo_title.
  ///
  /// In pl, this message translates to:
  /// **'Demo RIVE'**
  String get riveDemo_title;

  /// No description provided for @riveDemo_toggleLabel.
  ///
  /// In pl, this message translates to:
  /// **'Przełącz stan animacji'**
  String get riveDemo_toggleLabel;

  /// No description provided for @riveDemo_description.
  ///
  /// In pl, this message translates to:
  /// **'Ten przełącznik wysyła wartość logiczną do maszyny stanów RIVE.'**
  String get riveDemo_description;
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
