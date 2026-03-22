import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../models/track.dart';
import '../providers/app_provider.dart';

class TrackCard extends StatelessWidget {
  final Track track;
  final bool showOwner;
  const TrackCard({super.key, required this.track, this.showOwner = true});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final isPlaying = provider.audio.currentTrackId == track.id;
    return GestureDetector(
      onTap: () => provider.playTrack(track),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isPlaying ? AppTheme.primary.withOpacity(0.08) : AppTheme.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isPlaying ? AppTheme.primary.withOpacity(0.3) : AppTheme.border),
        ),
        child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 48, height: 48,
            child: track.imageUrl != null && track.imageUrl!.isNotEmpty
              ? CachedNetworkImage(imageUrl: track.imageUrl!, fit: BoxFit.cover, placeholder: (_, __) => _ph(), errorWidget: (_, __, ___) => _ph())
              : _ph())),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(track.title.isEmpty ? '무제' : track.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: isPlaying ? AppTheme.primary : null), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(children: [
              if (showOwner) ...[Text(track.ownerName.isEmpty ? '익명' : track.ownerName, style: const TextStyle(fontSize: 11, color: AppTheme.t3)), const SizedBox(width: 6)],
              Text('❤️ ${track.likeCount}', style: const TextStyle(fontSize: 10, color: AppTheme.t3)),
              if (track.model != null) ...[const SizedBox(width: 6), Text(track.model!, style: const TextStyle(fontSize: 9, color: AppTheme.accent3))],
            ]),
          ])),
          IconButton(icon: Icon(track.liked ? Icons.favorite : Icons.favorite_border, size: 20, color: track.liked ? Colors.redAccent : AppTheme.t3),
            onPressed: () => context.read<AppProvider>().toggleLike(track), padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 36)),
          if (isPlaying) const Icon(Icons.equalizer, size: 20, color: AppTheme.primary),
        ]),
      ),
    );
  }
  Widget _ph() => Container(color: AppTheme.bg3, child: const Center(child: Text('🎵', style: TextStyle(fontSize: 18))));
}
