import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../models/track.dart';
import '../../services/api_service.dart';
import '../../services/audio_service.dart';
import '../../widgets/track_card.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});
  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  List<Track> _tracks = [];
  bool _loading = true;
  final _audio = AudioService();

  @override
  void initState() {
    super.initState();
    _loadTracks();
  }

  Future<void> _loadTracks() async {
    setState(() => _loading = true);
    final tracks = await ApiService.getCommunityTracks();
    if (mounted) setState(() { _tracks = tracks; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kenny's Music Studio",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTracks),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _tracks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('🎵', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      Text('아직 생성된 음악이 없어요', style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('음악 만들기에서 첫 곡을 만들어보세요!', style: TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: AppTheme.accent,
                  onRefresh: _loadTracks,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _tracks.length,
                    itemBuilder: (ctx, i) => TrackCard(
                      track: _tracks[i],
                      onPlay: () => _audio.play(_tracks[i].audioUrl, trackId: _tracks[i].id),
                      onLike: () async {
                        await ApiService.likeTrack(_tracks[i].id);
                        _loadTracks();
                      },
                    ),
                  ),
                ),
    );
  }
}
