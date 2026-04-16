import 'package:flutter/material.dart';
import 'package:skeleton/core/localization/app_localizations.dart';

extension ContextExtension on BuildContext {
  AppLocalizations get localizations => AppLocalizations.of(this)!;
  ThemeData get theme => Theme.of(this);
}
