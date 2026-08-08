import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  static const String _prefKey = 'selected_theme_mode';
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isSystemMode => _themeMode == ThemeMode.system;

  ThemeController() {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString(_prefKey) ?? 'system';
      if (modeStr == 'dark') {
        _themeMode = ThemeMode.dark;
      } else if (modeStr == 'light') {
        _themeMode = ThemeMode.light;
      } else {
        _themeMode = ThemeMode.system;
      }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> toggleTheme() async {
    // Cycle through: System -> Light -> Dark -> System
    if (_themeMode == ThemeMode.system) {
      _themeMode = ThemeMode.light;
    } else if (_themeMode == ThemeMode.light) {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _prefKey,
        _themeMode == ThemeMode.dark ? 'dark' : (_themeMode == ThemeMode.light ? 'light' : 'system'),
      );
    } catch (_) {}
  }
}

class ThemeButton extends StatelessWidget {
  final ThemeController controller;

  const ThemeButton({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String tooltip;

    if (controller.isSystemMode) {
      icon = Icons.brightness_auto;
      tooltip = 'System Theme (Tap to switch)';
    } else if (controller.isDarkMode) {
      icon = Icons.dark_mode;
      tooltip = 'Dark Mode (Tap to switch)';
    } else {
      icon = Icons.light_mode;
      tooltip = 'Light Mode (Tap to switch)';
    }

    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: () {
        controller.toggleTheme();
      },
    );
  }
}
