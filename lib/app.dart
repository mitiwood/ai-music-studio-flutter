import 'package:flutter/material.dart';
import 'splash_screen.dart';

class KMSApp extends StatelessWidget {
  const KMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Kenny's Music Studio",
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF7C3AED),
        scaffoldBackgroundColor: const Color(0xFF0A0A1A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7C3AED),
          secondary: Color(0xFFA855F7),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
