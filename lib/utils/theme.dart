import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF5B2FA6);
  static const Color primaryDark = Color(0xFF4A2290);
  static const Color accent = Color(0xFF8B5CF6);
  static const Color background = Color(0xFFF9FAFC);

  static ThemeData light() {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      fontFamily: 'Poppins',
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}