import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maktab_management_system/app_localizations.dart';
import 'package:maktab_management_system/attendance_screen.dart';

import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:maktab_management_system/role_selection_screen.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('AttendanceScreen renders student list and toggles attendance status', (WidgetTester tester) async {
    final languageController = LanguageController();
    final sampleStudents = [
      {
        'name': 'احمد علی',
        'rollNo': '101',
        'grade': 'Class 1',
        'attendance': 'present',
      },
    ];

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ur'),
        localizationsDelegates: const [
          AppLocalizationsDelegate(),
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [Locale('ur'), Locale('en')],
        home: AttendanceScreen(
          students: sampleStudents,
          languageController: languageController,
          currentRole: AppRole.teacher,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify student name and details
    expect(find.textContaining('احمد علی'), findsOneWidget);
    expect(find.textContaining('101'), findsOneWidget);

    // Tap attendance button (currently present/حاضر)
    final attendanceBtn = find.text('حاضر');
    expect(attendanceBtn, findsOneWidget);
    await tester.tap(attendanceBtn);
    await tester.pumpAndSettle();
    expect(find.text('غیر حاضر'), findsOneWidget);
  });
}
