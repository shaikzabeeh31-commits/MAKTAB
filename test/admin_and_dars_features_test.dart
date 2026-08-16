import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab_management_system/admin_features_screen.dart';
import 'package:maktab_management_system/app_localizations.dart';
import 'package:maktab_management_system/db_backup_service.dart';
import 'package:maktab_management_system/lesson_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('ur')}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
    ],
    supportedLocales: const [Locale('ur'), Locale('en')],
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Admin Features & DB Import/Export Tests', () {
    testWidgets('DbBackupService exports and imports .db json correctly', (tester) async {
      final exported = await DbBackupService.exportDatabaseJson();
      expect(exported, contains('maktab_management_system.db'));
      expect(exported, contains('students'));

      final success = await DbBackupService.importDatabaseJson(exported);
      expect(success, isTrue);
    });

    testWidgets('AdminFeaturesScreen renders Executive Summary and DB Import/Export buttons', (tester) async {
      final ctrl = LanguageController();
      final students = [
        {'name': 'Mohammad Ahmed', 'rollNo': '101', 'className': 'Class 1', 'feeStatus': 'paid', 'feeAmount': '500', 'isPresent': true},
      ];

      await tester.pumpWidget(_wrap(AdminFeaturesScreen(
        languageController: ctrl,
        students: students,
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('ایڈوانسڈ ڈیش بورڈ'), findsAtLeastNWidgets(1));
      expect(find.textContaining('شناختی کارڈ'), findsOneWidget);
      expect(find.textContaining('ترقیِ درجہ'), findsOneWidget);
      expect(find.textContaining('سندِ فراغت'), findsOneWidget);
      expect(find.byIcon(Icons.storage_rounded), findsOneWidget);
    });

    testWidgets('LessonScreen renders Sabq and audio/recording controls', (tester) async {
      final ctrl = LanguageController();
      await tester.pumpWidget(_wrap(LessonScreen(
        languageController: ctrl,
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('پارہ'), findsAtLeastNWidgets(1));
      expect(find.byIcon(Icons.mic_rounded), findsAtLeastNWidgets(1));
    });
  });
}
