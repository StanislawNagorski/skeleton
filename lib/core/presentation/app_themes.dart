import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract class AppThemes {
  static final light = ThemeData.light().copyWith(
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
  );
}
