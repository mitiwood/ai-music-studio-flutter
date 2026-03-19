import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/app_provider.dart';
import 'simple_create_screen.dart';
import 'custom_create_screen.dart';
import 'youtube_create_screen.dart';
import 'mv_create_screen.dart';
import '../payment/payment_screen.dart';

class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('음악 만들기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Credit balance
            Consumer<AppProvider>(
              builder: (context, provider, _) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accent.withValues(alpha: 0.15),
                        AppTheme.accent2.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppTheme.accent.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.bolt, color: AppTheme.yellow, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('보유 크레딧',
                                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(
                              '${provider.credits}회 남음',
                              style: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PaymentScreen()),
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.accent, AppTheme.accent2],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add, size: 14, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                '크레딧 충전',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            _ModeCard(
              icon: Icons.music_note,
              title: '심플 모드',
              desc: '제목만 입력하면 AI가 알아서 만들어요',
              color: AppTheme.accent,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SimpleCreateScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _ModeCard(
              icon: Icons.tune,
              title: '커스텀 모드',
              desc: '장르, 분위기, 가사 등 세밀하게 조정',
              color: AppTheme.accent2,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CustomCreateScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _ModeCard(
              icon: Icons.ondemand_video,
              title: 'YouTube 모드',
              desc: 'YouTube URL로 비슷한 곡 생성',
              color: AppTheme.green,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const YoutubeCreateScreen()),
              ),
            ),
            const SizedBox(height: 12),
            _ModeCard(
              icon: Icons.videocam,
              title: '뮤직비디오',
              desc: '음악에 맞는 영상 자동 생성',
              color: AppTheme.yellow,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MvCreateScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title, desc;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.desc,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.card,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 15)),
            const SizedBox(height: 2),
            Text(desc, style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
          ])),
          Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textTertiary),
        ]),
      ),
    );
  }
}
