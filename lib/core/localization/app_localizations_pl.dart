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
}
