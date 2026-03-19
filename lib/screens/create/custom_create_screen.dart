import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/app_provider.dart';
import '../player/player_screen.dart';

class CustomCreateScreen extends StatefulWidget {
  const CustomCreateScreen({super.key});

  @override
  State<CustomCreateScreen> createState() => _CustomCreateScreenState();
}

class _CustomCreateScreenState extends State<CustomCreateScreen>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  final _lyricsController = TextEditingController();
  String _selectedGenre = 'pop';
  String _selectedMood = 'upbeat';
  double _bpm = 120;
  bool _vocal = true;
  bool _showPreview = false;
  late AnimationController _pulseController;

  final _genres = ['pop', 'rock', 'hip-hop', 'r&b', 'electronic', 'jazz', 'classical', 'ballad', 'indie', 'k-pop'];
  final _moods = ['upbeat', 'chill', 'sad', 'romantic', 'energetic', 'dark', 'dreamy', 'epic', 'happy', 'melancholy'];

  final _genreLabels = {
    'pop': '팝', 'rock': '록', 'hip-hop': '힙합', 'r&b': 'R&B',
    'electronic': '일렉트로닉', 'jazz': '재즈', 'classical': '클래식',
    'ballad': '발라드', 'indie': '인디', 'k-pop': 'K-POP',
  };

  final _moodLabels = {
    'upbeat': '신나는', 'chill': '편안한', 'sad': '슬픈', 'romantic': '로맨틱',
    'energetic': '에너지틱', 'dark': '다크', 'dreamy': '몽환적',
    'epic': '웅장한', 'happy': '행복한', 'melancholy': '멜랑콜리',
  };

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _lyricsController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String get _promptPreview {
    final parts = <String>[];
    parts.add('제목: ${_titleController.text.isNotEmpty ? _titleController.text : "(미입력)"}');
    parts.add('장르: ${_genreLabels[_selectedGenre] ?? _selectedGenre}');
    parts.add('분위기: ${_moodLabels[_selectedMood] ?? _selectedMood}');
    parts.add('BPM: ${_bpm.toInt()}');
    parts.add('보컬: ${_vocal ? "있음" : "없음 (인스트루멘탈)"}');
    if (_lyricsController.text.trim().isNotEmpty) {
      parts.add('가사: ${_lyricsController.text.trim().substring(0, _lyricsController.text.trim().length.clamp(0, 50))}...');
    }
    return parts.join('\n');
  }

  Future<void> _generate() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('제목을 입력해주세요'), backgroundColor: AppTheme.red),
      );
      return;
    }

    final provider = context.read<AppProvider>();
    final result = await provider.generateTrack(
      title: title,
      lyrics: _lyricsController.text.trim(),
      genre: _selectedGenre,
      mood: _selectedMood,
      bpm: _bpm.toInt(),
      vocal: _vocal,
      mode: 'custom',
    );

    if (!mounted) return;

    if (result != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('음악이 생성되었습니다!'), backgroundColor: AppTheme.green),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => PlayerScreen(track: result)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('생성에 실패했습니다. 다시 시도해주세요.'), backgroundColor: AppTheme.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        title: const Text('커스텀 모드', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        backgroundColor: AppTheme.bg2,
      ),
      body: provider.generating
          ? _buildLoadingView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Credit
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt, color: AppTheme.yellow, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '크레딧: ${provider.credits}',
                          style: const TextStyle(color: AppTheme.accent, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title
                  _sectionLabel('곡 제목'),
                  const SizedBox(height: 8),
                  _textField(_titleController, '만들고 싶은 음악의 제목'),
                  const SizedBox(height: 20),

                  // Lyrics
                  _sectionLabel('가사 (선택)'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _lyricsController,
                    maxLines: 6,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                    decoration: _inputDecoration('가사를 직접 입력하세요 (선택사항)'),
                  ),
                  const SizedBox(height: 20),

                  // Genre dropdown
                  _sectionLabel('장르'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedGenre,
                        isExpanded: true,
                        dropdownColor: AppTheme.card2,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        items: _genres.map((g) => DropdownMenuItem(
                          value: g,
                          child: Text(_genreLabels[g] ?? g),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedGenre = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Mood dropdown
                  _sectionLabel('분위기'),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedMood,
                        isExpanded: true,
                        dropdownColor: AppTheme.card2,
                        style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                        items: _moods.map((m) => DropdownMenuItem(
                          value: m,
                          child: Text(_moodLabels[m] ?? m),
                        )).toList(),
                        onChanged: (v) => setState(() => _selectedMood = v!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // BPM slider
                  _sectionLabel('BPM: ${_bpm.toInt()}'),
                  const SizedBox(height: 8),
                  SliderTheme(
                    data: SliderThemeData(
                      activeTrackColor: AppTheme.accent,
                      inactiveTrackColor: AppTheme.bg3,
                      thumbColor: AppTheme.accent,
                      overlayColor: AppTheme.accent.withValues(alpha: 0.2),
                      valueIndicatorColor: AppTheme.accent,
                      valueIndicatorTextStyle: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    child: Slider(
                      value: _bpm,
                      min: 60,
                      max: 200,
                      divisions: 28,
                      label: '${_bpm.toInt()} BPM',
                      onChanged: (v) => setState(() => _bpm = v),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      Text('60', style: TextStyle(color: AppTheme.textTertiary, fontSize: 11)),
                      Text('200', style: TextStyle(color: AppTheme.textTertiary, fontSize: 11)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Vocal toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('보컬', style: TextStyle(color: AppTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                            Text(
                              _vocal ? '보컬 포함' : '인스트루멘탈',
                              style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                            ),
                          ],
                        ),
                        Switch(
                          value: _vocal,
                          onChanged: (v) => setState(() => _vocal = v),
                          activeColor: AppTheme.accent,
                          inactiveTrackColor: AppTheme.bg3,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Prompt preview
                  GestureDetector(
                    onTap: () => setState(() => _showPreview = !_showPreview),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppTheme.bg3,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _showPreview ? Icons.expand_less : Icons.expand_more,
                            color: AppTheme.textSecondary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text('프롬프트 미리보기',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                  if (_showPreview)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        _promptPreview,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                          fontFamily: 'monospace',
                          height: 1.6,
                        ),
                      ),
                    ),
                  const SizedBox(height: 28),

                  // Generate button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _generate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, size: 20),
                          SizedBox(width: 8),
                          Text('커스텀 음악 생성', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700));
  }

  Widget _textField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
      decoration: _inputDecoration(hint),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppTheme.textTertiary, fontSize: 14),
      filled: true,
      fillColor: AppTheme.card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.accent),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + _pulseController.value * 0.15,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.accent2.withValues(alpha: 0.3),
                        AppTheme.accent2.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.tune, size: 40, color: AppTheme.accent2),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          const Text(
            'AI가 커스텀 음악을 만들고 있어요...',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            '세밀한 설정으로 생성 중이에요',
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(color: AppTheme.accent2, strokeWidth: 3),
          ),
        ],
      ),
    );
  }
}
