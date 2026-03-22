import 'package:flutter/material.dart';
import '../../config/theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(padding: EdgeInsets.fromLTRB(20, 16, 20, 16), child: Text('알림', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800))),
            const Expanded(
              child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.notifications_none, size: 48, color: AppTheme.t3),
                SizedBox(height: 12),
                Text('새로운 알림이 없어요', style: TextStyle(fontSize: 14, color: AppTheme.t3)),
              ])),
            ),
          ],
        ),
      ),
    );
  }
}
