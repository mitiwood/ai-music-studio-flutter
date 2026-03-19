import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:kakao_flutter_sdk_user/kakao_flutter_sdk_user.dart' as kakao;
import 'package:flutter_naver_login/flutter_naver_login.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/user.dart';

/// 소셜 로그인 서비스
class AuthService {
  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Kakao SDK 초기화 (main.dart에서 호출)
  static void initKakao() {
    kakao.KakaoSdk.init(nativeAppKey: const String.fromEnvironment('KAKAO_NATIVE_KEY', defaultValue: ''));
  }

  /// Google 네이티브 로그인
  static Future<AppUser?> loginWithGoogle() async {
    try {
      final account = await _googleSignIn.signIn();
      if (account == null) return null;

      final user = AppUser(
        name: account.displayName ?? '구글 사용자',
        provider: 'google',
        email: account.email,
        avatar: account.photoUrl ?? '',
      );

      await _saveUserToServer(user);
      return user;
    } catch (e) {
      return null;
    }
  }

  /// Kakao 네이티브 로그인
  static Future<AppUser?> loginWithKakao() async {
    try {
      // 카카오톡 설치 여부에 따라 로그인 방식 결정
      bool isKakaoTalkInstalled = await kakao.isKakaoTalkInstalled();

      kakao.OAuthToken token;
      if (isKakaoTalkInstalled) {
        token = await kakao.UserApi.instance.loginWithKakaoTalk();
      } else {
        token = await kakao.UserApi.instance.loginWithKakaoAccount();
      }

      if (token.accessToken.isEmpty) return null;

      // 사용자 정보 가져오기
      kakao.User kakaoUser = await kakao.UserApi.instance.me();

      final user = AppUser(
        name: kakaoUser.kakaoAccount?.profile?.nickname ?? '카카오 사용자',
        provider: 'kakao',
        email: kakaoUser.kakaoAccount?.email ?? '',
        avatar: kakaoUser.kakaoAccount?.profile?.thumbnailImageUrl ?? '',
      );

      await _saveUserToServer(user);
      return user;
    } catch (e) {
      return null;
    }
  }

  /// Naver 네이티브 로그인
  static Future<AppUser?> loginWithNaver() async {
    try {
      final result = await FlutterNaverLogin.logIn();
      if (result.status == NaverLoginStatus.error) return null;

      final account = await FlutterNaverLogin.currentAccount();

      final user = AppUser(
        name: account.name.isNotEmpty ? account.name : (account.nickname.isNotEmpty ? account.nickname : '네이버 사용자'),
        provider: 'naver',
        email: account.email,
        avatar: account.profileImage,
      );

      await _saveUserToServer(user);
      return user;
    } catch (e) {
      return null;
    }
  }

  /// 서버에 사용자 정보 저장
  static Future<void> _saveUserToServer(AppUser user) async {
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
    } catch (_) {}
  }

  /// Google 로그아웃
  static Future<void> logoutGoogle() async {
    try { await _googleSignIn.signOut(); } catch (_) {}
  }

  /// Kakao 로그아웃
  static Future<void> logoutKakao() async {
    try { await kakao.UserApi.instance.logout(); } catch (_) {}
  }

  /// Naver 로그아웃
  static Future<void> logoutNaver() async {
    try { await FlutterNaverLogin.logOut(); } catch (_) {}
  }

  /// 전체 로그아웃
  static Future<void> logoutAll() async {
    await Future.wait([logoutGoogle(), logoutKakao(), logoutNaver()]);
  }
}
