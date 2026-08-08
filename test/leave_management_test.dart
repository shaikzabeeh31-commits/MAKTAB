import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab_management_system/app_localizations.dart';
import 'package:maktab_management_system/leave_management_screen.dart';
import 'package:maktab_management_system/role_selection_screen.dart';
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

  group('Leave Management Unit Models Tests', () {
    test('LeaveRequest serializes to JSON and deserializes correctly', () {
      final req = LeaveRequest(
        id: 'LRQ-2024-TEST',
        teacherName: 'Sr. Fatima',
        teacherPhone: '0300-1112233',
        maktabName: 'Test Maktab',
        leaveType: 'Sick Leave',
        fromDate: '22 Jul 2024',
        toDate: '24 Jul 2024',
        totalDays: 3,
        reason: 'Fever',
        attachmentName: 'doc.pdf',
        appliedDate: 'Today',
        teacherMessage: 'Please approve',
        status: LeaveStatus.forwardedToAdmin,
        isDirectToAdmin: true,
        replacement: ReplacementTeacher(
          name: 'Sr. Maleeha',
          maktab: 'Test Maktab',
          phone: '0300-4455667',
          qualification: 'Hafiz',
          experience: '2 Years',
          fromDate: '22 Jul 2024',
          toDate: '24 Jul 2024',
          notes: 'Covering class 3',
        ),
      );

      final json = req.toJson();
      expect(json['id'], 'LRQ-2024-TEST');
      expect(json['isDirectToAdmin'], true);

      final restored = LeaveRequest.fromJson(json);
      expect(restored.id, 'LRQ-2024-TEST');
      expect(restored.teacherName, 'Sr. Fatima');
      expect(restored.status, LeaveStatus.forwardedToAdmin);
      expect(restored.replacement?.name, 'Sr. Maleeha');
    });
  });

  group('Leave Management UI Tests', () {
    testWidgets('Renders Teacher Leave Portal with tabs & history list', (tester) async {
      final ctrl = LanguageController();
      await tester.pumpWidget(_wrap(LeaveManagementScreen(
        currentRole: AppRole.teacher,
        languageController: ctrl,
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('استاد لیو پورٹل'), findsOneWidget);
      expect(find.textContaining('لیو ہسٹری'), findsOneWidget);
      expect(find.textContaining('نئی درخواست'), findsOneWidget);
    });

    testWidgets('Renders Manager Leave Portal with inbox tabs', (tester) async {
      final ctrl = LanguageController();
      await tester.pumpWidget(_wrap(LeaveManagementScreen(
        currentRole: AppRole.manager,
        languageController: ctrl,
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('مینجر ان باکس'), findsOneWidget);
      expect(find.textContaining('Pending'), findsOneWidget);
      expect(find.textContaining('Approved'), findsOneWidget);
    });

    testWidgets('Renders Admin Leave Portal with replacement button', (tester) async {
      final ctrl = LanguageController();
      await tester.pumpWidget(_wrap(LeaveManagementScreen(
        currentRole: AppRole.admin,
        languageController: ctrl,
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('مین ایڈمن ڈیش بورڈ'), findsOneWidget);
      expect(find.textContaining('ریپلیسمنٹ استاذ درج کریں'), findsAtLeastNWidgets(1));
    });
  });
}
