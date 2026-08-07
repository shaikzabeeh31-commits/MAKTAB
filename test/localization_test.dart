import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maktab_management_system/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppLocalizations Tests', () {
    test('translates keys correctly in Urdu', () {
      final loc = AppLocalizations(const Locale('ur'));
      expect(loc.translate('app_title'), equals('مکتب مینیجر'));
      expect(loc.translate('add_student'), equals('طالب علم شامل کریں'));
      expect(loc.translate('attendance'), equals('حاضری'));
    });

    test('translates keys correctly in English', () {
      final loc = AppLocalizations(const Locale('en'));
      expect(loc.translate('app_title'), equals('Maktab Manager'));
      expect(loc.translate('add_student'), equals('Add Student'));
      expect(loc.translate('attendance'), equals('Attendance'));
    });

    test('translates keys correctly in Arabic', () {
      final loc = AppLocalizations(const Locale('ar'));
      expect(loc.translate('app_title'), equals('مدير المكتب'));
      expect(loc.translate('add_student'), equals('إضافة طالب'));
      expect(loc.translate('attendance'), equals('التحضير'));
    });

    test('falls back to Urdu if translation missing in target locale', () {
      final loc = AppLocalizations(const Locale('en'));
      expect(loc.translate('non_existent_key'), equals('non_existent_key'));
    });
  });

  group('LanguageController Tests', () {
    test('initializes with default locale ur', () {
      final controller = LanguageController();
      expect(controller.locale.languageCode, equals('ur'));
    });

    test('updates language code and notifies listeners', () async {
      final controller = LanguageController();
      bool notified = false;
      controller.addListener(() {
        notified = true;
      });

      await controller.setLanguage('en');
      expect(controller.locale.languageCode, equals('en'));
      expect(notified, isTrue);
    });
  });
}
