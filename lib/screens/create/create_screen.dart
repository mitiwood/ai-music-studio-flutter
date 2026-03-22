import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/app_provider.dart';
import '../../services/api_service.dart';
import '../../models/track.dart';

class CreateScreen extends StatefulWidget {
  const CreateScreen({super.key});
  @override
  State<CreateScreen> createState() => _CreateScreenState();
}

class _CreateScreenState extends State<CreateScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final _promptCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  String _model = 'chirp-v3-5';
  bool _isGenerating = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() { _tabCtrl.dispose(); _promptCtrl.dispose(); _titleCtrl.dispose(); _tagsCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Text('새 곡 만들기', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
            )),
            // Attendance banner
            SliverToBoxAdapter(child: _buildAttendanceBanner()),
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(color: AppTheme.bg3, borderRadius: BorderRadius.circular(12)),
                child: TabBar(
                  controller: _tabCtrl,
                  indicator: BoxDecoration(borderRadius: BorderRadius.circular(10), gradient: AppTheme.primaryGradient),
                  labelColor: Colors.white, unselectedLabelColor: AppTheme.t3,
                  labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  tabs: const [Tab(text: '커스텀'), Tab(text: '심플'), Tab(text: 'YouTube'), Tab(text: 'MV')],
                ),
              ),
            )),
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabCtrl,
                children: [_buildCustomTab(), _buildSimpleTab(), _buildYoutubeTab(), _buildMvTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceBanner() {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final att = provider.attendance;
        if (att == null || !provider.isLoggedIn) return const SizedBox.shrink();
        final streak = att['streak'] ?? 0;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [AppTheme.yellow.withOpacity(0.08), AppTheme.primary.withOpacity(0.06)]),
            border: Border.all(color: AppTheme.yellow.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(children: [
            const Text('🔥', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Expanded(child: Text('$streak일 연속 출석 중!', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
            GestureDetector(
              onTap: () async {
                final result = await provider.doCheckIn();
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result['ok'] == true ? '출석 완료!' : (result['message'] ?? '이미 출석했어요')),
                ));
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(8)),
                child: const Text('출석', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ]),
        );
      },
    );
  }

  Widget _buildCustomTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('프롬프트'),
          TextField(controller: _promptCtrl, maxLines: 3, decoration: const InputDecoration(hintText: '어떤 음악을 만들까요?\n예: upbeat K-pop with female vocals')),
          const SizedBox(height: 12),
          _label('제목 (선택)'),
          TextField(controller: _titleCtrl, decoration: const InputDecoration(hintText: '곡 제목')),
          const SizedBox(height: 12),
          _label('태그 (선택)'),
          TextField(controller: _tagsCtrl, decoration: const InputDecoration(hintText: 'pop, korean, happy')),
          const SizedBox(height: 12),
          _label('모델'),
          DropdownButtonFormField<String>(
            value: _model, dropdownColor: AppTheme.card,
            decoration: const InputDecoration(),
            items: const [
              DropdownMenuItem(value: 'chirp-v3-5', child: Text('V3.5 (빠른 생성)')),
              DropdownMenuItem(value: 'chirp-v4', child: Text('V4.0 (고품질)')),
            ],
            onChanged: (v) => setState(() => _model = v ?? 'chirp-v3-5'),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isGenerating ? null : _generate,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: EdgeInsets.zero,
              ),
              child: Ink(
                decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(14)),
                child: Center(child: _isGenerating
                  ? Row(mainAxisSize: MainAxisSize.min, children: [const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)), const SizedBox(width: 10), Text(_status.isEmpty ? '생성 중...' : _status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))])
                  : const Text('음악 생성', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white))),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleTab() => const Center(child: Text('프롬프트만 입력하면 AI가 자동으로 작곡합니다', style: TextStyle(color: AppTheme.t3)));
  Widget _buildYoutubeTab() => const Center(child: Text('YouTube URL로 비슷한 곡 생성', style: TextStyle(color: AppTheme.t3)));
  Widget _buildMvTab() => const Center(child: Text('뮤직비디오 생성', style: TextStyle(color: AppTheme.t3)));

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.t2)),
  );

  Future<void> _generate() async {
    final prompt = _promptCtrl.text.trim();
    if (prompt.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('프롬프트를 입력해주세요'))); return; }
    final provider = context.read<AppProvider>();
    if (!provider.isLoggedIn) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('로그인 후 이용 가능합니다'))); return; }

    setState(() { _isGenerating = true; _status = '음악 생성 요청 중...'; });
    try {
      final result = await ApiService.kieRequest('POST', '/api/v1/generate', body: {
        'prompt': prompt, 'model': _model, 'title': _titleCtrl.text.trim(),
        'tags': _tagsCtrl.text.trim(),
        'callBackUrl': 'https://ai-music-studio-bice.vercel.app/api/kie-proxy',
      }, userName: provider.user!.name, userProvider: provider.user!.provider);

      final taskId = result['data']?['taskId'] ?? result['taskId'] ?? '';
      if (taskId.toString().isEmpty) throw Exception('taskId 없음');

      setState(() => _status = '음악 생성 중... (30~90초)');
      for (int i = 0; i < 60; i++) {
        await Future.delayed(Duration(seconds: i < 5 ? 1 : i < 15 ? 2 : 3));
        try {
          final poll = await ApiService.pollResult(taskId.toString());
          final data = poll['data'];
          if (data != null && data['audioUrl'] != null && data['audioUrl'].toString().isNotEmpty) {
            setState(() { _isGenerating = false; _status = ''; });
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${data['title'] ?? '새 곡'}" 생성 완료!')));
            final track = Track.fromJson(data);
            provider.playTrack(track);
            return;
          }
        } catch (_) {}
      }
      throw Exception('생성 시간 초과');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('오류: $e')));
    } finally {
      if (mounted) setState(() { _isGenerating = false; _status = ''; });
    }
  }
}
