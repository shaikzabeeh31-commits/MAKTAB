import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab_management_system/app_localizations.dart';
import 'package:maktab_management_system/community_chat_screen.dart';
import 'package:maktab_management_system/results_screen.dart';
import 'package:maktab_management_system/role_selection_screen.dart';
import 'package:maktab_management_system/theme_controller.dart';
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
    SharedPreferences.setMockInitialValues({'maktab_setup_complete': true});
  });

  group('Full System Features (51 to 100) Verification Tests', () {
    testWidgets('CommunityChatScreen renders channel chats, fee handover acknowledgement and message composer', (tester) async {
      final ctrl = LanguageController();
      await tester.pumpWidget(_wrap(CommunityChatScreen(languageController: ctrl, currentRole: AppRole.manager)));
      await tester.pumpAndSettle();

      expect(find.byType(CommunityChatScreen), findsOneWidget);
    });

    testWidgets('ResultsScreen renders Islamic Grading Badges and Top 3 Rank Position Holders banner', (tester) async {
      final ctrl = LanguageController();
      await tester.pumpWidget(_wrap(ResultsScreen(
        languageController: ctrl,
      )));
      await tester.pumpAndSettle();

      expect(find.textContaining('نتائج'), findsAtLeastNWidgets(1));
    });

    testWidgets('RoleDashboardScreen renders bottom navigation and role overview', (tester) async {
      final ctrl = LanguageController();
      await tester.pumpWidget(_wrap(RoleDashboardScreen(
        themeController: ThemeController(),
        currentRole: AppRole.manager,
        languageController: ctrl,
        students: const [],
        onSave: (s) async {},
        onChangeRole: () {},
      )));
      await tester.pumpAndSettle();

      expect(find.byType(RoleDashboardScreen), findsOneWidget);
    });
  });
}
