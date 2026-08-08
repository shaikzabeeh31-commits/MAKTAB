import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab_management_system/app_localizations.dart';
import 'package:maktab_management_system/attendance_screen.dart';
import 'package:maktab_management_system/role_selection_screen.dart';
import 'package:maktab_management_system/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  group('New Features & Attendance Checklist Tests', () {
    testWidgets('AttendanceScreen renders Cap, Uniform, and Books checkboxes', (tester) async {
      final ctrl = LanguageController();
      final students = [
        {'name': 'Zaid Hasan', 'rollNo': '101', 'grade': 'Class 1', 'attendance': 'present'},
      ];

      await tester.pumpWidget(_wrap(AttendanceScreen(
        students: students,
        languageController: ctrl,
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('Zaid Hasan'), findsOneWidget);
      expect(find.textContaining('ٹوپی'), findsOneWidget);
      expect(find.textContaining('لباس'), findsOneWidget);
      expect(find.textContaining('کتاب'), findsOneWidget);
    });

    testWidgets('RoleDashboardScreen renders Mutawalli dashboard with access controls', (tester) async {
      final ctrl = LanguageController();
      await tester.pumpWidget(_wrap(RoleDashboardScreen(
        themeController: ThemeController(),
        currentRole: AppRole.mutawalli,
        languageController: ctrl,
        students: const [
          {'name': 'Mohammad Ahmed', 'feeStatus': 'paid', 'feeAmount': '500'},
        ],
        onSave: (s
      ) async {},
        onChangeRole: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('متولی'), findsAtLeastNWidgets(1));
      expect(find.textContaining('Access Controls'), findsOneWidget);
      expect(find.textContaining('مجموعی فیس وصولی'), findsOneWidget);
    });
  });
}
