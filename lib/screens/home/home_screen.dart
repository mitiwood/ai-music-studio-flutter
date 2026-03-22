import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../create/create_screen.dart';
import '../community/community_screen.dart';
import '../community/library_screen.dart';
import 'notifications_screen.dart';
import 'settings_screen.dart';
import '../../widgets/mini_player.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _screens = [
    CreateScreen(),
    CommunityScreen(),
    LibraryScreen(),
    NotificationsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: provider.currentTab, children: _screens),
          const Positioned(left: 0, right: 0, bottom: 56, child: MiniPlayer()),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: provider.currentTab,
        onTap: provider.setTab,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.music_note), label: '만들기'),
          BottomNavigationBarItem(icon: Icon(Icons.explore), label: '커뮤니티'),
          BottomNavigationBarItem(icon: Icon(Icons.library_music), label: '보관함'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_outlined), label: '알림'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '설정'),
        ],
      ),
    );
  }
}
