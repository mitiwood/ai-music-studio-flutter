import 'package:flutter/material.dart';

class AppTheme {
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFFA855F7);
  static const Color accent = Color(0xFF6366F1);
  static const Color accent2 = Color(0xFF818CF8);
  static const Color accent3 = Color(0xFFA78BFA);
  static const Color bg = Color(0xFF0A0A1A);
  static const Color bg2 = Color(0xFF12121F);
  static const Color bg3 = Color(0xFF1A1A2E);
  static const Color card = Color(0xFF16162A);
  static const Color card2 = Color(0xFF1E1E36);
  static const Color border = Color(0xFF2A2A45);
  static const Color t1 = Color(0xFFEEEEF0);
  static const Color t2 = Color(0xFFA09AB8);
  static const Color t3 = Color(0xFF6B6580);
  static const Color red = Color(0xFFEF4444);
  static const Color green = Color(0xFF10B981);
  static const Color yellow = Color(0xFFF59E0B);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: primary,
    scaffoldBackgroundColor: bg,
    fontFamily: 'Pretendard',
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: primaryLight,
      surface: card,
      error: red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: bg, elevation: 0,
      titleTextStyle: TextStyle(color: t1, fontSize: 17, fontWeight: FontWeight.w800),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: bg2,
      selectedItemColor: primary,
      unselectedItemColor: t3,
      type: BottomNavigationBarType.fixed,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
    cardTheme: CardTheme(
      color: card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: const BorderSide(color: border, width: 1)),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true, fillColor: bg3,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: primary)),
      hintStyle: const TextStyle(color: t3, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: accent3),
    ),
  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primary,
    scaffoldBackgroundColor: const Color(0xFFF5F5F7),
    fontFamily: 'Pretendard',
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: primaryLight,
      surface: Colors.white,
      error: red,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white, elevation: 0,
      titleTextStyle: TextStyle(color: Color(0xFF1C1C1E), fontSize: 17, fontWeight: FontWeight.w800),
      iconTheme: IconThemeData(color: Color(0xFF1C1C1E)),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: primary,
      unselectedItemColor: Color(0xFF999999),
      type: BottomNavigationBarType.fixed,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14), side: BorderSide(color: Colors.grey.shade200)),
      elevation: 0,
    ),
  );

  static LinearGradient primaryGradient = const LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
}
