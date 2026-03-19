import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../config/constants.dart';
import '../models/track.dart';

class ShareUtils {
  static String getShareUrl(Track track) {
    return '${AppConstants.apiBaseUrl}/?shared=${track.id}';
  }

  static Future<void> shareTrack(Track track) async {
    final url = getShareUrl(track);
    final text = '${track.title} - ${track.ownerName}\n$url\n\nKenny\'s Music Studio에서 AI로 만든 음악을 들어보세요!';
    await Share.share(text);
  }

  static Future<void> copyLink(Track track) async {
    final url = getShareUrl(track);
    await Clipboard.setData(ClipboardData(text: url));
  }
}
