import 'package:flutter/material.dart';
import '../../config/theme.dart';

class CreateScreen extends StatelessWidget {
  const CreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('음악 만들기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ModeCard(icon: '🎵', title: '심플 모드', desc: '제목만 입력하면 AI가 알아서 만들어요', color: AppTheme.accent),
            const SizedBox(height: 12),
            _ModeCard(icon: '🎛️', title: '커스텀 모드', desc: '장르, 분위기, 가사 등 세밀하게 조정', color: AppTheme.accent2),
            const SizedBox(height: 12),
            _ModeCard(icon: '🎬', title: 'YouTube 모드', desc: 'YouTube URL로 비슷한 곡 생성', color: AppTheme.green),
            const SizedBox(height: 12),
            _ModeCard(icon: '📹', title: '뮤직비디오', desc: '음악에 맞는 영상 자동 생성', color: AppTheme.yellow),
          ],
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final String icon, title, desc;
  final Color color;
  const _ModeCard({required this.icon, required this.title, required this.desc, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.card,
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(children: [
        Text(icon, style: const TextStyle(fontSize: 28)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 15)),
          const SizedBox(height: 2),
          Text(desc, style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
        ])),
        Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.textTertiary),
      ]),
    );
  }
}
