import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/app_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final user = provider.user;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 4),
            const Text('설정', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
            const SizedBox(height: 20),
            // User card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(children: [
                CircleAvatar(
                  radius: 28, backgroundColor: Colors.white24,
                  backgroundImage: user?.avatar != null ? NetworkImage(user!.avatar!) : null,
                  child: user?.avatar == null
                    ? Text(
                        user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : '?',
                        style: const TextStyle(fontSize: 24, color: Colors.white),
                      )
                    : null,
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user?.name ?? '게스트', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('${user?.planIcon ?? '🆓'} ${user?.planLabel ?? 'Free'} · ${user?.provider ?? 'guest'}', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ])),
              ]),
            ),
            const SizedBox(height: 20),
            // Theme
            _settingsCard(
              icon: Icons.dark_mode, title: '테마',
              subtitle: provider.themeMode == ThemeMode.dark ? '다크 모드' : '데이 모드',
              trailing: Switch(value: provider.themeMode == ThemeMode.dark, onChanged: (_) => provider.toggleTheme(), activeColor: AppTheme.primary),
            ),
            const SizedBox(height: 8),
            // Plan info
            _settingsCard(
              icon: Icons.workspace_premium, title: '플랜 정보',
              subtitle: '${user?.planLabel ?? "Free"} · 곡 ${user?.creditsSong ?? 5}/월',
              trailing: const Icon(Icons.chevron_right, color: AppTheme.t3),
            ),
            const SizedBox(height: 8),
            // Login / Logout
            if (user == null || user.isGuest)
              _settingsCard(icon: Icons.login, title: '로그인', subtitle: 'Google, 카카오, 네이버', trailing: const Icon(Icons.chevron_right, color: AppTheme.t3), onTap: () => _showLoginSheet(context))
            else
              _settingsCard(icon: Icons.logout, title: '로그아웃', subtitle: user.email ?? '', trailing: const Icon(Icons.chevron_right, color: AppTheme.t3), onTap: () => provider.logout()),
            const SizedBox(height: 8),
            _settingsCard(icon: Icons.info_outline, title: '앱 정보', subtitle: 'v2.0.0 · Flutter', trailing: const Icon(Icons.chevron_right, color: AppTheme.t3)),
          ],
        ),
      ),
    );
  }

  Widget _settingsCard({required IconData icon, required String title, String? subtitle, Widget? trailing, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppTheme.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppTheme.border)),
        child: Row(children: [
          Icon(icon, size: 22, color: AppTheme.accent3),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            if (subtitle != null) Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.t3)),
          ])),
          if (trailing != null) trailing,
        ]),
      ),
    );
  }

  void _showLoginSheet(BuildContext context) {
    showModalBottomSheet(
      context: context, backgroundColor: AppTheme.bg2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          const Text('로그인', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          const Text('소셜 계정으로 간편 로그인', style: TextStyle(color: AppTheme.t3)),
          const SizedBox(height: 24),
          _loginButton('Google로 로그인', Colors.white, Colors.black87, () {}),
          const SizedBox(height: 10),
          _loginButton('카카오로 로그인', const Color(0xFFFEE500), Colors.black87, () {}),
          const SizedBox(height: 10),
          _loginButton('네이버로 로그인', const Color(0xFF03C75A), Colors.white, () {}),
          const SizedBox(height: 20),
        ]),
      ),
    );
  }

  Widget _loginButton(String text, Color bg, Color fg, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity, height: 50,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: bg, foregroundColor: fg, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
      ),
    );
  }
}
