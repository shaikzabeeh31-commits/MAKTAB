import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maktab_management_system/theme/app_colors.dart';
import 'package:maktab_management_system/theme/app_components.dart';
import 'package:maktab_management_system/theme/app_theme.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();


  group('Design System & UI Components Unit & Widget Tests', () {
    test('AppTheme builds valid Light and Dark themes', () {
      final lightTheme = AppTheme.lightTheme();
      final darkTheme = AppTheme.darkTheme();

      expect(lightTheme.useMaterial3, isTrue);
      expect(darkTheme.useMaterial3, isTrue);
      expect(lightTheme.colorScheme.primary, equals(AppColors.primary));
    });

    testWidgets('StatCardWidget renders label, value and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                StatCardWidget(
                  label: 'Total Students',
                  value: '150',
                  icon: Icons.school,
                  color: Colors.green,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Total Students'), findsOneWidget);
      expect(find.text('150'), findsOneWidget);
      expect(find.byIcon(Icons.school), findsOneWidget);
    });

    testWidgets('StatusChipWidget renders label and icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatusChipWidget(
              label: 'Paid',
              color: Colors.green,
              icon: Icons.check,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Paid'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    });
  });
}
