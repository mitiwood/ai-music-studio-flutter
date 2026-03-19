import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/app_provider.dart';
import '../../widgets/mini_player.dart';
import '../community/community_screen.dart';
import '../create/create_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final _screens = const [
    CommunityScreen(),
    CreateScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAnnouncement();
    });
  }

  Future<void> _checkAnnouncement() async {
    final provider = context.read<AppProvider>();
    await provider.checkAnnouncement();
    if (!mounted) return;
    final ann = provider.announcement;
    if (ann != null) {
      _showAnnouncementDialog(ann);
    }
  }

  void _showAnnouncementDialog(Map<String, dynamic> ann) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.campaign, color: AppTheme.yellow, size: 22),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                ann['title'] ?? '공지사항',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          ann['content'] ?? ann['message'] ?? '',
          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () {
              context.read<AppProvider>().dismissAnnouncement();
              Navigator.pop(ctx);
            },
            child: const Text('확인', style: TextStyle(color: AppTheme.accent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _screens[_currentIndex],
          // Mini player overlay
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: MiniPlayer(),
          ),
        ],
      ),
      bottomNavigationBar: Consumer<AppProvider>(
        builder: (context, provider, _) {
          return Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
            ),
            // Add padding at bottom if mini player is showing
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (provider.currentPlayingTrack != null)
                  const SizedBox(height: 64), // space for mini player
                BottomNavigationBar(
                  currentIndex: _currentIndex,
                  onTap: (i) => setState(() => _currentIndex = i),
                  items: const [
                    BottomNavigationBarItem(icon: Icon(Icons.music_note), label: '커뮤니티'),
                    BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: '만들기'),
                    BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '프로필'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
