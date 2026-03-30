import 'package:flutter/material.dart';

class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = "Kenny's Music Studio";
  static const String appVersion = '2.1.0';
  static const String appUrl = 'https://ai-music-studio-bice.vercel.app';
  static const String appScheme = 'kms';
  static const String appHost = 'ai-music-studio-bice.vercel.app';

  // User Agent
  static const String userAgent = 'KMSApp/2.1 Flutter';

  // Allowed internal domains
  static const List<String> internalDomains = [
    'ai-music-studio-bice.vercel.app',
    'kie.ai',
    'accounts.google.com',
    'kauth.kakao.com',
    'nid.naver.com',
    'api.tosspayments.com',
    'pay.toss.im',
  ];

  // Bridge Commands
  static const String bridgeChannel = 'FlutterBridge';

  // Storage Keys
  static const String keyThemeMode = 'theme_mode';
  static const String keyAuthToken = 'auth_token';
  static const String keyUserId = 'user_id';
  static const String keyUserName = 'user_name';
  static const String keyNotifEnabled = 'notification_enabled';
  static const String keyLastVisitedUrl = 'last_visited_url';
  static const String keyAppOpenCount = 'app_open_count';
  static const String keyFirstLaunch = 'first_launch';
  static const String keyDownloadPath = 'download_path';

  // Notification Channels
  static const String notifChannelGeneral = 'kms_general';
  static const String notifChannelMusic = 'kms_music';
  static const String notifChannelDownload = 'kms_download';
  static const String notifChannelSocial = 'kms_social';

  // Download MIME types
  static const Map<String, String> audioMimeTypes = {
    'mp3': 'audio/mpeg',
    'wav': 'audio/wav',
    'flac': 'audio/flac',
    'm4a': 'audio/mp4',
    'ogg': 'audio/ogg',
  };
}

class AppColors {
  AppColors._();

  // Primary
  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFFA855F7);
  static const Color primaryDark = Color(0xFF5B21B6);

  // Accent
  static const Color accent = Color(0xFFEC4899);
  static const Color accentLight = Color(0xFFF472B6);

  // Background (Dark)
  static const Color bgDark = Color(0xFF0A0A1A);
  static const Color cardDark = Color(0xFF14142B);
  static const Color surfaceDark = Color(0xFF1C1C3A);

  // Background (Light)
  static const Color bgLight = Color(0xFFF8F8FC);
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color surfaceLight = Color(0xFFF0F0F8);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF6B6580);
  static const Color textMuted = Color(0xFF4A4560);

  // Status
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [primaryLight, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient darkGradient = LinearGradient(
    colors: [Color(0xFF0A0A1A), Color(0xFF14142B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
