import 'package:flutter/material.dart';

class AppColors {
  static const Color orange = Color(0xFFE8A33D);
  static const Color teal   = Color(0xFF3EC6C0);
  static const Color red    = Color(0xFFE5484D);
  static const Color darkBg   = Color(0xFF141419);
  static const Color darkCard = Color(0xFF1B1B21);
}

class AppTheme {
  static ThemeData dark() => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkBg,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.orange,
          secondary: AppColors.teal,
          surface: AppColors.darkCard,
        ),
      );

  static ThemeData light() => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: const Color(0xFFF6F6F8),
        colorScheme: const ColorScheme.light(
          primary: AppColors.orange,
          secondary: AppColors.teal,
          surface: Colors.white,
        ),
      );
}
