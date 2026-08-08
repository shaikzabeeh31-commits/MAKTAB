import 'package:flutter/material.dart';
import 'dart:io' as std_io;
import 'app_colors.dart';
import 'app_spacing.dart';

import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static TextTheme _getTextTheme(String langCode) {
    try {
      if (std_io.Platform.environment.containsKey('FLUTTER_TEST')) {
        return const TextTheme();
      }
    } catch (_) {}
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
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        secondary: AppColors.secondary,
        onSecondary: Colors.white,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryLight,
        onPrimary: Color(0xFF0F172A),
        secondary: AppColors.secondaryDark,
        onSecondary: Colors.white,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
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
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceDark.withValues(alpha: 0.5),
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        enabledBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors.borderDark),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: AppColors.primaryLight, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
      ),
    );
  }
}
