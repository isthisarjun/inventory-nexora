import 'package:flutter/material.dart';

class AppProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  ThemeData _themeData = ThemeData.light();
  ThemeData get themeData => _themeData;

  AppProvider() {
    // Initialize with default theme
    _updateTheme();
  }

  void toggleThemeMode() {
    _isDarkMode = !_isDarkMode;
    _updateTheme();
    notifyListeners();
  }

  void _updateTheme() {
    _themeData = _isDarkMode ? ThemeData.dark() : ThemeData.light();
  }
}