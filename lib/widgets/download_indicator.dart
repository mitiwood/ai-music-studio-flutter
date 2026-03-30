import 'package:flutter/material.dart';
import '../utils/constants.dart';

class DownloadIndicator extends StatelessWidget {
  final String fileName;
  final double progress;
  final VoidCallback? onCancel;

  const DownloadIndicator({
    super.key, required this.fileName, required this.progress, this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final isComplete = progress >= 1.0;
    return Positioned(
      bottom: 100, left: 16, right: 16,
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardDark.withAlpha(242),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isComplete ? AppColors.success.withAlpha(128) : AppColors.primary.withAlpha(77)),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(77), blurRadius: 16, offset: const Offset(0, 4))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Icon(isComplete ? Icons.check_circle_rounded : Icons.download_rounded,
                color: isComplete ? AppColors.success : AppColors.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(child: Text(isComplete ? '다운로드 완료' : '다운로드 중...',
                style: TextStyle(color: isComplete ? AppColors.success : AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600))),
              if (!isComplete && onCancel != null)
                GestureDetector(onTap: onCancel, child: const Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18)),
            ]),
            const SizedBox(height: 4),
            Text(fileName, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12), overflow: TextOverflow.ellipsis),
            if (!isComplete) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress > 0 ? progress : null, minHeight: 4,
                  backgroundColor: AppColors.surfaceDark,
                  valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                ),
              ),
              const SizedBox(height: 4),
              Text('${(progress * 100).round()}%', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ],
          ]),
        ),
      ),
    );
  }
}
