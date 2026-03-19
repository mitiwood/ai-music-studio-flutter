import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../models/track.dart';
import '../../providers/app_provider.dart';
import '../../widgets/track_card.dart';
import '../player/player_screen.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _genres = ['전체', 'pop', 'rock', 'hip-hop', 'r&b', 'electronic', 'ballad', 'k-pop', 'jazz', 'indie'];
  final _genreLabels = {
    '전체': '전체', 'pop': '팝', 'rock': '록', 'hip-hop': '힙합', 'r&b': 'R&B',
    'electronic': '일렉', 'ballad': '발라드', 'k-pop': 'K-POP', 'jazz': '재즈', 'indie': '인디',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadCommunityTracks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kenny's Music Studio",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AppProvider>().loadCommunityTracks(),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          if (provider.tracksLoading && provider.communityTracks.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.accent));
          }

          final tracks = provider.filteredTracks;
          final hero = provider.heroTrack;

          return RefreshIndicator(
            color: AppTheme.accent,
            onRefresh: () => provider.loadCommunityTracks(),
            child: CustomScrollView(
              slivers: [
                // Hero track card
                if (hero != null)
                  SliverToBoxAdapter(
                    child: _HeroTrackCard(
                      track: hero,
                      onPlay: () {
                        provider.playTrack(hero);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => PlayerScreen(track: hero)),
                        );
                      },
                    ),
                  ),
                // Genre filter chips
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 44,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      itemCount: _genres.length,
                      itemBuilder: (ctx, i) {
                        final genre = _genres[i];
                        final selected = (provider.selectedGenre ?? '전체') == genre;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => provider.setGenreFilter(genre),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              decoration: BoxDecoration(
                                color: selected ? AppTheme.accent : AppTheme.card,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: selected ? AppTheme.accent : AppTheme.border,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _genreLabels[genre] ?? genre,
                                  style: TextStyle(
                                    color: selected ? Colors.white : AppTheme.textSecondary,
                                    fontSize: 12,
                                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 8)),
                // Track list
                if (tracks.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.music_off, size: 48, color: AppTheme.textTertiary),
                          const SizedBox(height: 12),
                          Text('해당 장르의 음악이 없어요',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                        ],
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => TrackCard(
                          track: tracks[i],
                          onPlay: () {
                            provider.playTrack(tracks[i]);
                          },
                          onLike: () => provider.likeTrack(tracks[i].id),
                          onTap: () {
                            provider.playTrack(tracks[i]);
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => PlayerScreen(track: tracks[i])),
                            );
                          },
                        ),
                        childCount: tracks.length,
                      ),
                    ),
                  ),
                // Bottom padding for mini player
                const SliverToBoxAdapter(child: SizedBox(height: 80)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HeroTrackCard extends StatelessWidget {
  final Track track;
  final VoidCallback onPlay;

  const _HeroTrackCard({required this.track, required this.onPlay});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [AppTheme.accent2, AppTheme.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            if (track.imageUrl.isNotEmpty)
              Positioned.fill(
                child: Opacity(
                  opacity: 0.25,
                  child: Image.network(track.imageUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox()),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Art
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.black26,
                      image: track.imageUrl.isNotEmpty
                          ? DecorationImage(
                              image: NetworkImage(track.imageUrl),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: track.imageUrl.isEmpty
                        ? const Center(child: Icon(Icons.music_note, color: Colors.white54, size: 32))
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'HOT',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          track.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          track.ownerName,
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.favorite, size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text('${track.likes}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            const SizedBox(width: 12),
                            const Icon(Icons.play_arrow, size: 14, color: Colors.white70),
                            const SizedBox(width: 4),
                            Text('${track.plays}',
                                style: const TextStyle(color: Colors.white70, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: onPlay,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.play_arrow, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
