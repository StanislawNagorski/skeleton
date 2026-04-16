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
  String get homePage_decrementButton => 'Zmniejsz';

  @override
  String get homePage_error => 'Wystąpił błąd';
}
