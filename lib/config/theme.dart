import 'package:flutter/material.dart';

/// KMS 다크 테마 (웹 버전과 동일한 색상 체계)
class AppTheme {
  static const Color bg = Color(0xFF0A0A0F);
  static const Color bg2 = Color(0xFF111118);
  static const Color bg3 = Color(0xFF1A1A24);
  static const Color card = Color(0xFF16161F);
  static const Color card2 = Color(0xFF1E1E2A);
  static const Color accent = Color(0xFFA855F7);
  static const Color accent2 = Color(0xFF7C3AED);
  static const Color textPrimary = Color(0xFFF0F0F8);
  static const Color textSecondary = Color(0xFFB0B0C8);
  static const Color textTertiary = Color(0xFF666680);
  static const Color red = Color(0xFFFF4560);
  static const Color green = Color(0xFF00DDA0);
  static const Color yellow = Color(0xFFFFD000);
  static const Color border = Color(0x12FFFFFF);

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        primaryColor: accent,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          secondary: accent2,
          surface: card,
          error: red,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: bg2,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardThemeData(
          color: card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: border),
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: bg2,
          selectedItemColor: accent,
          unselectedItemColor: textTertiary,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(color: textPrimary, fontWeight: FontWeight.w800),
          bodyLarge: TextStyle(color: textPrimary),
          bodyMedium: TextStyle(color: textSecondary),
          bodySmall: TextStyle(color: textTertiary),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
        ),
      );
}
