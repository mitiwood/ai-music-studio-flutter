import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/app_provider.dart';
import '../player/player_screen.dart';

class SimpleCreateScreen extends StatefulWidget {
  const SimpleCreateScreen({super.key});

  @override
  State<SimpleCreateScreen> createState() => _SimpleCreateScreenState();
}

class _SimpleCreateScreenState extends State<SimpleCreateScreen>
    with SingleTickerProviderStateMixin {
  final _titleController = TextEditingController();
  String _selectedGenre = 'pop';
  String _selectedMood = 'upbeat';
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
    _pulseController.dispose();
    super.dispose();
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
      genre: _selectedGenre,
      mood: _selectedMood,
      mode: 'simple',
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
        title: const Text('심플 모드', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        backgroundColor: AppTheme.bg2,
      ),
      body: provider.generating
          ? _buildLoadingView()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Credit display
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
                  const SizedBox(height: 24),
                  // Title
                  const Text('곡 제목', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: '만들고 싶은 음악의 제목을 입력하세요',
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
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Genre chips
                  const Text('장르', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _genres.map((g) => _buildChip(
                      label: _genreLabels[g] ?? g,
                      selected: _selectedGenre == g,
                      onTap: () => setState(() => _selectedGenre = g),
                    )).toList(),
                  ),
                  const SizedBox(height: 24),
                  // Mood chips
                  const Text('분위기', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _moods.map((m) => _buildChip(
                      label: _moodLabels[m] ?? m,
                      selected: _selectedMood == m,
                      onTap: () => setState(() => _selectedMood = m),
                    )).toList(),
                  ),
                  const SizedBox(height: 36),
                  // Generate button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _generate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome, size: 20),
                          SizedBox(width: 8),
                          Text('AI 음악 생성', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildChip({required String label, required bool selected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.accent.withValues(alpha: 0.2) : AppTheme.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.accent : AppTheme.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppTheme.accent : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
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
                        AppTheme.accent.withValues(alpha: 0.3),
                        AppTheme.accent.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.music_note, size: 40, color: AppTheme.accent),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 28),
          const Text(
            'AI가 음악을 만들고 있어요...',
            style: TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            '최대 2~3분 정도 소요될 수 있습니다',
            style: TextStyle(color: AppTheme.textTertiary, fontSize: 13),
          ),
          const SizedBox(height: 24),
          const SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 3),
          ),
        ],
      ),
    );
  }
}
