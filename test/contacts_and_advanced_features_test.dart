import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab_management_system/app_localizations.dart';
import 'package:maktab_management_system/fee_screen.dart';
import 'package:maktab_management_system/pdf_service.dart';

void main() {
  group('Contacts & Advanced Features Unit Tests', () {
    test('kFeeMonths contains all 12 month labels', () {
      expect(kFeeMonths.length, equals(12));
      expect(kFeeMonths.first, equals('January'));
      expect(kFeeMonths.last, equals('December'));
    });

    test('All 8 target languages are defined in kAllLanguages', () {
      expect(kAllLanguages.length, equals(8));
      final codes = kAllLanguages.map((l) => l.code).toList();
      expect(codes, containsAll(['ur', 'en', 'ar', 'hi', 'te', 'kn', 'ta', 'ml']));
    });

    test('AppLocalizations translates key contact and student labels correctly', () {
      final locUr = AppLocalizations(const Locale('ur'));
      expect(locUr.translate('student_name'), equals('طالب علم کا نام'));

      final locEn = AppLocalizations(const Locale('en'));
      expect(locEn.translate('student_name'), equals('Student Name'));
    });
  });
}
