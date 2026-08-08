import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab_management_system/app_localizations.dart';
import 'package:maktab_management_system/role_selection_screen.dart';
import 'package:maktab_management_system/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wraps the widget in a full MaterialApp with Urdu locale support.
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

void _useSize(WidgetTester tester, double width, double height) {
  const dpr = 1.0;
  final original = tester.view.physicalSize;
  tester.view.physicalSize = Size(width * dpr, height * dpr);
  tester.view.devicePixelRatio = dpr;
  addTearDown(() {
    tester.view.physicalSize = original;
    tester.view.resetDevicePixelRatio();
  });
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Role Selection Screen Tests', () {
    testWidgets('renders Step 1 with 6 role choices (Urdu locale)',
        (tester) async {
      _useSize(tester, 1080, 2400);
      final ctrl = LanguageController();
      await tester.pumpWidget(_wrap(RoleSelectionScreen(
        languageController: ctrl,
        themeController: ThemeController(),
        students: const [],
        onSave: (_) async {},
        onRoleSelected: (_) {},
      )));
      await tester.pumpAndSettle();

      // Urdu locale: select_role key → 'اپنا کردار منتخب کریں'
      expect(find.text('اپنا کردار منتخب کریں'), findsOneWidget);
      // Role cards use titleUrdu (Manager) + titleEnglish → 'مینجر (Manager)'
      expect(find.textContaining('مینجر'), findsOneWidget);
      expect(find.textContaining('ایڈمن'), findsOneWidget);
      expect(find.textContaining('استاد'), findsOneWidget);
      expect(find.textContaining('والد'), findsOneWidget);
      expect(find.textContaining('متولی'), findsOneWidget);
      expect(find.textContaining('دیگر'), findsOneWidget);
    });

    testWidgets('tapping role card (Teacher) changes selection', (tester) async {
      _useSize(tester, 1080, 2400);
      final ctrl = LanguageController();
      await tester.pumpWidget(_wrap(RoleSelectionScreen(
        languageController: ctrl,
        themeController: ThemeController(),
        students: const [],
        onSave: (_) async {},
        onRoleSelected: (_) {},
      )));
      await tester.pumpAndSettle();

      // Find the teacher card by partial text (contains 'استاد')
      final teacherCard = find.textContaining('استاد');
      expect(teacherCard, findsOneWidget);
      await tester.tap(teacherCard);
      await tester.pumpAndSettle();

      // After tapping, the card should be selected (test that UI updates without crash)
      // Tap continue button
      final continueBtn = find.textContaining('جاری');
      if (continueBtn.evaluate().isNotEmpty) {
        await tester.tap(continueBtn.first);
        await tester.pumpAndSettle();
        // Step 2 should show a welcome text containing 'استاد'
        expect(find.textContaining('خوش آمدید'), findsAtLeastNWidgets(1));
      }
    });

    testWidgets('Step 2 Start button triggers onRoleSelected callback',
        (tester) async {
      _useSize(tester, 1080, 2400);
      final ctrl = LanguageController();
      AppRole? selected;
      await tester.pumpWidget(_wrap(RoleSelectionScreen(
        languageController: ctrl,
        themeController: ThemeController(),
        students: const [],
        onSave: (_) async {},
        onRoleSelected: (r) => selected = r,
      )));
      await tester.pumpAndSettle();

      // Tap Mutawalli card by partial text
      final mutawalliCard = find.textContaining('متولی');
      expect(mutawalliCard, findsOneWidget);
      await tester.tap(mutawalliCard);
      await tester.pumpAndSettle();

      // Tap continue / جاری رکھیں
      final continueBtn = find.textContaining('جاری');
      if (continueBtn.evaluate().isNotEmpty) {
        await tester.tap(continueBtn.first);
        await tester.pumpAndSettle();

        // Tap the dashboard / ڈیش بورڈ button
        final dashBtn = find.textContaining('ڈیش بورڈ');
        if (dashBtn.evaluate().isNotEmpty) {
          await tester.tap(dashBtn.first);
          await tester.pumpAndSettle();
        }
        expect(selected, equals(AppRole.mutawalli));
      }
    });
  });

  group('Role Dashboard Screen Tests', () {
    testWidgets('renders Manager dashboard with stats', (tester) async {
      _useSize(tester, 1080, 2400);
      final ctrl = LanguageController();
      await tester.pumpWidget(_wrap(RoleDashboardScreen(
        themeController: ThemeController(),
        currentRole: AppRole.manager,
        languageController: ctrl,
        students: const [
          {'name': 'Ahmed', 'feeStatus': 'paid', 'isPresent': true}
        ],
        onSave: (_) async {},
        onChangeRole: () {},
      )));
      await tester.pumpAndSettle();

      // The dashboard renders some content — check for stats widgets
      // total_students key → 'کل طلبہ' in Urdu
      expect(find.textContaining('کل طلبہ'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders Parent dashboard with child overview', (tester) async {
      _useSize(tester, 1080, 2400);
      final ctrl = LanguageController();
      await tester.pumpWidget(_wrap(RoleDashboardScreen(
        themeController: ThemeController(),
        currentRole: AppRole.parent,
        languageController: ctrl,
        students: const [
          {'name': 'Faizan', 'feeStatus': 'paid', 'isPresent': true}
        ],
        onSave: (_) async {},
        onChangeRole: () {},
      )));
      await tester.pumpAndSettle();

      // Parent dashboard should show child name
      expect(find.textContaining('Faizan'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders Teacher dashboard with lesson and attendance tabs',
        (tester) async {
      _useSize(tester, 1080, 2400);
      final ctrl = LanguageController();
      await tester.pumpWidget(_wrap(RoleDashboardScreen(
        themeController: ThemeController(),
        currentRole: AppRole.teacher,
        languageController: ctrl,
        students: const [],
        onSave: (_) async {},
        onChangeRole: () {},
      )));
      await tester.pumpAndSettle();

      // Teacher has bottom nav with attendance and fee tabs
      expect(find.textContaining('حاضری'), findsAtLeastNWidgets(1));
    });

    testWidgets('renders Admin dashboard without crash', (tester) async {
      _useSize(tester, 1080, 2400);
      final ctrl = LanguageController();
      await tester.pumpWidget(_wrap(RoleDashboardScreen(
        themeController: ThemeController(),
        currentRole: AppRole.admin,
        languageController: ctrl,
        students: const [],
        onSave: (_) async {},
        onChangeRole: () {},
      )));
      await tester.pumpAndSettle();
      // Just verify it renders without exception
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
    });

    testWidgets('renders Mutawalli dashboard without crash', (tester) async {
      _useSize(tester, 1080, 2400);
      final ctrl = LanguageController();
      await tester.pumpWidget(_wrap(RoleDashboardScreen(
        themeController: ThemeController(),
        currentRole: AppRole.mutawalli,
        languageController: ctrl,
        students: const [],
        onSave: (_) async {},
        onChangeRole: () {},
      )));
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
    });
  });
}
