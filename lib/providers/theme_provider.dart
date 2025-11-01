import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;
  
  // Set theme mode and notify listeners
  void setThemeMode(ThemeMode themeMode) {
    _themeMode = themeMode;
    notifyListeners();
  }
  
  // Toggle between light and dark theme
  void toggleTheme() {
    final newTheme = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    setThemeMode(newTheme);
  }
  
  // Set light theme
  void setLightTheme() {
    setThemeMode(ThemeMode.light);
  }
  
  // Set dark theme
  void setDarkTheme() {
    setThemeMode(ThemeMode.dark);
  }
  
  // Set system theme
  void setSystemTheme() {
    setThemeMode(ThemeMode.system);
  }
}
