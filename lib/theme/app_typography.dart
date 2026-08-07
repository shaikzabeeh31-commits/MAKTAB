import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTypography {
  static const TextStyle appTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.15,
  );

  static const TextStyle screenHeading = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const TextStyle sectionHeading = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.bold,
    color: AppColors.secondary,
  );

  static const TextStyle studentName = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.normal,
  );

  static const TextStyle captionText = TextStyle(
    fontSize: 11,
    color: Colors.grey,
  );

  static const TextStyle amountText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );
}
