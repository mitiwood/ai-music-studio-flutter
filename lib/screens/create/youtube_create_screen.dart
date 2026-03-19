import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import '../../config/constants.dart';
import '../../config/theme.dart';
import '../../models/track.dart';
import '../../providers/app_provider.dart';
import '../player/player_screen.dart';

class YoutubeCreateScreen extends StatefulWidget {
  const YoutubeCreateScreen({super.key});
  @override
  State<YoutubeCreateScreen> createState() => _YoutubeCreateScreenState();
}

class _YoutubeCreateScreenState extends State<YoutubeCreateScreen> {
  final _urlController = TextEditingController();
  bool _analyzing = false;
  bool _generating = false;
  Map<String, dynamic>? _analysis;
  String? _error;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  bool _isValidYoutubeUrl(String url) {
    return url.contains('youtube.com/watch') || url.contains('youtu.be/') || url.contains('youtube.com/shorts');
  }

  Future<void> _analyzeUrl() async {
    final url = _urlController.text.trim();
    if (!_isValidYoutubeUrl(url)) {
      setState(() => _error = '올바른 YouTube URL을 입력해주세요');
      return;
    }

    setState(() { _analyzing = true; _error = null; _analysis = null; });

    try {
      final r = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.apiAnalyze}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'url': url, 'type': 'youtube'}),
      );

      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        setState(() => _analysis = data);
      } else {
        setState(() => _error = 'YouTube 분석에 실패했습니다');
      }
    } catch (e) {
      setState(() => _error = '네트워크 오류가 발생했습니다');
    }

    setState(() => _analyzing = false);
  }

  Future<void> _generate() async {
    if (_analysis == null) return;
    setState(() => _generating = true);

    final provider = context.read<AppProvider>();
    final title = _analysis!['title'] ?? 'YouTube 커버';
    final genre = _analysis!['genre'] ?? 'pop';
    final mood = _analysis!['mood'] ?? 'upbeat';

    final track = await provider.generateTrack(
      title: '$title (AI Cover)',
      genre: genre,
      mood: mood,
      mode: 'youtube',
    );

    setState(() => _generating = false);

    if (track != null && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PlayerScreen(track: track)),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('생성에 실패했습니다'), backgroundColor: AppTheme.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube 모드', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTheme.green.withValues(alpha: 0.2)),
            ),
            child: const Row(children: [
              Icon(Icons.ondemand_video, color: AppTheme.green, size: 24),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('YouTube URL로 음악 생성', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                SizedBox(height: 2),
                Text('YouTube 영상을 분석해서 비슷한 느낌의 AI 음악을 만들어요', style: TextStyle(color: AppTheme.textTertiary, fontSize: 11)),
              ])),
            ]),
          ),
          const SizedBox(height: 24),

          // URL Input
          const Text('YouTube URL', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'https://youtube.com/watch?v=...',
              hintStyle: const TextStyle(color: AppTheme.textTertiary, fontSize: 13),
              filled: true,
              fillColor: AppTheme.bg3,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppTheme.green)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, size: 18, color: AppTheme.textTertiary),
                onPressed: () => _urlController.clear(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Analyze button
          ElevatedButton.icon(
            onPressed: _analyzing ? null : _analyzeUrl,
            icon: _analyzing
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.search, size: 18),
            label: Text(_analyzing ? '분석 중...' : '영상 분석하기'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),

          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppTheme.red, fontSize: 13)),
          ],

          // Analysis result
          if (_analysis != null) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('분석 결과', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 12),
                _AnalysisRow(label: '제목', value: _analysis!['title'] ?? '-'),
                _AnalysisRow(label: '장르', value: _analysis!['genre'] ?? '-'),
                _AnalysisRow(label: '분위기', value: _analysis!['mood'] ?? '-'),
                _AnalysisRow(label: 'BPM', value: '${_analysis!['bpm'] ?? '-'}'),
                if (_analysis!['tags'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Wrap(
                      spacing: 6, runSpacing: 6,
                      children: (_analysis!['tags'] as String).split(',').map((tag) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(tag.trim(), style: const TextStyle(color: AppTheme.green, fontSize: 11, fontWeight: FontWeight.w600)),
                      )).toList(),
                    ),
                  ),
              ]),
            ),
            const SizedBox(height: 20),

            // Generate button
            ElevatedButton.icon(
              onPressed: _generating ? null : _generate,
              icon: _generating
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome, size: 18),
              label: Text(_generating ? '생성 중...' : 'AI 음악 생성하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
              ),
            ),
          ],
        ]),
      ),
    );
  }
}

class _AnalysisRow extends StatelessWidget {
  final String label, value;
  const _AnalysisRow({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(width: 60, child: Text(label, style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12))),
        Expanded(child: Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}
