import 'package:flutter/material.dart';
import '../../config/theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: AppTheme.bg3, shape: BoxShape.circle),
              child: const Center(child: Text('👤', style: TextStyle(fontSize: 36))),
            ),
            const SizedBox(height: 16),
            const Text('로그인이 필요합니다', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('소셜 로그인으로 내 음악을 관리하세요', style: TextStyle(color: AppTheme.textTertiary, fontSize: 13)),
            const SizedBox(height: 24),
            _LoginButton(icon: '🟢', label: 'Naver로 로그인', color: const Color(0xFF03C75A)),
            const SizedBox(height: 10),
            _LoginButton(icon: '🟡', label: 'Kakao로 로그인', color: const Color(0xFFFEE500), textColor: Colors.black),
            const SizedBox(height: 10),
            _LoginButton(icon: '🔴', label: 'Google로 로그인', color: const Color(0xFFEA4335)),
          ]),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  final String icon, label;
  final Color color;
  final Color textColor;
  const _LoginButton({required this.icon, required this.label, required this.color, this.textColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {/* TODO: 소셜 로그인 */},
        style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: textColor, padding: const EdgeInsets.symmetric(vertical: 14)),
        child: Text('$icon  $label', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
