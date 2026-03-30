import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../utils/constants.dart';

/// 로컬 알림 서비스 — 음악 생성 완료, 다운로드 완료, 소셜 알림 등
class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      const InitializationSettings(android: androidSettings, iOS: iosSettings),
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    // Android 알림 채널 생성
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        AppConstants.notifChannelMusic,
        '음악 알림',
        description: '음악 생성 및 다운로드 관련 알림',
        importance: Importance.high,
      ));
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        AppConstants.notifChannelDownload,
        '다운로드',
        description: '파일 다운로드 진행 상황',
        importance: Importance.low,
        showBadge: false,
      ));
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        AppConstants.notifChannelSocial,
        '소셜 알림',
        description: '좋아요, 댓글, 팔로우 알림',
        importance: Importance.defaultImportance,
      ));
    }

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    // 알림 탭 시 딥링크 처리 (payload에 URL 포함)
    // WebView에서 해당 URL로 이동
  }

  /// 음악 생성 완료 알림
  Future<void> showMusicComplete({required String title, String? body}) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body ?? '음악이 생성되었습니다! 탭하여 확인하세요.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notifChannelMusic,
          '음악 알림',
          icon: '@mipmap/ic_launcher',
          priority: Priority.high,
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }

  /// 다운로드 진행 알림
  Future<void> showDownloadProgress({
    required int id,
    required String fileName,
    required int progress,
    required int maxProgress,
  }) async {
    await _plugin.show(
      id,
      '다운로드 중...',
      fileName,
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notifChannelDownload,
          '다운로드',
          icon: '@mipmap/ic_launcher',
          showProgress: true,
          maxProgress: maxProgress,
          progress: progress,
          ongoing: progress < maxProgress,
          autoCancel: progress >= maxProgress,
          priority: Priority.low,
          importance: Importance.low,
        ),
      ),
    );
  }

  /// 다운로드 완료 알림
  Future<void> showDownloadComplete({required String fileName, String? filePath}) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      '다운로드 완료',
      '$fileName 저장 완료',
      NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notifChannelDownload,
          '다운로드',
          icon: '@mipmap/ic_launcher',
          priority: Priority.defaultPriority,
          importance: Importance.defaultImportance,
        ),
      ),
      payload: filePath,
    );
  }

  /// 소셜 알림 (좋아요, 댓글, 팔로우)
  Future<void> showSocialNotification({required String title, required String body, String? payload}) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notifChannelSocial,
          '소셜 알림',
          icon: '@mipmap/ic_launcher',
          priority: Priority.defaultPriority,
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  /// 일반 알림
  Future<void> showGeneral({required String title, required String body, String? payload}) async {
    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          AppConstants.notifChannelGeneral,
          '일반 알림',
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  /// 알림 취소
  Future<void> cancel(int id) => _plugin.cancel(id);
  Future<void> cancelAll() => _plugin.cancelAll();
}
