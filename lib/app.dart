import 'package:flutter/material.dart';
import 'splash_screen.dart';
import 'utils/theme.dart';

class KMSApp extends StatelessWidget {
  const KMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Kenny's Music Studio",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
    );
  }
}
