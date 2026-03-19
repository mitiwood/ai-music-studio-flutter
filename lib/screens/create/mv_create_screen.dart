import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/track.dart';
import '../../providers/app_provider.dart';

class MvCreateScreen extends StatefulWidget {
  const MvCreateScreen({super.key});
  @override
  State<MvCreateScreen> createState() => _MvCreateScreenState();
}

class _MvCreateScreenState extends State<MvCreateScreen> {
  Track? _selectedTrack;
  bool _generating = false;
  String? _error;
  String _mvStyle = 'cinematic';

  final _styles = {
    'cinematic': {'label': '시네마틱', 'icon': Icons.movie, 'desc': '영화 같은 분위기'},
    'anime': {'label': '애니메이션', 'icon': Icons.animation, 'desc': '일본 애니메이션 스타일'},
    'abstract': {'label': '추상적', 'icon': Icons.blur_on, 'desc': '색감 중심 추상 영상'},
    'lyric_video': {'label': '가사 영상', 'icon': Icons.text_fields, 'desc': '가사가 화면에 표시'},
    'retro': {'label': '레트로', 'icon': Icons.filter_vintage, 'desc': '80~90년대 감성'},
    'nature': {'label': '자연', 'icon': Icons.landscape, 'desc': '자연 풍경 배경'},
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().loadMyTracks();
    });
  }

  Future<void> _generateMV() async {
    if (_selectedTrack == null) {
      setState(() => _error = '음악을 먼저 선택해주세요');
      return;
    }

    setState(() { _generating = true; _error = null; });

    try {
      final r = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.apiKieProxy}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': _selectedTrack!.title,
          'gen_mode': 'mv',
          'audio_url': _selectedTrack!.audioUrl,
          'mv_style': _mvStyle,
          'lyrics': _selectedTrack!.lyrics,
          'tags': _selectedTrack!.tags,
          'owner_name': _selectedTrack!.ownerName,
          'owner_provider': _selectedTrack!.ownerProvider,
          'owner_avatar': _selectedTrack!.ownerAvatar,
        }),
      );

      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data['track'] != null && mounted) {
          await context.read<AppProvider>().loadCommunityTracks();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('뮤직비디오가 생성되었습니다!'), backgroundColor: AppTheme.green),
            );
            Navigator.pop(context);
          }
          return;
        }
      }
      setState(() => _error = 'MV 생성에 실패했습니다');
    } catch (e) {
      setState(() => _error = '네트워크 오류가 발생했습니다');
    }

    setState(() => _generating = false);
  }

  void _showTrackPicker() {
    final provider = context.read<AppProvider>();
    final tracks = provider.communityTracks.where((t) => t.audioUrl.isNotEmpty && !t.hasMV).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bg2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, sc) => Column(children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: AppTheme.border, borderRadius: BorderRadius.circular(2)),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('음악 선택', style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          Expanded(
            child: tracks.isEmpty
                ? const Center(child: Text('MV를 만들 수 있는 트랙이 없습니다', style: TextStyle(color: AppTheme.textTertiary)))
                : ListView.builder(
                    controller: sc,
                    itemCount: tracks.length,
                    itemBuilder: (ctx, i) {
                      final t = tracks[i];
                      final selected = _selectedTrack?.id == t.id;
                      return ListTile(
                        leading: Container(
                          width: 44, height: 44,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: AppTheme.bg3,
                            image: t.imageUrl.isNotEmpty ? DecorationImage(image: NetworkImage(t.imageUrl), fit: BoxFit.cover) : null,
                          ),
                          child: t.imageUrl.isEmpty ? const Icon(Icons.music_note, color: AppTheme.textTertiary, size: 20) : null,
                        ),
                        title: Text(t.title, style: TextStyle(color: selected ? AppTheme.accent : AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text(t.ownerName, style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
                        trailing: selected ? const Icon(Icons.check_circle, color: AppTheme.accent) : null,
                        onTap: () {
                          setState(() => _selectedTrack = t);
                          Navigator.pop(ctx);
                        },
                      );
                    },
                  ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('뮤직비디오', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.yellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.yellow.withValues(alpha: 0.2)),
            ),
            child: const Row(children: [
              Icon(Icons.videocam, color: AppTheme.yellow, size: 24),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AI 뮤직비디오 생성', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                SizedBox(height: 2),
                Text('음악에 맞는 뮤직비디오를 AI가 자동으로 만들어요', style: TextStyle(color: AppTheme.textTertiary, fontSize: 11)),
              ])),
            ]),
          ),
          const SizedBox(height: 24),

          // Track selector
          const Text('음악 선택', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _showTrackPicker,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.bg3,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _selectedTrack != null ? AppTheme.accent : AppTheme.border),
              ),
              child: _selectedTrack != null
                  ? Row(children: [
                      Container(
                        width: 40, height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: AppTheme.card,
                          image: _selectedTrack!.imageUrl.isNotEmpty
                              ? DecorationImage(image: NetworkImage(_selectedTrack!.imageUrl), fit: BoxFit.cover) : null,
                        ),
                        child: _selectedTrack!.imageUrl.isEmpty ? const Icon(Icons.music_note, size: 18, color: AppTheme.textTertiary) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_selectedTrack!.title, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(_selectedTrack!.ownerName, style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12)),
                      ])),
                      const Icon(Icons.swap_horiz, color: AppTheme.accent, size: 20),
                    ])
                  : const Row(children: [
                      Icon(Icons.add_circle_outline, color: AppTheme.textTertiary, size: 22),
                      SizedBox(width: 10),
                      Text('MV를 만들 음악을 선택하세요', style: TextStyle(color: AppTheme.textTertiary, fontSize: 13)),
                    ]),
            ),
          ),
          const SizedBox(height: 24),

          // MV style
          const Text('영상 스타일', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _styles.entries.map((e) {
              final selected = _mvStyle == e.key;
              return GestureDetector(
                onTap: () => setState(() => _mvStyle = e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? AppTheme.accent.withValues(alpha: 0.15) : AppTheme.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: selected ? AppTheme.accent : AppTheme.border),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(e.value['icon'] as IconData, size: 16, color: selected ? AppTheme.accent : AppTheme.textTertiary),
                    const SizedBox(width: 6),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(e.value['label'] as String, style: TextStyle(color: selected ? AppTheme.accent : AppTheme.textPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(e.value['desc'] as String, style: const TextStyle(color: AppTheme.textTertiary, fontSize: 10)),
                    ]),
                  ]),
                ),
              );
            }).toList(),
          ),

          if (_error != null) ...[
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: AppTheme.red, fontSize: 13)),
          ],

          const SizedBox(height: 32),

          // Generate button
          ElevatedButton.icon(
            onPressed: _generating ? null : _generateMV,
            icon: _generating
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.auto_awesome, size: 18),
            label: Text(_generating ? 'MV 생성 중...' : '뮤직비디오 생성하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.yellow,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
        ]),
      ),
    );
  }
}
