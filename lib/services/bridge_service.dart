import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vibration/vibration.dart';
import 'package:image_picker/image_picker.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../utils/constants.dart';
import 'download_service.dart';
import 'notification_service.dart';
import 'storage_service.dart';

/// JS-Flutter 브릿지 서비스
/// 웹앱에서 FlutterBridge.postMessage(JSON) 호출 시 네이티브 기능 실행
///
/// 프로토콜: JSON { "command": "...", "data": { ... } }
///
/// 지원 커맨드:
///   share, download, haptic, clipboard, toast, notification,
///   theme, auth, pickImage, review, appInfo, musicComplete,
///   saveUrl, badge, log
class BridgeService {
  final WebViewController controller;
  final BuildContext Function() contextGetter;
  final DownloadService _download = DownloadService();
  final NotificationService _notif = NotificationService();
  late StorageService _storage;

  BridgeService({required this.controller, required this.contextGetter});

  Future<void> init() async {
    _storage = await StorageService.getInstance();
  }

  /// 브릿지 메시지 핸들러
  Future<void> handleMessage(String rawMessage) async {
    try {
      // 레거시 호환: "share:데이터" 형식
      if (rawMessage.startsWith('share:')) {
        await _handleShare({'text': rawMessage.substring(6)});
        return;
      }

      final Map<String, dynamic> message = json.decode(rawMessage);
      final String command = message['command'] ?? '';
      final Map<String, dynamic> data =
          message['data'] is Map ? Map<String, dynamic>.from(message['data']) : {};

      switch (command) {
        case 'share':
          await _handleShare(data);
        case 'download':
          await _handleDownload(data);
        case 'haptic':
          await _handleHaptic(data);
        case 'clipboard':
          await _handleClipboard(data);
        case 'toast':
          _handleToast(data);
        case 'notification':
          await _handleNotification(data);
        case 'theme':
          await _handleTheme(data);
        case 'auth':
          await _handleAuth(data);
        case 'pickImage':
          await _handlePickImage(data);
        case 'review':
          await _handleReview();
        case 'appInfo':
          await _handleAppInfo();
        case 'musicComplete':
          await _handleMusicComplete(data);
        case 'saveUrl':
          await _handleSaveUrl(data);
        case 'log':
          debugPrint('[WebBridge] ${data['message']}');
        default:
          debugPrint('[BridgeService] Unknown command: $command');
      }
    } catch (e) {
      debugPrint('[BridgeService] Error: $e, raw: $rawMessage');
    }
  }

  /// 네이티브 공유 시트
  Future<void> _handleShare(Map<String, dynamic> data) async {
    final text = data['text'] ?? '';
    final title = data['title'] ?? '';
    final url = data['url'] ?? '';
    final shareText = url.isNotEmpty ? '$text\n$url' : text;
    await Share.share(shareText, subject: title);
  }

  /// 파일 다운로드
  Future<void> _handleDownload(Map<String, dynamic> data) async {
    final url = data['url'] ?? '';
    final fileName = data['fileName'] ?? 'download';

    if (url.isEmpty) return;

    final path = await _download.downloadFile(
      url: url,
      fileName: fileName,
      onProgress: (received, total) {
        final percent = total > 0 ? (received / total * 100).round() : -1;
        _sendToWeb('downloadProgress', {
          'url': url,
          'percent': percent,
          'received': received,
          'total': total,
        });
      },
    );

    _sendToWeb('downloadComplete', {
      'url': url,
      'path': path ?? '',
      'success': path != null,
    });
  }

