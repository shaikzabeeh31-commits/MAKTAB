import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as std_io;
import 'app_colors.dart';
import 'app_spacing.dart';

import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static TextTheme _getTextTheme(String langCode) {
    try {
      if (!kIsWeb &&
    std_io.Platform.environment.containsKey('FLUTTER_TEST')) {
        return const TextTheme();
      }
    } catch (_) {}
    if (langCode == 'ur' || langCode == 'ar') {
      const baseTheme = TextTheme(
        displayLarge: TextStyle(fontFamily: 'MehrNastaliq', fontSize: 24, height: 1.45),
        displayMedium: TextStyle(fontFamily: 'MehrNastaliq', fontSize: 21, height: 1.45),
        displaySmall: TextStyle(fontFamily: 'MehrNastaliq', fontSize: 18, height: 1.4),
        headlineLarge: TextStyle(fontFamily: 'MehrNastaliq', fontSize: 17, height: 1.4, fontWeight: FontWeight.bold),
        headlineMedium: TextStyle(fontFamily: 'MehrNastaliq', fontSize: 15, height: 1.35, fontWeight: FontWeight.bold),
        headlineSmall: TextStyle(fontFamily: 'MehrNastaliq', fontSize: 14, height: 1.35, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontFamily: 'MehrNastaliq', fontSize: 14, height: 1.35, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontFamily: 'MehrNastaliq', fontSize: 13, height: 1.35, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontFamily: 'MehrNastaliq', fontSize: 12, height: 1.3, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontFamily: 'MehrNastaliq', fontSize: 13, height: 1.35),
        bodyMedium: TextStyle(fontFamily: 'MehrNastaliq', fontSize: 12, height: 1.3),
        bodySmall: TextStyle(fontFamily: 'MehrNastaliq', fontSize: 10.5, height: 1.25),
        labelLarge: TextStyle(fontFamily: 'MehrNastaliq', fontSize: 12, height: 1.3, fontWeight: FontWeight.bold),
        labelMedium: TextStyle(fontFamily: 'MehrNastaliq', fontSize: 10.5, height: 1.25),
        labelSmall: TextStyle(fontFamily: 'MehrNastaliq', fontSize: 9.5, height: 1.2),
      );
      return GoogleFonts.notoNastaliqUrduTextTheme(baseTheme);
    }
    return GoogleFonts.interTextTheme();
  }

  static ThemeData lightTheme([String langCode = 'en']) {
    final textTheme = _getTextTheme(langCode);
    final isUrduOrArabic = langCode == 'ur' || langCode == 'ar';
    bool isTest = false;
    try {
      if (!kIsWeb && std_io.Platform.environment.containsKey('FLUTTER_TEST')) {
        isTest = true;
      }
    } catch (_) {}
    final String? fontFamily = (isUrduOrArabic && !isTest)
        ? 'MehrNastaliq'
        : null;
    return ThemeData(
      fontFamily: fontFamily,
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
    final isUrduOrArabic = langCode == 'ur' || langCode == 'ar';
    bool isTest = false;
    try {
      if (!kIsWeb && std_io.Platform.environment.containsKey('FLUTTER_TEST')) {
        isTest = true;
      }
    } catch (_) {}
    final String? fontFamily = (isUrduOrArabic && !isTest)
        ? 'MehrNastaliq'
        : null;
    return ThemeData(
      fontFamily: fontFamily,
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
