import 'package:flutter/material.dart';
import 'package:skeleton/core/presentation/app_colors.dart';

abstract class AppThemes {
  static final ThemeData light = ThemeData.light().copyWith(
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
  );
}
