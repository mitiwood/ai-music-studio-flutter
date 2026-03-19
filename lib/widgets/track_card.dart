import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/track.dart';
import '../utils/share_utils.dart';

class TrackCard extends StatelessWidget {
  final Track track;
  final VoidCallback? onPlay;
  final VoidCallback? onLike;
  final VoidCallback? onTap;

  const TrackCard({super.key, required this.track, this.onPlay, this.onLike, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppTheme.card,
          border: Border.all(color: AppTheme.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: [
          // Cover image + play button
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Stack(children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: track.imageUrl.isNotEmpty
                    ? Image.network(track.imageUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder())
                    : _placeholder(),
              ),
              Positioned.fill(
                child: Center(
                  child: GestureDetector(
                    onTap: onPlay,
                    child: Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
              if (track.hasMV)
                Positioned(
                  top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.yellow.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('MV', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.black)),
                  ),
                ),
            ]),
          ),
          // Info
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(track.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(children: [
                if (track.ownerAvatar.isNotEmpty && !track.isGuest)
                  CircleAvatar(backgroundImage: NetworkImage(track.ownerAvatar), radius: 10),
                if (track.ownerAvatar.isNotEmpty && !track.isGuest) const SizedBox(width: 6),
                Text(track.isGuest ? '게스트' : track.ownerName,
                    style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
                const Spacer(),
                _Badge(track.genMode),
              ]),
              const SizedBox(height: 10),
              Row(children: [
                _ActionBtn(icon: Icons.favorite, label: '${track.likes}', onTap: onLike, color: AppTheme.red),
                const SizedBox(width: 12),
                _ActionBtn(icon: Icons.play_arrow, label: '${track.plays}'),
                const SizedBox(width: 12),
                _ActionBtn(
                  icon: Icons.share_outlined,
                  label: '공유',
                  onTap: () {
                    ShareUtils.shareTrack(track);
                  },
                ),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(color: AppTheme.bg3, child: const Center(child: Icon(Icons.music_note, size: 32, color: AppTheme.textTertiary)));
}

class _Badge extends StatelessWidget {
  final String mode;
  const _Badge(this.mode);
  @override
  Widget build(BuildContext context) {
    final labels = {'custom': '커스텀', 'simple': '심플', 'youtube': 'YouTube', 'mv': 'MV'};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.12),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(labels[mode] ?? mode, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.accent)),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Color color;
  const _ActionBtn({required this.icon, required this.label, this.onTap, this.color = AppTheme.textTertiary});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color)),
      ]),
    );
  }
}
