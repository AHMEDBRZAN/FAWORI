import 'package:flutter/material.dart';

class AppColors {
  static const Color orange = Color(0xFFE8A33D);
  static const Color teal = Color(0xFF3EC6C0);
  static const Color red = Color(0xFFE5484D);
  static const Color darkBg = Color(0xFF141419);
  static const Color darkCard = Color(0xFF1B1B21);
  static const Color lightBg = Color(0xFFEDEFF3);
  static const Color lightCard = Color(0xFFFAFBFC);
  static const Color ink = Color(0xFF23405C);
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
        dividerColor: const Color(0xFF2A2A33),
        cardColor: AppColors.darkCard,
      );

  static ThemeData light() => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.lightBg,
        colorScheme: const ColorScheme.light(
          primary: AppColors.orange,
          secondary: AppColors.teal,
          surface: AppColors.lightCard,
          onSurface: AppColors.ink,
        ),
        dividerColor: const Color(0xFFDDE1E8),
        cardColor: AppColors.lightCard,
      );

  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2A2A33)
          : const Color(0xFFDDE1E8);

  static Color text(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
          ? Colors.white
          : AppColors.ink;
}
