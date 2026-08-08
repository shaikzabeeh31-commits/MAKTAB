import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab_management_system/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<String> targetLangs = [
    'ur', // Urdu
    'en', // English
    'ar', // Arabic
    'hi', // Hindi
    'te', // Telugu
    'kn', // Kannada
    'ta', // Tamil
    'ml', // Malayalam
  ];

  final List<String> requiredKeys = [
    'app_title',
    'students_list',
    'add_student',
    'edit_student',
    'search_hint',
    'name',
    'roll_no',
    'father_name',
    'phone_number',
    'class_grade',
    'shift',
    'save',
    'cancel',
    'fee_record',
    'fee_amount',
    'fee_status',
    'due',
    'partially_paid',
    'paid',
    'attendance',
    'present',
    'absent',
    'leave',
    'sabaq_lessons',
    'select_language',
    'no_students_found',
    'select_role',
    'welcome',
    'continue_btn',
    'login',
    'new_admission',
    'old_admission',
    'batch_group',
    'advanced_dashboard',
    'staff_logins',
    'parent_logins',
    'create_group',
    'attendance_ledger',
    'lesson_plan',
  ];

  group('Multi-Language Translations Verification Tests (8 Languages)', () {
    for (final langCode in targetLangs) {
      test('Language [$langCode] translates all required keys correctly', () {
        final loc = AppLocalizations(Locale(langCode));

        for (final key in requiredKeys) {
          final translated = loc.translate(key);
          expect(translated, isNotNull);
          expect(translated, isNotEmpty,
              reason: 'Key "$key" should have non-empty translation for language "$langCode"');
        }
      });
    }

    test('LanguageController updates locale and notifies listeners', () async {
      final ctrl = LanguageController();
      expect(ctrl.locale.languageCode, isNotNull);

      await ctrl.setLanguage('ar');
      expect(ctrl.locale.languageCode, 'ar');

      await ctrl.setLanguage('te');
      expect(ctrl.locale.languageCode, 'te');

      await ctrl.setLanguage('kn');
      expect(ctrl.locale.languageCode, 'kn');

      await ctrl.setLanguage('ta');
      expect(ctrl.locale.languageCode, 'ta');

      await ctrl.setLanguage('ml');
      expect(ctrl.locale.languageCode, 'ml');

      await ctrl.setLanguage('ur');
      expect(ctrl.locale.languageCode, 'ur');
    });

    test('kAllLanguages list has all 8 target languages with flags', () {
      expect(kAllLanguages.length, 8);
      final codes = kAllLanguages.map((l) => l.code).toList();
      expect(codes, containsAll(targetLangs));
    });
  });
}
