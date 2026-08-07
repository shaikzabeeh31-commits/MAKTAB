import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const String _prefKey = 'selected_theme_mode';
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  ThemeController() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString(_prefKey) ?? 'light';
      if (modeStr == 'dark') {
        _themeMode = ThemeMode.dark;
      } else {
        _themeMode = ThemeMode.light;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.light;
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefKey,
        _themeMode == ThemeMode.dark ? 'dark' : 'light',
      );
    } catch (_) {}
  }
}

class ThemeButton extends StatelessWidget {
  final ThemeController controller;

  const ThemeButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        controller.isDarkMode ? Icons.light_mode : Icons.dark_mode,
      ),
      tooltip: controller.isDarkMode ? 'Light Mode' : 'Dark Mode',
      onPressed: () {
        controller.toggleTheme();
      },
    );
  }
}
