import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/user.dart';
import '../../providers/app_provider.dart';
import '../../widgets/track_card.dart';
import '../admin/admin_screen.dart';
import '../player/player_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('프로필', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.isLoggedIn) {
            return _LoggedInView(provider: provider);
          }
          return _LoginView();
        },
      ),
    );
  }
}

class _LoginView extends StatelessWidget {
  Future<void> _handleLogin(BuildContext context, Future<bool> Function() loginFn, String providerName) async {
    final success = await loginFn();
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$providerName 로그인에 실패했습니다'),
          backgroundColor: AppTheme.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        if (provider.loginLoading) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: AppTheme.accent),
                SizedBox(height: 16),
                Text('로그인 중...', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
              ],
            ),
          );
        }
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(color: AppTheme.bg3, shape: BoxShape.circle),
                child: const Center(child: Icon(Icons.person, size: 40, color: AppTheme.textTertiary)),
              ),
              const SizedBox(height: 16),
              const Text('로그인이 필요합니다',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              const Text('소셜 로그인으로 내 음악을 관리하세요',
                  style: TextStyle(color: AppTheme.textTertiary, fontSize: 13)),
              const SizedBox(height: 24),
              _LoginButton(
                icon: Icons.chat_bubble,
                label: 'Naver로 로그인',
                color: const Color(0xFF03C75A),
                onTap: () => _handleLogin(context, provider.loginWithNaver, 'Naver'),
              ),
              const SizedBox(height: 10),
              _LoginButton(
                icon: Icons.chat,
                label: 'Kakao로 로그인',
                color: const Color(0xFFFEE500),
                textColor: Colors.black,
                onTap: () => _handleLogin(context, provider.loginWithKakao, 'Kakao'),
              ),
              const SizedBox(height: 10),
              _LoginButton(
                icon: Icons.g_mobiledata,
                label: 'Google로 로그인',
                color: const Color(0xFFEA4335),
                onTap: () => _handleLogin(context, provider.loginWithGoogle, 'Google'),
              ),
              const SizedBox(height: 24),
              TextButton(
                onPressed: () {
                  final p = context.read<AppProvider>();
                  p.login(AppUser(
                    name: '게스트',
                    provider: 'guest',
                  ));
                },
                child: const Text('게스트로 계속하기',
                    style: TextStyle(color: AppTheme.textTertiary, fontSize: 13)),
              ),
            ]),
          ),
        );
      },
    );
  }
}

class _LoginButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _LoginButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }
}

class _LoggedInView extends StatefulWidget {
  final AppProvider provider;
  const _LoggedInView({required this.provider});

  @override
  State<_LoggedInView> createState() => _LoggedInViewState();
}

class _LoggedInViewState extends State<_LoggedInView> {
  @override
  void initState() {
    super.initState();
    widget.provider.loadMyTracks();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.provider.currentUser!;
    final planInfo = AppConstants.plans[user.plan] ?? AppConstants.plans['free']!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // User info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 36,
                  backgroundColor: AppTheme.bg3,
                  backgroundImage:
                      user.avatar.isNotEmpty ? NetworkImage(user.avatar) : null,
                  child: user.avatar.isEmpty
                      ? const Icon(Icons.person, size: 36, color: AppTheme.textTertiary)
                      : null,
                ),
                const SizedBox(height: 12),
                Text(
                  user.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email.isNotEmpty ? user.email : user.provider,
                  style: const TextStyle(color: AppTheme.textTertiary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                // Plan & Credits
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _InfoChip(
                      icon: Icons.workspace_premium,
                      label: planInfo['label'] as String,
                      color: user.isPremium ? AppTheme.yellow : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 12),
                    _InfoChip(
                      icon: Icons.bolt,
                      label: '${user.credits} 크레딧',
                      color: AppTheme.accent,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Settings section
          Container(
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.notifications_outlined,
                  title: '알림 설정',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('알림 설정은 준비 중입니다'), backgroundColor: AppTheme.accent),
                    );
                  },
                ),
                const Divider(color: AppTheme.border, height: 1),
                _SettingsTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: '관리자',
                  subtitle: '유저/트랙/댓글/공지 관리',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
                  },
                ),
                const Divider(color: AppTheme.border, height: 1),
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: '앱 정보',
                  subtitle: AppConstants.appVersion,
                  onTap: () {},
                ),
                const Divider(color: AppTheme.border, height: 1),
                _SettingsTile(
                  icon: Icons.logout,
                  title: '로그아웃',
                  color: AppTheme.red,
                  onTap: () {
                    widget.provider.logout();
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // My tracks
          Row(
            children: [
              const Text('내 트랙',
                  style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              Text('${widget.provider.myTracks.length}곡',
                  style: const TextStyle(color: AppTheme.textTertiary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.provider.myTracksLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator(color: AppTheme.accent)),
            )
          else if (widget.provider.myTracks.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  const Icon(Icons.music_off, size: 40, color: AppTheme.textTertiary),
                  const SizedBox(height: 10),
                  const Text('아직 만든 곡이 없어요',
                      style: TextStyle(color: AppTheme.textTertiary, fontSize: 13)),
                ],
              ),
            )
          else
            ...widget.provider.myTracks.map((track) => TrackCard(
                  track: track,
                  onPlay: () => widget.provider.playTrack(track),
                  onLike: () => widget.provider.likeTrack(track.id),
                  onDislike: () => widget.provider.dislikeTrack(track.id),
                  showDelete: true,
                  onDelete: () async {
                    final ok = await widget.provider.deleteTrack(track.id);
                    if (ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('트랙이 삭제되었습니다'), backgroundColor: AppTheme.accent),
                      );
                    }
                  },
                  onTap: () {
                    widget.provider.playTrack(track);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => PlayerScreen(track: track)),
                    );
                  },
                )),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.color = AppTheme.textPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(title, style: TextStyle(color: color, fontSize: 14)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12))
          : null,
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textTertiary),
      onTap: onTap,
    );
  }
}
