import 'package:flutter/material.dart';

/// Color palette for the app with light and dark mode colors.
class AppColors {
  // Primary color - Green
  static const Color primary = Color(0xFF2E7D32);
  static const Color primaryLight = Color(0xFF60AC5D);
  static const Color primaryDark = Color(0xFF005005);
  
  // Secondary color - Blue
  static const Color secondary = Color(0xFF1976D2);
  static const Color secondaryLight = Color(0xFF63A4FF);
  static const Color secondaryDark = Color(0xFF004BA0);
  
  // Accent colors
  static const Color accent1 = Color(0xFFFFA000);  // Amber
  static const Color accent2 = Color(0xFFD81B60);  // Pink
  static const Color accent3 = Color(0xFF8E24AA);  // Purple
  
  // Background colors
  static const Color background = Color(0xFFF5F5F5);  // Light grey
  static const Color backgroundDark = Color(0xFF121212);  // Almost black
  
  // Surface colors (cards, dialogs, etc.)
  static const Color surface = Color(0xFFFFFFFF);  // White
  static const Color surfaceDark = Color(0xFF1E1E1E);  // Dark grey
  
  // Text colors
  static const Color textPrimary = Color(0xFF212121);  // Almost black
  static const Color textSecondary = Color(0xFF757575);  // Medium grey
  static const Color textPrimaryDark = Color(0xFFE0E0E0);  // Light grey
  static const Color textSecondaryDark = Color(0xFF9E9E9E);  // Medium grey
  
  // Functional colors
  static const Color error = Color(0xFFD32F2F);  // Red
  static const Color success = Color(0xFF388E3C);  // Green
  static const Color warning = Color(0xFFF57C00);  // Orange
  static const Color info = Color(0xFF0288D1);  // Blue
  
  // Dark mode functional colors
  static const Color errorDark = Color(0xFFEF5350);  // Lighter red
  static const Color successDark = Color(0xFF66BB6A);  // Lighter green
  static const Color warningDark = Color(0xFFFF9800);  // Lighter orange
  static const Color infoDark = Color(0xFF29B6F6);  // Lighter blue
  
  // Border colors
  static const Color border = Color(0xFFE0E0E0);  // Light grey
  static const Color borderDark = Color(0xFF424242);  // Dark grey
  
  // Disabled colors
  static const Color disabledBackground = Color(0xFFEEEEEE);  // Very light grey
  static const Color disabledText = Color(0xFFBDBDBD);  // Light grey
  static const Color disabledBackgroundDark = Color(0xFF424242);  // Dark grey
  static const Color disabledTextDark = Color(0xFF757575);  // Medium grey
  
  // Input field background
  static const Color inputBackground = Color(0xFFF5F5F5);  // Light grey
  static const Color inputBackgroundDark = Color(0xFF2C2C2C);  // Darker grey
  
  // Transparent colors (for overlays, etc.)
  static const Color overlay = Color(0x80000000);  // Black with 50% opacity
  static const Color overlayLight = Color(0x33000000);  // Black with 20% opacity
  
  // Semantic colors for specific features
  static const Map<String, Color> orderStatus = {  // Changed from Color to Map<String, Color>
    'pending': Color(0xFFFFA000),  // Amber
    'processing': Color(0xFF1976D2),  // Blue
    'delivered': Color(0xFF388E3C),  // Green
    'cancelled': Color(0xFFD32F2F),  // Red
  };
  
  // Material color swatches
  static const MaterialColor primarySwatch = MaterialColor(
    0xFF2E7D32,
    <int, Color>{
      50: Color(0xFFE8F5E9),
      100: Color(0xFFC8E6C9),
      200: Color(0xFFA5D6A7),
      300: Color(0xFF81C784),
      400: Color(0xFF66BB6A),
      500: Color(0xFF4CAF50),
      600: Color(0xFF43A047),
      700: Color(0xFF388E3C),
      800: Color(0xFF2E7D32),
      900: Color(0xFF1B5E20),
    },
  );
  
  static const MaterialColor secondarySwatch = MaterialColor(
    0xFF1976D2,
    <int, Color>{
      50: Color(0xFFE3F2FD),
      100: Color(0xFFBBDEFB),
      200: Color(0xFF90CAF9),
      300: Color(0xFF64B5F6),
      400: Color(0xFF42A5F5),
      500: Color(0xFF2196F3),
      600: Color(0xFF1E88E5),
      700: Color(0xFF1976D2),
      800: Color(0xFF1565C0),
      900: Color(0xFF0D47A1),
    },
  );
  
  // Neutral color shades (greys)
  static const Map<int, Color> neutral = {
    50: Color(0xFFFAFAFA),
    100: Color(0xFFF5F5F5),
    200: Color(0xFFEEEEEE),
    300: Color(0xFFE0E0E0),
    400: Color(0xFFBDBDBD),
    500: Color(0xFF9E9E9E),
    600: Color(0xFF757575),
    700: Color(0xFF616161),
    800: Color(0xFF424242),
    900: Color(0xFF212121),
  };
}