// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Polish (`pl`).
class AppLocalizationsPl extends AppLocalizations {
  AppLocalizationsPl([String locale = 'pl']) : super(locale);

  @override
  String get homePage_title => 'Szkieletor Aplikacja';

  @override
  String get homePage_centeredText => 'Nacisnąłeś przycisk tyle razy:';

  @override
  String get homePage_incrementButton => 'Zwiększ';

  @override
  String get homePage_decrementButton => 'Zmniejsz';

  @override
  String get homePage_error => 'Wystąpił błąd';

  @override
  String get homePage_riveDemoButton => 'Demo RIVE';

  @override
  String get onboarding_slide1Title => 'Witaj';

  @override
  String get onboarding_slide1Subtitle =>
      'Twoja nowa aplikacja jest gotowa. Zobaczmy co potrafi.';

  @override
  String get onboarding_slide2Title => 'Odkryj funkcje';

  @override
  String get onboarding_slide2Subtitle =>
      'Wszystko czego potrzebujesz, zbudowane z czystą architekturą.';

  @override
  String get onboarding_slide3Title => 'Zaczynamy';

  @override
  String get onboarding_slide3Subtitle =>
      'Wszystko gotowe. Zanurz się i dostosuj do siebie.';

  @override
  String get onboarding_skipButton => 'Pomiń';

  @override
  String get onboarding_nextButton => 'Dalej';

  @override
  String get onboarding_getStartedButton => 'Zaczynamy';

  @override
  String get coachMark_counterTitle => 'To jest Twój licznik';

  @override
  String get coachMark_counterBody =>
      'Naciśnij przycisk poniżej, aby go zwiększyć.';

  @override
  String get coachMark_fabTitle => 'Zwiększ';

  @override
  String get coachMark_fabBody =>
      'Naciśnij ten przycisk, aby zwiększyć licznik.';

  @override
  String get riveDemo_title => 'Demo RIVE';

  @override
  String get riveDemo_toggleLabel => 'Przełącz stan animacji';

  @override
  String get riveDemo_description =>
      'Ten przełącznik wysyła wartość logiczną do maszyny stanów RIVE.';
}
