import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';

/// 백그라운드 메시지 핸들러 (top-level function 필수)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  debugPrint('[PushService] 백그라운드 메시지: ${message.messageId}');
}

/// FCM 푸시 알림 서비스
/// Firebase가 설정되지 않은 경우(google-services.json 미존재)에도
/// 앱이 정상 동작하도록 모든 호출을 try/catch로 감쌈
class PushService {
  static bool _initialized = false;
  static String? _fcmToken;

  static String? get fcmToken => _fcmToken;
  static bool get isInitialized => _initialized;

  /// Firebase 초기화 및 FCM 설정
  static Future<void> initialize() async {
    try {
      await Firebase.initializeApp();

      // 백그라운드 핸들러 등록
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;

      // 알림 권한 요청
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      debugPrint('[PushService] 알림 권한: ${settings.authorizationStatus}');

      // FCM 토큰 가져오기
      _fcmToken = await messaging.getToken();
      debugPrint('[PushService] FCM Token: $_fcmToken');

      // 토큰을 서버에 등록
      if (_fcmToken != null) {
        await _registerToken(_fcmToken!);
      }

      // 토큰 갱신 리스너
      messaging.onTokenRefresh.listen((String token) async {
        _fcmToken = token;
        await _registerToken(token);
      });

      // 포그라운드 메시지 핸들러
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[PushService] 포그라운드 메시지: ${message.notification?.title}');
      });

      // 알림 클릭 핸들러
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('[PushService] 알림 클릭: ${message.data}');
      });

      _initialized = true;
      debugPrint('[PushService] FCM 초기화 성공');
    } catch (e) {
      debugPrint('[PushService] FCM 초기화 실패 (Firebase 미설정): $e');
      // Firebase 미설정 시 앱이 정상 동작하도록 무시
    }
  }

  /// FCM 토큰을 서버에 등록
  static Future<void> _registerToken(String token) async {
    try {
      await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/api/push-subscribe'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'platform': 'android',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        }),
      );
      debugPrint('[PushService] 토큰 서버 등록 완료');
    } catch (e) {
      debugPrint('[PushService] 토큰 서버 등록 실패: $e');
    }
  }
}