  /// 햅틱 피드백
  Future<void> _handleHaptic(Map<String, dynamic> data) async {
    final type = data['type'] ?? 'medium';
    switch (type) {
      case 'light':
        HapticFeedback.lightImpact();
      case 'medium':
        HapticFeedback.mediumImpact();
      case 'heavy':
        HapticFeedback.heavyImpact();
      case 'selection':
        HapticFeedback.selectionClick();
      case 'vibrate':
        final duration = data['duration'] ?? 100;
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: duration);
        }
    }
  }

  /// 클립보드 복사
  Future<void> _handleClipboard(Map<String, dynamic> data) async {
    final text = data['text'] ?? '';
    await Clipboard.setData(ClipboardData(text: text));
    _handleToast({
      'message': data['toast'] ?? '클립보드에 복사되었습니다',
      'type': 'success',
    });
  }

  /// 토스트 메시지 (SnackBar)
  void _handleToast(Map<String, dynamic> data) {
    final message = data['message'] ?? '';
    final type = data['type'] ?? 'info';

    final context = contextGetter();
    if (!context.mounted) return;

    Color bgColor;
    IconData icon;
    switch (type) {
      case 'success':
        bgColor = AppColors.success;
        icon = Icons.check_circle_rounded;
      case 'error':
        bgColor = AppColors.error;
        icon = Icons.error_rounded;
      case 'warning':
        bgColor = AppColors.warning;
        icon = Icons.warning_rounded;
      default:
        bgColor = AppColors.primary;
        icon = Icons.info_rounded;
    }

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(width: 8),
        Expanded(
          child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14)),
        ),
      ]),
      backgroundColor: bgColor,
      duration: Duration(milliseconds: data['duration'] ?? 2000),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  /// 로컬 알림
  Future<void> _handleNotification(Map<String, dynamic> data) async {
    final title = data['title'] ?? AppConstants.appName;
    final body = data['body'] ?? '';
    final type = data['type'] ?? 'general';

    switch (type) {
      case 'music':
        await _notif.showMusicComplete(title: title, body: body);
      case 'social':
        await _notif.showSocialNotification(title: title, body: body);
      default:
        await _notif.showGeneral(title: title, body: body);
    }
  }

  /// 테마 변경
  Future<void> _handleTheme(Map<String, dynamic> data) async {
    final mode = data['mode'] ?? 'dark';
    await _storage.setThemeMode(mode);
    _sendToWeb('themeChanged', {'mode': mode});
  }

  /// 인증 정보 저장/삭제
  Future<void> _handleAuth(Map<String, dynamic> data) async {
    final action = data['action'] ?? 'save';
    if (action == 'save') {
      if (data['token'] != null) await _storage.setAuthToken(data['token']);
      if (data['userId'] != null) await _storage.setUserId(data['userId']);
      if (data['userName'] != null) await _storage.setUserName(data['userName']);
    } else if (action == 'clear') {
      await _storage.setAuthToken(null);
      await _storage.setUserId(null);
      await _storage.setUserName(null);
    }
    _sendToWeb('authSaved', {'success': true});
  }

  /// 네이티브 이미지 피커
  Future<void> _handlePickImage(Map<String, dynamic> data) async {
    final source = data['source'] == 'camera' ? ImageSource.camera : ImageSource.gallery;
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, maxWidth: 800, imageQuality: 85);

    if (image != null) {
      final bytes = await image.readAsBytes();
      final b64 = base64Encode(bytes);
      _sendToWeb('imagePicked', {
        'base64': 'data:image/jpeg;base64,$b64',
        'path': image.path,
        'name': image.name,
      });
    } else {
      _sendToWeb('imagePicked', {'cancelled': true});
    }
  }

  /// 인앱 리뷰 요청
  Future<void> _handleReview() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    }
  }

  /// 앱 정보 전달
  Future<void> _handleAppInfo() async {
    final info = await PackageInfo.fromPlatform();
    _sendToWeb('appInfo', {
      'version': info.version,
      'buildNumber': info.buildNumber,
      'packageName': info.packageName,
      'platform': 'flutter',
    });
  }

  /// 음악 생성 완료 알림 + 햅틱
  Future<void> _handleMusicComplete(Map<String, dynamic> data) async {
    final title = data['title'] ?? '새 음악';
    await _notif.showMusicComplete(
      title: '음악 생성 완료!',
      body: '$title - 탭하여 재생하세요',
    );
    HapticFeedback.mediumImpact();
  }

  /// 현재 URL 저장 (앱 재시작 시 복원)
  Future<void> _handleSaveUrl(Map<String, dynamic> data) async {
    final url = data['url'] ?? '';
    if (url.isNotEmpty) await _storage.setLastVisitedUrl(url);
  }

  /// Flutter → Web 이벤트 전송
  void _sendToWeb(String event, Map<String, dynamic> data) {
    final payload = json.encode({'event': event, 'data': data});
    controller.runJavaScript(
      'window.dispatchEvent(new CustomEvent("flutterMessage", {detail: $payload}));',
    );
  }

  /// 앱 초기화 시 웹에 네이티브 정보 전달
  Future<void> sendAppReady() async {
    final info = await PackageInfo.fromPlatform();
    _sendToWeb('appReady', {
      'version': info.version,
      'platform': 'flutter',
      'theme': _storage.themeMode,
      'userId': _storage.userId,
      'notifEnabled': _storage.notifEnabled,
    });
  }
}
