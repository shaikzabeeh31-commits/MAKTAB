import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab_management_system/app_localizations.dart';
import 'package:maktab_management_system/role_selection_screen.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    localizationsDelegates: const [
      AppLocalizationsDelegate(),
      GlobalMaterialLocalizations.delegate,
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
  group('Role Selection Screen Tests', () {
    testWidgets('renders Step 1 with 6 role choices', (tester) async {
      _useSize(tester, 1080, 2400);
      final ctrl = LanguageController();
      await tester.pumpWidget(_wrap(RoleSelectionScreen(
        languageController: ctrl,
        students: const [],
        onSave: (_) async {},
        onRoleSelected: (_) {},
      )));
      await tester.pumpAndSettle();

      expect(find.text('کردار منتخب کریں'), findsOneWidget);
      expect(find.text('اپنا کردار منتخب کریں'), findsOneWidget);
      expect(find.text('مینجر'), findsOneWidget);
      expect(find.text('ایڈمن'), findsOneWidget);
      expect(find.text('استاد'), findsOneWidget);
      expect(find.text('والد/مدر'), findsOneWidget);
      expect(find.text('متولی'), findsOneWidget);
      expect(find.text('دیگر'), findsOneWidget);
    });

    testWidgets('tapping role card changes active selection', (tester) async {
      _useSize(tester, 1080, 2400);
      final ctrl = LanguageController();
      await tester.pumpWidget(_wrap(RoleSelectionScreen(
        languageController: ctrl,
        students: const [],
        onSave: (_) async {},
        onRoleSelected: (_) {},
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('استاد'));
      await tester.pumpAndSettle();

      // Tap continue button to go to Step 2
      await tester.tap(find.text('جاری رکھیں'));
      await tester.pumpAndSettle();

      expect(find.text('خوش آمدید'), findsOneWidget);
      expect(find.text('خوش آمدید استاد صاحب!'), findsOneWidget);
    });

    testWidgets('Step 2 Start button triggers onRoleSelected callback',
        (tester) async {
      _useSize(tester, 1080, 2400);
      final ctrl = LanguageController();
      AppRole? selected;
      await tester.pumpWidget(_wrap(RoleSelectionScreen(
        languageController: ctrl,
        students: const [],
        onSave: (_) async {},
        onRoleSelected: (r) => selected = r,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('متولی'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('جاری رکھیں'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('ڈیش بورڈ پر جائیں'));
      await tester.pumpAndSettle();

      expect(selected, equals(AppRole.mutawalli));
    });
  });

  group('Role Dashboard Screen Tests', () {
    testWidgets('renders Manager dashboard with stats & quick actions',
        (tester) async {
      final ctrl = LanguageController();
      await tester.pumpWidget(_wrap(RoleDashboardScreen(
        currentRole: AppRole.manager,
        languageController: ctrl,
        students: const [
          {'name': 'Ahmed', 'feeStatus': 'paid', 'isPresent': true}
        ],
        onSave: (_) async {},
        onChangeRole: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('مینجر ڈیش بورڈ'), findsOneWidget);
      expect(find.text('کل طلبہ'), findsOneWidget);
      expect(find.text('حاضری درج کریں'), findsOneWidget);
    });

    testWidgets('renders Parent dashboard with child overview',
        (tester) async {
      final ctrl = LanguageController();
      await tester.pumpWidget(_wrap(RoleDashboardScreen(
        currentRole: AppRole.parent,
        languageController: ctrl,
        students: const [
          {'name': 'Faizan', 'feeStatus': 'paid', 'isPresent': true}
        ],
        onSave: (_) async {},
        onChangeRole: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('والد/مدر'), findsAtLeastNWidgets(1));
      expect(find.text('Faizan'), findsOneWidget);
    });
  });
}
