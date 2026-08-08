import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static TextTheme _getTextTheme(String langCode) {
    if (langCode == 'ur' || langCode == 'ar') {
      return GoogleFonts.notoNastaliqUrduTextTheme();
    }
    return GoogleFonts.interTextTheme();
  }

  static ThemeData lightTheme([String langCode = 'en']) {
    final textTheme = _getTextTheme(langCode);
    return ThemeData(
      textTheme: textTheme,
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: AppColors.surfaceLight,
      ),
      scaffoldBackgroundColor: AppColors.bgLight,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceLight,
        elevation: 1.5,
        margin: AppSpacing.cardMargin,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusMd),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: AppSpacing.radiusSm),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
    );
  }

  static ThemeData darkTheme([String langCode = 'en']) {
    final textTheme = _getTextTheme(langCode);
    return ThemeData(
      textTheme: textTheme.apply(
        bodyColor: AppColors.textPrimaryDark,
        displayColor: AppColors.textPrimaryDark,
      ),
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        primary: AppColors.primaryLight,
        secondary: AppColors.secondaryDark,
        surface: AppColors.surfaceDark,
      ),
      scaffoldBackgroundColor: AppColors.bgDark,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surfaceDark,
        elevation: 2,
        margin: AppSpacing.cardMargin,
        shape: RoundedRectangleBorder(borderRadius: AppSpacing.radiusMd),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.surfaceDark,
        foregroundColor: AppColors.textPrimaryDark,
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: AppSpacing.radiusSm),
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
    );
  }
}
