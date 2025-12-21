import 'package:flutter/material.dart';

/// Simple navigation service for ESC key handling
/// ESC key simulates the back arrow button behavior
class NavigationService {
  /// Handle ESC key press - simulate back arrow button
  static bool handleEscapeKey(BuildContext context) {
    try {
      final currentRoute = ModalRoute.of(context)?.settings.name ?? 'unknown';
      print('� ESC pressed on screen: $currentRoute');
      
      // Check if we can navigate back (same logic as back arrow button)
      if (Navigator.of(context).canPop()) {
        print('⬅️ Navigating back (simulating back arrow button)');
        Navigator.of(context).pop();
        return true; // Consume the key event
      } else {
        print('🚫 Cannot navigate back - no previous screen in stack');
        return false; // Don't consume the key event
      }
    } catch (e) {
      print('❌ Error handling ESC key: $e');
      return false;
    }
  }
}