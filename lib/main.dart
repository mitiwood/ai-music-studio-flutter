import 'package:flutter/material.dart';
import 'config/theme.dart';
import 'screens/home/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const KMSApp());
}

class KMSApp extends StatelessWidget {
  const KMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Kenny's Music Studio",
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}
