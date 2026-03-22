import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/app_provider.dart';

class AttendanceBanner extends StatelessWidget {
  const AttendanceBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    if (!provider.isLoggedIn || provider.attendance == null) return const SizedBox.shrink();
    final att = provider.attendance!;
    final checked = att['todayChecked'] == true;
    final streak = (att['currentStreak'] ?? 0) as int;
    final monthCount = att['monthCount'] ?? 0;

    return GestureDetector(
      onTap: checked ? null : () async {
        final result = await provider.doCheckIn();
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? '출석 체크 완료!'), backgroundColor: AppTheme.green));
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppTheme.primary.withOpacity(0.12), AppTheme.primaryLight.withOpacity(0.08)]),
          borderRadius: BorderRadius.circular(12), border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
        ),
        child: Row(children: [
          const Text('📅', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(checked ? '$streak일 연속 출석 중!' : '출석 체크하고 보너스 받기', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
            Text(checked ? '이번 달 $monthCount일 출석' : '매일 접속하면 보너스 크레딧!', style: const TextStyle(fontSize: 11, color: AppTheme.t3)),
            const SizedBox(height: 4),
            Row(children: List.generate(7, (i) => Container(width: 8, height: 8, margin: const EdgeInsets.only(right: 3),
              decoration: BoxDecoration(shape: BoxShape.circle, color: i < streak % 7 ? AppTheme.primary : (i == streak % 7 && checked ? AppTheme.yellow : AppTheme.border))))),
          ])),
          Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(gradient: checked ? null : AppTheme.primaryGradient, color: checked ? AppTheme.bg3 : null, borderRadius: BorderRadius.circular(20)),
            child: Text(checked ? '완료' : '출석하기', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: checked ? AppTheme.t3 : Colors.white))),
        ]),
      ),
    );
  }
}
