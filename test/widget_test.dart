import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maktab_management_system/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({'user_selected_role': 'manager'});
  });

  testWidgets('Maktab App Smoke Test - Renders main screen with language button', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Verify Title / App bar is present
    expect(find.textContaining('مکتب'), findsAtLeastNWidgets(1));

    // Verify Language button is present
    expect(find.byIcon(Icons.language), findsOneWidget);
  });

  testWidgets('Toggles language to English via PopupMenuButton', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    // Tap language button
    await tester.tap(find.byIcon(Icons.language));
    await tester.pumpAndSettle();

    // Select English option
    final englishOption = find.text('English');
    expect(englishOption, findsWidgets);
    await tester.tap(englishOption.first);
    await tester.pumpAndSettle();

    // Verify Title switched to English 'Manager'
    expect(find.textContaining('Manager'), findsAtLeastNWidgets(1));
  });
}
