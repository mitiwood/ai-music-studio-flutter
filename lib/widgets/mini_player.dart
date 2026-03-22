import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../config/theme.dart';
import '../providers/app_provider.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final audio = provider.audio;
    if (audio.currentTrackId == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppTheme.card, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        StreamBuilder<Duration>(stream: audio.positionStream, builder: (_, posSnap) {
          return StreamBuilder<Duration?>(stream: audio.durationStream, builder: (_, durSnap) {
            final pos = posSnap.data?.inMilliseconds.toDouble() ?? 0;
            final dur = durSnap.data?.inMilliseconds.toDouble() ?? 1;
            return ClipRRect(borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              child: LinearProgressIndicator(value: dur > 0 ? (pos / dur).clamp(0, 1) : 0, minHeight: 3, backgroundColor: AppTheme.border, valueColor: const AlwaysStoppedAnimation(AppTheme.primary)));
          });
        }),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), child: Row(children: [
          ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 40, height: 40,
            child: audio.currentImageUrl != null
              ? CachedNetworkImage(imageUrl: audio.currentImageUrl!, fit: BoxFit.cover, errorWidget: (_, __, ___) => _ph()) : _ph())),
          const SizedBox(width: 10),
          Expanded(child: Text(audio.currentTitle ?? '재생 중', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis)),
          StreamBuilder<bool>(stream: audio.playingStream, builder: (_, snap) {
            final playing = snap.data ?? false;
            return IconButton(icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 32), onPressed: () => playing ? audio.pause() : audio.resume());
          }),
          IconButton(icon: const Icon(Icons.close, size: 20, color: AppTheme.t3), onPressed: () { audio.stop(); }),
        ])),
      ]),
    );
  }
  Widget _ph() => Container(color: AppTheme.bg3, child: const Center(child: Text('🎵', style: TextStyle(fontSize: 16))));
}
