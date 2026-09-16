import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  static const TextStyle appTitle = TextStyle(
    fontFamily: 'MehrNastaliq',
    fontSize: 18,
    fontWeight: FontWeight.bold,
    height: 1.35,
    letterSpacing: 0.15,
  );

  static const TextStyle screenHeading = TextStyle(
    fontFamily: 'MehrNastaliq',
    fontSize: 16,
    fontWeight: FontWeight.bold,
    height: 1.35,
    color: AppColors.primary,
  );

  static const TextStyle sectionHeading = TextStyle(
    fontFamily: 'MehrNastaliq',
    fontSize: 14,
    fontWeight: FontWeight.bold,
    height: 1.35,
    color: AppColors.secondary,
  );

  static const TextStyle studentName = TextStyle(
    fontFamily: 'MehrNastaliq',
    fontSize: 13,
    fontWeight: FontWeight.bold,
    height: 1.3,
  );

  static const TextStyle bodyText = TextStyle(
    fontFamily: 'MehrNastaliq',
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.3,
  );

  static const TextStyle captionText = TextStyle(
    fontFamily: 'MehrNastaliq',
    fontSize: 10.5,
    color: Colors.grey,
    height: 1.25,
  );

  static const TextStyle amountText = TextStyle(
    fontFamily: 'MehrNastaliq',
    fontSize: 15,
    fontWeight: FontWeight.bold,
    height: 1.3,
    color: AppColors.primary,
  );
}
