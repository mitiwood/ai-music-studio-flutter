import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/app_provider.dart';
import '../../widgets/track_card.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() { super.initState(); _tabCtrl = TabController(length: 3, vsync: this); }
  @override
  void dispose() { _tabCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, 8), child: Text('보관함', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TabBar(
                controller: _tabCtrl,
                labelColor: AppTheme.primary, unselectedLabelColor: AppTheme.t3,
                indicatorColor: AppTheme.primary,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                tabs: const [Tab(text: '최근 재생'), Tab(text: '내 곡'), Tab(text: '플레이리스트')],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  // History
                  provider.history.isEmpty
                    ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.music_note, size: 40, color: AppTheme.t3),
                        SizedBox(height: 8),
                        Text('재생한 곡이 없어요', style: TextStyle(color: AppTheme.t3)),
                      ]))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: provider.history.length,
                        itemBuilder: (_, i) => TrackCard(
                          track: provider.history[i],
                        ),
                      ),
                  // My tracks
                  RefreshIndicator(
                    onRefresh: provider.loadMyTracks,
                    child: provider.myTracks.isEmpty
                      ? ListView(children: const [SizedBox(height: 100), Center(child: Text('아직 만든 곡이 없어요\n만들기 탭에서 첫 곡을 생성해보세요!', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.t3)))])
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: provider.myTracks.length,
                          itemBuilder: (_, i) => TrackCard(
                            track: provider.myTracks[i],
                          ),
                        ),
                  ),
                  // Playlists
                  const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.folder_open, size: 40, color: AppTheme.t3),
                    SizedBox(height: 8),
                    Text('플레이리스트 (준비 중)', style: TextStyle(color: AppTheme.t3)),
                  ])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
