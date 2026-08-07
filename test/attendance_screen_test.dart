import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maktab_management_system/app_localizations.dart';
import 'package:maktab_management_system/attendance_screen.dart';

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
        home: AttendanceScreen(
          students: sampleStudents,
          languageController: languageController,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify student name and details
    expect(find.text('احمد علی'), findsOneWidget);
    expect(find.textContaining('101'), findsOneWidget);

    // Tap Absent chip
    final absentChip = find.text('غائب');
    expect(absentChip, findsOneWidget);
    await tester.tap(absentChip);
    await tester.pumpAndSettle();
  });
}
