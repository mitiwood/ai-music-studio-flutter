import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/theme.dart';
import 'providers/app_provider.dart';
import 'screens/home/home_screen.dart';
import 'services/auth_service.dart';
import 'services/push_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Kakao SDK 초기화
  AuthService.initKakao();
  // Firebase/FCM 초기화 (미설정 시 무시)
  PushService.initialize();
  runApp(const KMSApp());
}

class KMSApp extends StatelessWidget {
  const KMSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: MaterialApp(
        title: "Kenny's Music Studio",
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const HomeScreen(),
      ),
    );
  }
}
