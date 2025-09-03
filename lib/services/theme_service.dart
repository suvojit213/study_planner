import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  Color _appColor = Colors.blue;

  ThemeMode get themeMode => _themeMode;
  Color get appColor => _appColor;

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('themeMode');
    if (themeModeString == 'dark') {
      _themeMode = ThemeMode.dark;
    } else if (themeModeString == 'light') {
      _themeMode = ThemeMode.light;
    } else {
      _themeMode = ThemeMode.system;
    }

    final colorValue = prefs.getInt('appColor');
    if (colorValue != null) {
      _appColor = Color(colorValue);
    }

    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    _themeMode = themeMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', themeMode.toString().split('.').last);
    notifyListeners();
  }

  Future<void> setAppColor(Color color) async {
    _appColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('appColor', color.value);
    notifyListeners();
  }
}
