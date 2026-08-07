import 'package:flutter/material.dart';

class AppTheme {
  // Flat Color Palette
  static const Color charcoal = Color(0xFF2C3E50);
  static const Color cobalt = Color(0xFF3498DB);
  static const Color emerald = Color(0xFF27AE60);
  static const Color orange = Color(0xFFE67E22);
  static const Color crimson = Color(0xFFC0392B);
  static const Color cloudWhite = Color(0xFFECF0F1);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: cobalt,
      scaffoldBackgroundColor: cloudWhite,
      appBarTheme: const AppBarTheme(
        backgroundColor: charcoal,
        foregroundColor: cloudWhite,
        elevation: 0,
      ),
      colorScheme: const ColorScheme.light(
        primary: cobalt,
        secondary: emerald,
        error: crimson,
        surface: Colors.white,
      ),
      fontFamily: 'Segoe UI', // Good standard for Windows desktop
    );
  }
}
