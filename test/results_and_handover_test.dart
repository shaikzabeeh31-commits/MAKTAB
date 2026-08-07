import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab_management_system/app_localizations.dart';
import 'package:maktab_management_system/community_chat_screen.dart';
import 'package:maktab_management_system/results_screen.dart';
import 'package:maktab_management_system/role_selection_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Student Results Grade Calculations Tests', () {
    test('Calculates grades and percentages correctly', () {
      final r1 = StudentResult(
        rollNo: '1',
        name: 'Abdullah',
        fatherName: 'Tariq',
        className: 'Class 7',
        quranScore: 95,
        tajweedScore: 95,
        diniyatScore: 95,
        arabicScore: 95,
      );

      expect(r1.totalMarks, 380);
      expect(r1.percentage, 95.0);
      expect(r1.grade, contains('Mumtaz'));

      final r2 = StudentResult(
        rollNo: '2',
        name: 'Zaid',
        fatherName: 'Ali',
        className: 'Class 7',
        quranScore: 30,
        tajweedScore: 30,
        diniyatScore: 30,
        arabicScore: 30,
      );

      expect(r2.percentage, 30.0);
      expect(r2.grade, contains('Rasib'));
    });
  });

  group('Fee Handover Record Serialization Tests', () {
    test('FeeHandoverRecord serializes and deserializes correctly', () {
      final fh = FeeHandoverRecord(
        id: 'fh_001',
        teacherName: 'Sr. Fatima',
        studentName: 'Muhammad Abdullah',
        amount: '500',
        paymentMode: 'Cash',
        date: 'Today',
        isAcknowledged: true,
      );

      final json = fh.toJson();
      expect(json['amount'], '500');
      expect(json['isAcknowledged'], true);

      final restored = FeeHandoverRecord.fromJson(json);
      expect(restored.teacherName, 'Sr. Fatima');
      expect(restored.studentName, 'Muhammad Abdullah');
      expect(restored.isAcknowledged, true);
    });
  });

  group('Results & Permissions UI Widget Tests', () {
    testWidgets('Renders ResultsScreen with stats and student cards', (tester) async {
      final ctrl = LanguageController();
      await tester.pumpWidget(_wrap(ResultsScreen(languageController: ctrl)));
      await tester.pumpAndSettle();

      expect(find.textContaining('Academic Results'), findsOneWidget);
      expect(find.textContaining('Muhammad Abdullah'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Mumtaz'), findsAtLeastNWidgets(1));
    });

    testWidgets('Renders Teacher Role Dashboard with Fees & Attendance access', (tester) async {
      final ctrl = LanguageController();
      await tester.pumpWidget(_wrap(RoleDashboardScreen(
        currentRole: AppRole.teacher,
        languageController: ctrl,
        students: const [],
        onSave: (s) async {},
        onChangeRole: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('فیس پورٹل'), findsAtLeastNWidgets(1));
      expect(find.textContaining('حاضری'), findsAtLeastNWidgets(1));
    });
  });
}
