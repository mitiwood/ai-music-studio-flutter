import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _isOffline = false;
  double _progress = 0;

  static const _appUrl = 'https://ai-music-studio-bice.vercel.app';

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _initWebView();
  }

  Future<void> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    if (mounted) {
      setState(() => _isOffline = result.contains(ConnectivityResult.none));
    }
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0A0A1A))
      ..setUserAgent('KMSApp/2.0 Flutter Android')
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _isLoading = true);
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _isLoading = false);
          // 앱 전용 CSS 주입 (PWA 설치 배너 숨기기 등)
          _controller.runJavaScript('''
            document.body.classList.add('kms-app');
            var s = document.createElement('style');
            s.textContent = '.pwa-install-banner,.pwa-prompt{display:none!important}';
            document.head.appendChild(s);
          ''');
        },
        onProgress: (progress) {
          if (mounted) setState(() => _progress = progress / 100);
        },
        onNavigationRequest: (request) {
          final url = request.url;
          // 외부 링크는 브라우저로 열기
          if (!url.startsWith(_appUrl) &&
              !url.contains('kie.ai') &&
              !url.contains('accounts.google.com') &&
              !url.contains('kauth.kakao.com') &&
              !url.contains('nid.naver.com') &&
              !url.contains('api.tosspayments.com')) {
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
      ))
      // JS → Flutter 브릿지
      ..addJavaScriptChannel('FlutterBridge', onMessageReceived: (message) {
        _handleBridgeMessage(message.message);
      })
      ..loadRequest(Uri.parse(_appUrl));
  }

  void _handleBridgeMessage(String message) {
    if (message.startsWith('share:')) {
      final data = message.substring(6);
      Share.share(data);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOffline) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A1A),
        body: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('📡', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text('인터넷 연결이 필요합니다', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
            const SizedBox(height: 8),
            const Text('Wi-Fi 또는 모바일 데이터를 확인해주세요', style: TextStyle(fontSize: 13, color: Color(0xFF6B6580))),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                await _checkConnectivity();
                if (!_isOffline) _controller.loadRequest(Uri.parse(_appUrl));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              child: const Text('다시 시도', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ]),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _controller.canGoBack()) {
          await _controller.goBack();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A1A),
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              // 로딩 프로그레스 바
              if (_isLoading)
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    minHeight: 2,
                    backgroundColor: Colors.transparent,
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF7C3AED)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
