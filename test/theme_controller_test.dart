import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:maktab_management_system/theme_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ThemeController initializes with system theme', () {
    final controller = ThemeController();
    expect(controller.themeMode, ThemeMode.system);
    expect(controller.isSystemMode, true);
  });

  test('ThemeController toggles theme (system -> light -> dark -> system)', () async {
    final controller = ThemeController();
    expect(controller.themeMode, ThemeMode.system);

    await controller.toggleTheme();
    expect(controller.themeMode, ThemeMode.light);

    await controller.toggleTheme();
    expect(controller.themeMode, ThemeMode.dark);

    await controller.toggleTheme();
    expect(controller.themeMode, ThemeMode.system);
  });
}
