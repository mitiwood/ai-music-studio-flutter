import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/track.dart';
import '../models/user.dart';

/// KMS API 서비스
class ApiService {
  static const _base = AppConstants.apiBaseUrl;

  /// 커뮤니티 공개 트랙 조회
  static Future<List<Track>> getCommunityTracks({int limit = 200}) async {
    final r = await http.get(Uri.parse('$_base${AppConstants.apiTracks}?public=true&limit=$limit'));
    if (r.statusCode != 200) return [];
    final d = jsonDecode(r.body);
    final list = d['tracks'] as List? ?? [];
    return list.map((t) => Track.fromJson(t)).toList();
  }

  /// 트랙 좋아요
  static Future<bool> likeTrack(String trackId) async {
    final r = await http.patch(
      Uri.parse('$_base${AppConstants.apiTracks}?id=$trackId&action=like'),
      headers: {'Content-Type': 'application/json'},
    );
    return r.statusCode == 200;
  }

  /// 트랙 싫어요
  static Future<bool> dislikeTrack(String trackId) async {
    final r = await http.patch(
      Uri.parse('$_base${AppConstants.apiTracks}?id=$trackId&action=dislike'),
      headers: {'Content-Type': 'application/json'},
    );
    return r.statusCode == 200;
  }

  /// 트랙 삭제
  static Future<bool> deleteTrack(String trackId) async {
    final r = await http.delete(
      Uri.parse('$_base${AppConstants.apiTracks}?id=$trackId'),
      headers: {'Content-Type': 'application/json'},
    );
    return r.statusCode == 200;
  }

  /// 관리자 API - 전체 유저 조회
  static Future<List<Map<String, dynamic>>> getUsers() async {
    final r = await http.get(Uri.parse('$_base${AppConstants.apiUsers}'));
    if (r.statusCode != 200) return [];
    final d = jsonDecode(r.body);
    return List<Map<String, dynamic>>.from(d['users'] ?? []);
  }

  /// 관리자 API - 전체 트랙 조회 (비공개 포함)
  static Future<List<Track>> getAllTracks({int limit = 500}) async {
    final r = await http.get(Uri.parse('$_base${AppConstants.apiTracks}?limit=$limit'));
    if (r.statusCode != 200) return [];
    final d = jsonDecode(r.body);
    final list = d['tracks'] as List? ?? [];
    return list.map((t) => Track.fromJson(t)).toList();
  }

  /// 트랙 공개/비공개 토글
  static Future<bool> toggleTrackVisibility(String trackId, bool isPublic) async {
    final r = await http.patch(
      Uri.parse('$_base${AppConstants.apiTracks}?id=$trackId&action=${isPublic ? 'show' : 'hide'}'),
      headers: {'Content-Type': 'application/json'},
    );
    return r.statusCode == 200;
  }

  /// 공지 발송
  static Future<bool> sendAnnouncement({required String title, required String content}) async {
    final r = await http.post(
      Uri.parse('$_base${AppConstants.apiAnnouncement}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'title': title, 'content': content}),
    );
    return r.statusCode == 200;
  }

  /// 공지 삭제
  static Future<bool> deleteAnnouncement() async {
    final r = await http.delete(Uri.parse('$_base${AppConstants.apiAnnouncement}'));
    return r.statusCode == 200;
  }

  /// 로그인 사용자 저장
  static Future<void> saveLoginUser(AppUser user) async {
    await http.post(
      Uri.parse('$_base${AppConstants.apiUsers}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': user.name,
        'provider': user.provider,
        'email': user.email,
        'avatar': user.avatar,
        'lastLogin': DateTime.now().millisecondsSinceEpoch,
        'loginCount': user.loginCount,
      }),
    );
  }

  /// 공지 조회
  static Future<Map<String, dynamic>?> getAnnouncement() async {
    final r = await http.get(Uri.parse('$_base${AppConstants.apiAnnouncement}'));
    if (r.statusCode != 200) return null;
    final d = jsonDecode(r.body);
    if (d['hasAnnouncement'] == true) return d['announcement'];
    return null;
  }

  /// 댓글 조회
  static Future<List<Map<String, dynamic>>> getComments(String trackId) async {
    final r = await http.get(Uri.parse('$_base${AppConstants.apiComments}?track_id=$trackId'));
    if (r.statusCode != 200) return [];
    final d = jsonDecode(r.body);
    return List<Map<String, dynamic>>.from(d['comments'] ?? []);
  }

  /// 댓글 작성
  static Future<bool> postComment({
    required String trackId,
    required String content,
    String authorName = '익명',
    String authorProvider = 'guest',
    String? parentId,
  }) async {
    final r = await http.post(
      Uri.parse('$_base${AppConstants.apiComments}'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'track_id': trackId,
        'content': content,
        'author_name': authorName,
        'author_provider': authorProvider,
        if (parentId != null) 'parent_id': parentId,
      }),
    );
    return r.statusCode == 200;
  }
}
