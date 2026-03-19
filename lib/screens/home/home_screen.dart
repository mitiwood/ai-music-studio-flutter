import 'package:flutter/material.dart';
import '../../config/theme.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.music_note), label: '커뮤니티'),
            BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: '만들기'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '프로필'),
          ],
        ),
      ),
    );
  }
}
