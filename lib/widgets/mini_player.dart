import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/app_provider.dart';
import '../screens/player/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final track = provider.currentPlayingTrack;
        if (track == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => PlayerScreen(track: track)),
            );
          },
          child: Container(
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.card2,
              border: const Border(
                top: BorderSide(color: AppTheme.border, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Album art
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppTheme.bg3,
                    image: track.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(track.imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: track.imageUrl.isEmpty
                      ? const Center(
                          child: Icon(Icons.music_note, color: AppTheme.accent, size: 28),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Title
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track.ownerName,
                        style: const TextStyle(
                          color: AppTheme.textTertiary,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                // Play/Pause
                StreamBuilder<bool>(
                  stream: provider.audioService.playingStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data ?? false;
                    return IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        color: AppTheme.textPrimary,
                        size: 28,
                      ),
                      onPressed: () {
                        if (isPlaying) {
                          provider.audioService.pause();
                        } else {
                          provider.audioService.resume();
                        }
                      },
                    );
                  },
                ),
                // Close
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textTertiary, size: 20),
                  onPressed: () => provider.stopPlayback(),
                ),
                const SizedBox(width: 4),
              ],
            ),
          ),
        );
      },
    );
  }
}
