import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/app_provider.dart';
import '../../models/track.dart';
import '../../widgets/track_card.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  String _filter = 'all';
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadCommunityTracks();
    });
  }

  List<Track> _getFiltered(List<Track> tracks) {
    var list = tracks;
    if (_search.isNotEmpty) {
      list = list.where((t) =>
        t.title.toLowerCase().contains(_search.toLowerCase()) ||
        (t.tags ?? '').toLowerCase().contains(_search.toLowerCase()) ||
        t.ownerName.toLowerCase().contains(_search.toLowerCase())
      ).toList();
    }
    if (_filter == 'popular') {
      list = List.from(list)..sort((a, b) => b.likeCount.compareTo(a.likeCount));
    }
    if (_filter == 'recent') {
      list = List.from(list)..sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final filtered = _getFiltered(provider.communityTracks);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: provider.loadCommunityTracks,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('커뮤니티', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 10),
                  TextField(
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: '곡, 태그, 크리에이터 검색...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true, contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    _filterChip('전체', 'all'), const SizedBox(width: 6),
                    _filterChip('인기', 'popular'), const SizedBox(width: 6),
                    _filterChip('최신', 'recent'),
                  ]),
                ]),
              )),
              // Popular chart (top 5)
              if (_filter == 'all' && _search.isEmpty)
                SliverToBoxAdapter(child: _buildChart(provider.communityTracks)),
              // Track list
              provider.isLoading
                ? const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    sliver: SliverList(delegate: SliverChildBuilderDelegate(
                      (ctx, i) => TrackCard(
                        track: filtered[i],
                      ),
                      childCount: filtered.length,
                    )),
                  ),
              // Bottom padding for mini player
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final active = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          gradient: active ? AppTheme.primaryGradient : null,
          color: active ? null : AppTheme.bg3,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : AppTheme.t3)),
      ),
    );
  }

  Widget _buildChart(List<Track> tracks) {
    final sorted = List<Track>.from(tracks)..sort((a, b) => b.likeCount.compareTo(a.likeCount));
    final top = sorted.take(5).toList();
    if (top.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [AppTheme.yellow.withOpacity(0.06), AppTheme.primary.withOpacity(0.04)]),
        border: Border.all(color: AppTheme.yellow.withOpacity(0.15)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.emoji_events, size: 16, color: AppTheme.yellow),
            const SizedBox(width: 6),
            const Text('인기 차트', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.yellow)),
          ]),
          const SizedBox(height: 10),
          ...top.asMap().entries.map((e) {
            final i = e.key;
            final t = e.value;
            return GestureDetector(
              onTap: () => context.read<AppProvider>().playTrack(t),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(children: [
                  SizedBox(width: 24, child: Text('${i + 1}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: i < 3 ? AppTheme.yellow : AppTheme.t3))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(t.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
                  Icon(Icons.favorite, size: 11, color: AppTheme.t3),
                  const SizedBox(width: 3),
                  Text('${t.likeCount}', style: const TextStyle(fontSize: 11, color: AppTheme.t3)),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }
}
