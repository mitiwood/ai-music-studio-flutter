import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:audio_session/audio_session.dart';
import 'services/bridge_service.dart';
import 'services/deep_link_service.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'widgets/offline_screen.dart';
import 'widgets/download_indicator.dart';
import 'utils/constants.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> with WidgetsBindingObserver {
  late final WebViewController _controller;
  late BridgeService _bridge;
  late StorageService _storage;
  final DeepLinkService _deepLink = DeepLinkService();
  final NotificationService _notif = NotificationService();

  bool _isLoading = true;
  bool _isOffline = false;
  double _progress = 0;
  bool _initialized = false;

  // 다운로드 상태
  bool _showDownload = false;
  String _downloadFileName = '';
  double _downloadProgress = 0;

  // 연결 상태 구독
  StreamSubscription? _connectivitySub;
  StreamSubscription? _deepLinkSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAll();
  }

  Future<void> _initAll() async {
    _storage = await StorageService.getInstance();
    await _notif.init();
    await _deepLink.init();
    await _storage.incrementAppOpenCount();
    await _setupAudioSession();
    _initWebView();
    _listenConnectivity();
    _listenDeepLinks();

    setState(() => _initialized = true);
  }

  /// 오디오 세션 설정 — 백그라운드 오디오 유지
  Future<void> _setupAudioSession() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playback,
      avAudioSessionMode: AVAudioSessionMode.defaultMode,
      androidAudioAttributes: AndroidAudioAttributes(
        contentType: AndroidAudioContentType.music,
        usage: AndroidAudioUsage.media,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));
  }

  /// 네트워크 상태 실시간 모니터링
  void _listenConnectivity() {
    _connectivitySub = Connectivity().onConnectivityChanged.listen((results) {
      final offline = results.contains(ConnectivityResult.none);
      if (mounted && _isOffline != offline) {
        setState(() => _isOffline = offline);
        if (!offline && _initialized) {
          _controller.reload();
        }
      }
    });
    // 초기 상태 체크
    Connectivity().checkConnectivity().then((results) {
      if (mounted) {
        setState(() => _isOffline = results.contains(ConnectivityResult.none));
      }
    });
  }

  /// 딥링크 실시간 수신
  void _listenDeepLinks() {
    // 앱 시작 시 딥링크
    if (_deepLink.initialLink != null) {
      Future.delayed(const Duration(milliseconds: 500), () {
        _controller.loadRequest(Uri.parse(_deepLink.initialLink!));
      });
    }

    // 앱 실행 중 딥링크
    _deepLinkSub = _deepLink.linkStream.listen((url) {
      _controller.loadRequest(Uri.parse(url));
    });
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.bgDark)
      ..setUserAgent(AppConstants.userAgent)
      ..enableZoom(false)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _isLoading = true);
        },
        onPageFinished: (url) {
          if (mounted) setState(() => _isLoading = false);
          _injectNativeBridge();
          _injectAppStyles();
          // URL 저장 (재시작 복원용)
          _storage.setLastVisitedUrl(url);
        },
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress / 100);
        },
        onNavigationRequest: (request) => _handleNavigation(request),
        onWebResourceError: (error) {
          debugPrint('[WebView] Error: ${error.description}');
        },
        onHttpError: (error) {
          debugPrint('[WebView] HTTP Error: ${error.response?.statusCode}');
        },
      ))
      // JS → Flutter 브릿지 채널
      ..addJavaScriptChannel(AppConstants.bridgeChannel, onMessageReceived: (message) {
        _bridge.handleMessage(message.message);
      })
      // 다운로드 전용 채널
      ..addJavaScriptChannel('FlutterDownload', onMessageReceived: (message) {
        _bridge.handleMessage('{"command":"download","data":${message.message}}');
      })
      // 토스트 전용 채널
      ..addJavaScriptChannel('FlutterToast', onMessageReceived: (message) {
        _bridge.handleMessage('{"command":"toast","data":${message.message}}');
      })
      // 햅틱 전용 채널
      ..addJavaScriptChannel('FlutterHaptic', onMessageReceived: (message) {
        HapticFeedback.mediumImpact();
      });

    // 브릿지 서비스 초기화
    _bridge = BridgeService(
      controller: _controller,
      contextGetter: () => context,
    );
    _bridge.init();

    // URL 로드 (저장된 URL 또는 기본 URL)
    final startUrl = _storage.lastVisitedUrl ?? AppConstants.appUrl;
    _controller.loadRequest(Uri.parse(startUrl));
  }

  /// 네비게이션 요청 핸들러
  NavigationDecision _handleNavigation(NavigationRequest request) {
    final url = request.url;
    final uri = Uri.tryParse(url);
    if (uri == null) return NavigationDecision.prevent;

    // 내부 도메인 체크
    for (final domain in AppConstants.internalDomains) {
      if (uri.host.contains(domain)) {
        return NavigationDecision.navigate;
      }
    }

    // blob:, data: URL 허용
    if (url.startsWith('blob:') || url.startsWith('data:')) {
      return NavigationDecision.navigate;
    }

    // 전화, 메일, SMS 등 스킴 처리
    if (['tel', 'mailto', 'sms'].contains(uri.scheme)) {
      launchUrl(uri);
      return NavigationDecision.prevent;
    }

    // 그 외 외부 링크 → 브라우저
    launchUrl(uri, mode: LaunchMode.externalApplication);
    return NavigationDecision.prevent;
  }

  /// 네이티브 브릿지 JS 코드 주입
  void _injectNativeBridge() {
    _controller.runJavaScript('''
      // ─── KMS 네이티브 브릿지 ───
      (function() {
        if (window.__kmsNativeBridge) return;
        window.__kmsNativeBridge = true;
        window.__isKMSApp = true;
        window.__kmsAppVersion = '${AppConstants.appVersion}';

        // 네이티브 브릿지 유틸리티
        window.KMSNative = {
          // 네이티브 공유
          share: function(text, title, url) {
            FlutterBridge.postMessage(JSON.stringify({
              command: 'share',
              data: { text: text || '', title: title || '', url: url || '' }
            }));
          },

          // 파일 다운로드
          download: function(url, fileName) {
            FlutterBridge.postMessage(JSON.stringify({
              command: 'download',
              data: { url: url, fileName: fileName || 'download' }
            }));
          },

          // 햅틱 피드백
          haptic: function(type) {
            FlutterBridge.postMessage(JSON.stringify({
              command: 'haptic',
              data: { type: type || 'medium' }
            }));
          },

          // 클립보드 복사
          clipboard: function(text, toastMsg) {
            FlutterBridge.postMessage(JSON.stringify({
              command: 'clipboard',
              data: { text: text, toast: toastMsg }
            }));
          },

          // 토스트 메시지
          toast: function(message, type, duration) {
            FlutterBridge.postMessage(JSON.stringify({
              command: 'toast',
              data: { message: message, type: type || 'info', duration: duration || 2000 }
            }));
          },

          // 로컬 알림
          notify: function(title, body, type) {
            FlutterBridge.postMessage(JSON.stringify({
              command: 'notification',
              data: { title: title, body: body, type: type || 'general' }
            }));
          },

          // 테마 변경
          setTheme: function(mode) {
            FlutterBridge.postMessage(JSON.stringify({
              command: 'theme',
              data: { mode: mode }
            }));
          },

          // 인증 정보 저장
          saveAuth: function(token, userId, userName) {
            FlutterBridge.postMessage(JSON.stringify({
              command: 'auth',
              data: { action: 'save', token: token, userId: userId, userName: userName }
            }));
          },

          // 인증 정보 삭제
          clearAuth: function() {
            FlutterBridge.postMessage(JSON.stringify({
              command: 'auth',
              data: { action: 'clear' }
            }));
          },

          // 이미지 피커
          pickImage: function(source) {
            FlutterBridge.postMessage(JSON.stringify({
              command: 'pickImage',
              data: { source: source || 'gallery' }
            }));
          },

          // 인앱 리뷰
          requestReview: function() {
            FlutterBridge.postMessage(JSON.stringify({ command: 'review', data: {} }));
          },

          // 앱 정보
          getAppInfo: function() {
            FlutterBridge.postMessage(JSON.stringify({ command: 'appInfo', data: {} }));
          },

          // 음악 생성 완료 알림
          musicComplete: function(title) {
            FlutterBridge.postMessage(JSON.stringify({
              command: 'musicComplete',
              data: { title: title }
            }));
          },

          // URL 저장
          saveUrl: function(url) {
            FlutterBridge.postMessage(JSON.stringify({
              command: 'saveUrl',
              data: { url: url }
            }));
          },

          // 로그
          log: function(msg) {
            FlutterBridge.postMessage(JSON.stringify({
              command: 'log',
              data: { message: msg }
            }));
          }
        };

        // 네이티브 이벤트 수신 헬퍼
        window.onFlutterMessage = function(callback) {
          window.addEventListener('flutterMessage', function(e) {
            callback(e.detail);
          });
        };

        // Web Share API를 네이티브 공유로 오버라이드
        if (navigator.share) {
          var _origShare = navigator.share.bind(navigator);
          navigator.share = function(data) {
            KMSNative.share(data.text || data.title, data.title, data.url);
            return Promise.resolve();
          };
        }

        // 음악 생성 완료 후크 — 앱이 백그라운드일 때 알림
        var _origFetch = window.fetch;
        window.fetch = function() {
          return _origFetch.apply(this, arguments).then(function(response) {
            var url = arguments[0];
            if (typeof url === 'string' && url.includes('/api/callback') && document.hidden) {
              KMSNative.musicComplete('새 음악');
            }
            return response;
          });
        };

        console.log('[KMS] Native bridge v${AppConstants.appVersion} initialized');
      })();
    ''');
    // 앱 준비 이벤트 전송
    _bridge.sendAppReady();
  }

  /// 앱 전용 스타일 주입
  void _injectAppStyles() {
    _controller.runJavaScript('''
      (function() {
        if (document.getElementById('kms-app-style')) return;
        document.body.classList.add('kms-app');
        var s = document.createElement('style');
        s.id = 'kms-app-style';
        s.textContent = \`
          /* PWA 설치 배너 숨기기 */
          .pwa-install-banner, .pwa-prompt, .install-btn,
          [class*="pwa-install"], [class*="install-prompt"] {
            display: none !important;
          }
          /* 앱 환경 최적화 */
          body.kms-app {
            -webkit-user-select: none;
            user-select: none;
            -webkit-tap-highlight-color: transparent;
            overscroll-behavior: none;
          }
          /* 텍스트 입력 필드는 선택 허용 */
          body.kms-app input, body.kms-app textarea, body.kms-app [contenteditable] {
            -webkit-user-select: text;
            user-select: text;
          }
          /* 스크롤바 숨기기 (앱 환경) */
          body.kms-app ::-webkit-scrollbar {
            width: 0;
            height: 0;
          }
          /* Safe area 패딩 */
          body.kms-app .bottom-nav {
            padding-bottom: env(safe-area-inset-bottom, 0px);
          }
        \`;
        document.head.appendChild(s);
      })();
    ''');
  }

  /// 앱 라이프사이클 변화 처리
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        // 앱 포그라운드 복귀 시 연결 상태 확인
        Connectivity().checkConnectivity().then((results) {
          if (mounted) {
            final offline = results.contains(ConnectivityResult.none);
            setState(() => _isOffline = offline);
            if (!offline) {
              // WebView에 포그라운드 이벤트 전달
              _controller.runJavaScript(
                'window.dispatchEvent(new Event("kms-app-resumed"));',
              );
            }
          }
        });
      case AppLifecycleState.paused:
        // 앱 백그라운드 시 URL 저장
        _controller.currentUrl().then((url) {
          if (url != null) _storage.setLastVisitedUrl(url);
        });
        // WebView에 백그라운드 이벤트 전달
        _controller.runJavaScript(
          'window.dispatchEvent(new Event("kms-app-paused"));',
        );
      default:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    _deepLinkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isOffline) {
      return Scaffold(
        backgroundColor: AppColors.bgDark,
        body: SafeArea(
          child: OfflineScreen(
            onRetry: () async {
              final results = await Connectivity().checkConnectivity();
              final offline = results.contains(ConnectivityResult.none);
              if (mounted) {
                setState(() => _isOffline = offline);
                if (!offline) _controller.reload();
              }
            },
          ),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // WebView 내 바텀시트/모달 닫기 시도
        final closed = await _controller.runJavaScriptReturningResult('''
          (function() {
            // 열린 바텀시트 닫기
            var sheets = document.querySelectorAll('.bottom-sheet.active, .modal.show, [class*="sheet"].open');
            if (sheets.length > 0) {
              sheets[sheets.length - 1].classList.remove('active', 'show', 'open');
              return true;
            }
            // 풀플레이어 닫기
            var fp = document.getElementById('fullplayer');
            if (fp && fp.classList.contains('open')) {
              fp.classList.remove('open');
              return true;
            }
            return false;
          })()
        ''');

        if (closed.toString() == 'true') return;

        // WebView 히스토리 뒤로가기
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgDark,
        body: SafeArea(
          child: Stack(
            children: [
              // WebView
              if (_initialized) WebViewWidget(controller: _controller),

              // 로딩 프로그레스 바
              if (_isLoading)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: _buildProgressBar(),
                ),

              // 다운로드 진행 오버레이
              if (_showDownload)
                DownloadIndicator(
                  fileName: _downloadFileName,
                  progress: _downloadProgress,
                  onCancel: () {
                    setState(() => _showDownload = false);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// 향상된 프로그레스 바
  Widget _buildProgressBar() {
    return AnimatedOpacity(
      opacity: _isLoading ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: Container(
        height: 3,
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: LinearProgressIndicator(
          value: _progress > 0 ? _progress : null,
          minHeight: 3,
          backgroundColor: Colors.transparent,
          valueColor: AlwaysStoppedAnimation(
            Color.lerp(AppColors.primary, AppColors.accent, _progress) ?? AppColors.primary,
          ),
        ),
      ),
    );
  }
}
