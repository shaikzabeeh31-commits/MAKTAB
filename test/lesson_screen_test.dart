import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab_management_system/app_localizations.dart';
import 'package:maktab_management_system/lesson_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_localizations/flutter_localizations.dart';

Widget _wrap(Widget child, {Locale locale = const Locale('en')}) {
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

  group('LessonScreen (Madrasa AIB Dars System) Widget Tests', () {
    testWidgets('Renders top bar, Section 1, Section 2, Section 3 and Bottom action buttons', (tester) async {
      final ctrl = LanguageController();
      ctrl.setLanguage('en');
      await tester.pumpWidget(_wrap(LessonScreen(languageController: ctrl)));
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.text('Select Subject'), findsOneWidget);
      expect(find.text('Lesson Entry (Speak or Type)'), findsOneWidget);
      expect(find.text('Dars Entry (In Class)'), findsOneWidget);

      expect(find.text('Save All Entries'), findsOneWidget);
      expect(find.text('Save as PDF'), findsOneWidget);
    });

    testWidgets('Renders student dars list with quality ratings and remarks', (tester) async {
      final ctrl = LanguageController();
      ctrl.setLanguage('en');
      final students = [
        {'name': 'Mohammad Ahmed', 'fatherName': 'Father A', 'group': 'Hifz Group A'},
        {'name': 'Abdullah Khan', 'fatherName': 'Father B', 'group': 'Hifz Group A'},
      ];
      await tester.pumpWidget(_wrap(LessonScreen(
        languageController: ctrl,
        students: students,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Mohammad Ahmed'), findsOneWidget);
      expect(find.text('Abdullah Khan'), findsOneWidget);
      expect(find.text('Mark All Yaad Hai'), findsOneWidget);
      expect(find.text('Mark All Iaadah'), findsOneWidget);
    });
  });
}
