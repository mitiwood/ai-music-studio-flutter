import 'dart:math';
import 'package:flutter/material.dart';
import 'webview_screen.dart';
import 'utils/constants.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _mainCtrl;
  late AnimationController _particleCtrl;
  late AnimationController _pulseCtrl;
  late Animation<double> _fadeIn;
  late Animation<double> _scale;
  late Animation<double> _slideUp;
  late Animation<double> _logoRotate;
  late Animation<double> _subtitleFade;

  final List<_Particle> _particles = [];
  final _random = Random();

  @override
  void initState() {
    super.initState();

    for (var i = 0; i < 20; i++) {
      _particles.add(_Particle(
        x: _random.nextDouble(), y: _random.nextDouble(),
        size: _random.nextDouble() * 4 + 1,
        speed: _random.nextDouble() * 0.5 + 0.2,
        opacity: _random.nextDouble() * 0.5 + 0.1,
      ));
    }

    _mainCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _fadeIn = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainCtrl, curve: const Interval(0, 0.5, curve: Curves.easeOut)));
    _scale = Tween<double>(begin: 0.6, end: 1).animate(
      CurvedAnimation(parent: _mainCtrl, curve: const Interval(0, 0.5, curve: Curves.easeOutBack)));
    _slideUp = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.2, 0.7, curve: Curves.easeOut)));
    _logoRotate = Tween<double>(begin: -0.1, end: 0).animate(
      CurvedAnimation(parent: _mainCtrl, curve: const Interval(0, 0.6, curve: Curves.easeOutBack)));
    _subtitleFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _mainCtrl, curve: const Interval(0.4, 0.8, curve: Curves.easeOut)));

    _particleCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500),
      lowerBound: 0.95, upperBound: 1.05)..repeat(reverse: true);

    _mainCtrl.forward();

    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const WebViewScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeInOut), child: child),
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    });
  }

  @override
  void dispose() {
    _mainCtrl.dispose();
    _particleCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgDark,
      body: Stack(children: [
        Container(decoration: const BoxDecoration(
          gradient: RadialGradient(center: Alignment(0, -0.3), radius: 1.2,
            colors: [Color(0xFF1A1040), Color(0xFF0A0A1A)]))),

        AnimatedBuilder(
          animation: _particleCtrl,
          builder: (context, _) => CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _ParticlePainter(particles: _particles, progress: _particleCtrl.value))),

        Center(child: AnimatedBuilder(
          animation: _mainCtrl,
          builder: (_, __) => Opacity(
            opacity: _fadeIn.value,
            child: Transform.translate(
              offset: Offset(0, _slideUp.value),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (_, __) => Transform.scale(
                    scale: _scale.value * _pulseCtrl.value,
                    child: Transform.rotate(
                      angle: _logoRotate.value,
                      child: Container(
                        width: 96, height: 96,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: AppColors.primary.withAlpha(128), blurRadius: 32, offset: const Offset(0, 8), spreadRadius: 4),
                            BoxShadow(color: AppColors.accent.withAlpha(51), blurRadius: 48, offset: const Offset(0, 12), spreadRadius: 8),
                          ],
                        ),
                        child: const Center(child: Text('\u{1F3B5}', style: TextStyle(fontSize: 44))),
                      )))),

                const SizedBox(height: 28),

                ShaderMask(
                  shaderCallback: (bounds) => const LinearGradient(
                    colors: [AppColors.primaryLight, AppColors.accent]).createShader(bounds),
                  child: const Text("Kenny's Music Studio",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5))),

                const SizedBox(height: 12),

                Opacity(opacity: _subtitleFade.value,
                  child: const Text('AI\ub85c \ub098\ub9cc\uc758 \uc74c\uc545\uc744 \ub9cc\ub4e4\uc5b4\ubcf4\uc138\uc694',
                    style: TextStyle(fontSize: 14, color: AppColors.textSecondary, letterSpacing: 0.3))),

                const SizedBox(height: 8),

                Opacity(opacity: _subtitleFade.value * 0.5,
                  child: const Text('v${AppConstants.appVersion}',
                    style: TextStyle(fontSize: 11, color: AppColors.textMuted))),

                const SizedBox(height: 40),

                SizedBox(width: 32, height: 32,
                  child: CircularProgressIndicator(strokeWidth: 2.5, strokeCap: StrokeCap.round,
                    valueColor: AlwaysStoppedAnimation(
                      Color.lerp(AppColors.primary, AppColors.accent, _particleCtrl.value)!))),
              ]))))),

        Positioned(bottom: 40, left: 0, right: 0,
          child: AnimatedBuilder(
            animation: _mainCtrl,
            builder: (_, __) => Opacity(
              opacity: _subtitleFade.value * 0.4,
              child: const Column(children: [
                Text('Powered by AI', style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                SizedBox(height: 4),
                Text('\u00a9 2024 Kenny Music Studio', style: TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ])))),
      ]),
    );
  }
}

class _Particle {
  double x, y, size, speed, opacity;
  _Particle({required this.x, required this.y, required this.size, required this.speed, required this.opacity});
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final y = ((p.y + progress * p.speed) % 1.2) * size.height;
      final x = p.x * size.width + sin(progress * 2 * pi + p.x * 10) * 20;
      final paint = Paint()
        ..color = Color.lerp(AppColors.primary, AppColors.accent, p.x)!
            .withAlpha((p.opacity * (0.5 + 0.5 * sin(progress * 2 * pi + p.y * 5)) * 255).round());
      canvas.drawCircle(Offset(x, y), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}
