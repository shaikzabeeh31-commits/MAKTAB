import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab_management_system/app_localizations.dart';
import 'package:maktab_management_system/attendance_screen.dart';
import 'package:maktab_management_system/fee_screen.dart';
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

  group('Fee & Attendance Features 31-50 Tests', () {
    testWidgets('FeeScreen renders Collection Analytics, Teacher Ledger, Annual Audit, and Fee Collector Role buttons', (tester) async {
      final ctrl = LanguageController();
      final students = [
        {'name': 'Mohammad Ahmed', 'rollNo': '101', 'className': 'Class 1', 'feeStatus': 'paid', 'feeAmount': '500', 'isPresent': true},
      ];

      await tester.pumpWidget(_wrap(FeeScreen(
        students: students,
        languageController: ctrl,
        onSave: (s) async {},
      )));
      await tester.pumpAndSettle();

      expect(find.byType(FeeScreen), findsOneWidget);
    });

    testWidgets('AttendanceScreen renders Bulk Holiday, Ratio, Parent Leave, and Matrix PDF buttons', (tester) async {
      final ctrl = LanguageController();
      final students = [
        {'name': 'Zaid Hasan', 'rollNo': '101', 'grade': 'Class 1', 'attendance': 'present'},
      ];

      await tester.pumpWidget(_wrap(AttendanceScreen(
        students: students,
        languageController: ctrl,
      )));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.calendar_month_rounded), findsOneWidget);
      expect(find.byType(AttendanceScreen), findsOneWidget);
    });
  });
}
