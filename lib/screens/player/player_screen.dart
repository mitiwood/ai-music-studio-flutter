import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/track.dart';
import '../../providers/app_provider.dart';
import '../../utils/share_utils.dart';
import '../../widgets/comment_section.dart';

class PlayerScreen extends StatefulWidget {
  final Track track;
  const PlayerScreen({super.key, required this.track});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _showLyrics = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    // Auto-play if not already playing this track
    if (provider.audioService.currentTrackId != widget.track.id) {
      provider.playTrack(widget.track);
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final audio = provider.audioService;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.keyboard_arrow_down, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('재생 중', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, size: 22),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            // Album art
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: AppTheme.bg3,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                    image: widget.track.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(widget.track.imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: widget.track.imageUrl.isEmpty
                      ? const Center(
                          child: Icon(Icons.music_note, size: 64, color: AppTheme.accent),
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 28),
            // Title & artist
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    widget.track.title,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.track.ownerName,
                    style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Seek bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: StreamBuilder<Duration>(
                stream: audio.positionStream,
                builder: (context, posSnap) {
                  return StreamBuilder<Duration?>(
                    stream: audio.durationStream,
                    builder: (context, durSnap) {
                      final pos = posSnap.data ?? Duration.zero;
                      final dur = durSnap.data ?? Duration.zero;
                      final maxVal = dur.inMilliseconds.toDouble();

                      return Column(
                        children: [
                          SliderTheme(
                            data: SliderThemeData(
                              trackHeight: 3,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                              activeTrackColor: AppTheme.accent,
                              inactiveTrackColor: AppTheme.bg3,
                              thumbColor: AppTheme.accent,
                              overlayColor: AppTheme.accent.withValues(alpha: 0.2),
                            ),
                            child: Slider(
                              value: maxVal > 0
                                  ? pos.inMilliseconds.toDouble().clamp(0, maxVal)
                                  : 0,
                              max: maxVal > 0 ? maxVal : 1,
                              onChanged: (v) {
                                audio.seek(Duration(milliseconds: v.toInt()));
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatDuration(pos),
                                    style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
                                Text(_formatDuration(dur),
                                    style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            // Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Like
                IconButton(
                  icon: const Icon(Icons.favorite_border, color: AppTheme.red),
                  iconSize: 28,
                  onPressed: () => provider.likeTrack(widget.track.id),
                ),
                const SizedBox(width: 16),
                // Play/Pause
                StreamBuilder<bool>(
                  stream: audio.playingStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data ?? false;
                    return GestureDetector(
                      onTap: () {
                        if (isPlaying) {
                          audio.pause();
                        } else {
                          audio.resume();
                        }
                      },
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: const BoxDecoration(
                          color: AppTheme.accent,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                // Share
                IconButton(
                  icon: const Icon(Icons.share_outlined, color: AppTheme.textSecondary),
                  iconSize: 28,
                  onPressed: () => ShareUtils.shareTrack(widget.track),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Lyrics toggle
            if (widget.track.lyrics.isNotEmpty)
              Column(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _showLyrics = !_showLyrics),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: _showLyrics
                            ? AppTheme.accent.withValues(alpha: 0.15)
                            : AppTheme.bg3,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _showLyrics ? AppTheme.accent.withValues(alpha: 0.3) : AppTheme.border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showLyrics ? Icons.lyrics : Icons.lyrics_outlined,
                            size: 16,
                            color: _showLyrics ? AppTheme.accent : AppTheme.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _showLyrics ? '가사 숨기기' : '가사 보기',
                            style: TextStyle(
                              color: _showLyrics ? AppTheme.accent : AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_showLyrics)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.bg3,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Text(
                        widget.track.lyrics,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 14,
                          height: 1.8,
                        ),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 16),
            const Divider(color: AppTheme.border),
            // Comments
            CommentSection(trackId: widget.track.id),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
