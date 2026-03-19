/// KMS API 및 앱 설정 상수
class AppConstants {
  static const String appName = "Kenny's Music Studio";
  static const String appVersion = 'v4.0-flutter';
  static const String apiBaseUrl = 'https://ai-music-studio-bice.vercel.app';

  // API 엔드포인트
  static const String apiTracks = '/api/tracks';
  static const String apiUsers = '/api/users';
  static const String apiComments = '/api/comments';
  static const String apiAnnouncement = '/api/announcement';
  static const String apiManagers = '/api/managers';
  static const String apiKieProxy = '/api/kie-proxy';
  static const String apiAnalyze = '/api/analyze';
  static const String apiPushSend = '/api/push-send';
  static const String apiClaudeUsage = '/api/claude-usage';
  static const String apiPaymentsConfirm = '/api/payments/confirm';

  // 소셜 로그인
  static const String authGoogle = '/api/auth/google';
  static const String authKakao = '/api/auth/kakao/redirect';
  static const String authNaver = '/api/auth/naver/redirect';

  // 플랜
  static const Map<String, Map<String, dynamic>> plans = {
    'free': {'price': 0, 'credits': 2, 'label': 'Free'},
    'basic': {'price': 4900, 'credits': 30, 'label': 'Basic'},
    'pro': {'price': 9900, 'credits': 100, 'label': 'Pro'},
    'unlimited': {'price': 19900, 'credits': 999999, 'label': 'Unlimited'},
  };
}
