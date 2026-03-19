import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/user.dart';

/// 소셜 로그인 서비스
class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Google 네이티브 로그인
  static Future<AppUser?> loginWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null; // 사용자가 취소함

      final user = AppUser(
        name: account.displayName ?? '구글 사용자',
        provider: 'google',
        email: account.email,
        avatar: account.photoUrl ?? '',
      );

      // 서버에 사용자 정보 저장
      try {
        await http.post(
          Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.apiUsers}'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'name': user.name,
            'provider': user.provider,
            'email': user.email,
            'avatar': user.avatar,
            'lastLogin': DateTime.now().millisecondsSinceEpoch,
            'loginCount': 1,
          }),
        );
      } catch (_) {
        // 서버 저장 실패해도 로그인은 진행
      }

      return user;
    } catch (e) {
      return null;
    }
  }

  /// Google 로그아웃
  static Future<void> logoutGoogle() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}
