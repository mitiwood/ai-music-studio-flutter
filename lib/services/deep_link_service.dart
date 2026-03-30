import 'dart:async';
import 'package:app_links/app_links.dart';
import '../utils/constants.dart';

/// 딥링크 서비스 — kms:// 또는 https:// 딥링크 처리
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._();
  factory DeepLinkService() => _instance;
  DeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  final StreamController<String> _linkController = StreamController<String>.broadcast();

  Stream<String> get linkStream => _linkController.stream;
  String? _initialLink;
  String? get initialLink => _initialLink;

  Future<void> init() async {
    // 앱이 종료된 상태에서 딥링크로 열린 경우
    try {
      final uri = await _appLinks.getInitialLink();
      if (uri != null) {
        _initialLink = _convertToWebUrl(uri);
      }
    } catch (_) {}

    // 앱이 실행 중일 때 딥링크 수신
    _appLinks.uriLinkStream.listen((uri) {
      final webUrl = _convertToWebUrl(uri);
      if (webUrl != null) {
        _linkController.add(webUrl);
      }
    });
  }

  /// 딥링크 URI를 웹 URL로 변환
  /// kms://track/123 -> https://ai-music-studio-bice.vercel.app/#track/123
  /// kms://community -> https://ai-music-studio-bice.vercel.app/#community
  String? _convertToWebUrl(Uri uri) {
    if (uri.scheme == AppConstants.appScheme) {
      final path = uri.host + uri.path;
      return '${AppConstants.appUrl}/#$path';
    }
    if (uri.host == AppConstants.appHost) {
      return uri.toString();
    }
    return null;
  }

  void dispose() {
    _linkController.close();
  }
}
