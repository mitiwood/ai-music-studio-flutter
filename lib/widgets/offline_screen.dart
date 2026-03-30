import 'package:flutter/material.dart';
import '../utils/constants.dart';

class OfflineScreen extends StatefulWidget {
  final VoidCallback onRetry;
  const OfflineScreen({super.key, required this.onRetry});

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _bounce;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _bounce = Tween<double>(begin: -8, end: 8).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _handleRetry() async {
    setState(() => _retrying = true);
    await Future.delayed(const Duration(milliseconds: 500));
    widget.onRetry();
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.3), radius: 1.2,
          colors: [Color(0xFF1A1040), AppColors.bgDark],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedBuilder(
              animation: _bounce,
              builder: (_, __) => Transform.translate(
                offset: Offset(0, _bounce.value),
                child: Container(
                  width: 80, height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withAlpha(77)),
                  ),
                  child: const Icon(Icons.wifi_off_rounded, size: 40, color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text('인터넷 연결이 필요합니다',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            const Text('Wi-Fi 또는 모바일 데이터를\n확인해주세요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: _retrying ? null : _handleRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _retrying
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.refresh_rounded, size: 20),
                      SizedBox(width: 8),
                      Text('다시 시도', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ]),
              ),
            ),
            const SizedBox(height: 16),
            Text('오프라인에서는 다운로드된 음악만 재생할 수 있습니다',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.textMuted.withAlpha(153))),
          ]),
        ),
      ),
    );
  }
}
