import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/track.dart';
import '../models/comment.dart';

class ApiService {
  static const baseUrl = 'https://ai-music-studio-bice.vercel.app';

  // ── Tracks ──
  static Future<List<Track>> getTracks({bool publicOnly = true}) async {
    final url = '$baseUrl/api/tracks${publicOnly ? '?public=true' : ''}';
    final r = await http.get(Uri.parse(url));
    if (r.statusCode != 200) return [];
    final data = jsonDecode(r.body);
    final list = data is List ? data : (data['tracks'] ?? []);
    return list.map<Track>((j) => Track.fromJson(j)).toList();
  }

  static Future<bool> likeTrack(String trackId, String userName, String userProvider, {String type = 'like'}) async {
    final r = await http.patch(
      Uri.parse('$baseUrl/api/tracks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'id': trackId, 'action': type, 'userName': userName, 'userProvider': userProvider}),
    );
    return r.statusCode == 200;
  }

  static Future<Map<String, dynamic>> saveTrack(Map<String, dynamic> trackData) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/tracks'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(trackData),
    );
    return jsonDecode(r.body);
  }

  // ── Music Generation (kie.ai proxy) ──
  static Future<Map<String, dynamic>> kieRequest(String method, String path, {Map<String, dynamic>? body, String? userName, String? userProvider}) async {
    final payload = <String, dynamic>{'path': path, 'method': method};
    if (body != null) payload['body'] = body;
    if (userName != null) payload['userName'] = userName;
    if (userProvider != null) payload['userProvider'] = userProvider;
    final r = await http.post(
      Uri.parse('$baseUrl/api/kie-proxy'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    final data = jsonDecode(r.body);
    if (r.statusCode != 200) {
      throw Exception(data['error'] ?? data['msg'] ?? 'API Error ${r.statusCode}');
    }
    return data;
  }

  static Future<Map<String, dynamic>> pollResult(String taskId) async {
    return kieRequest('GET', '/api/v1/generate/record-info?taskId=$taskId');
  }

  // ── Comments ──
  static Future<List<Comment>> getComments(String trackId) async {
    final r = await http.get(Uri.parse('$baseUrl/api/comments?track_id=${Uri.encodeComponent(trackId)}'));
    if (r.statusCode != 200) return [];
    final d = jsonDecode(r.body);
    return (d['comments'] as List? ?? []).map<Comment>((j) => Comment.fromJson(j)).toList();
  }

  static Future<bool> postComment({required String trackId, required String content, String? parentId, required String authorName, String? authorAvatar, required String authorProvider}) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/comments'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'track_id': trackId, 'content': content, 'parent_id': parentId, 'author_name': authorName, 'author_avatar': authorAvatar ?? '', 'author_provider': authorProvider}),
    );
    return r.statusCode == 200;
  }

  static Future<bool> deleteComment(String id, String authorName, String authorProvider) async {
    final r = await http.delete(Uri.parse('$baseUrl/api/comments?id=${Uri.encodeComponent(id)}&authorName=${Uri.encodeComponent(authorName)}&authorProvider=${Uri.encodeComponent(authorProvider)}'));
    return r.statusCode == 200;
  }

  // ── Attendance ──
  static Future<Map<String, dynamic>> getAttendance(String userName, String userProvider) async {
    final r = await http.get(Uri.parse('$baseUrl/api/attendance?userName=${Uri.encodeComponent(userName)}&userProvider=${Uri.encodeComponent(userProvider)}'));
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> checkIn(String userName, String userProvider) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/attendance'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userName': userName, 'userProvider': userProvider}),
    );
    return jsonDecode(r.body);
  }

  // ── Profile ──
  static Future<Map<String, dynamic>> getProfile(String userName, String userProvider) async {
    final r = await http.get(Uri.parse('$baseUrl/api/profile?name=${Uri.encodeComponent(userName)}&provider=${Uri.encodeComponent(userProvider)}'));
    return jsonDecode(r.body);
  }

  static Future<Map<String, dynamic>> updateProfile({required String oldName, required String newName, required String provider, String? bio}) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/profile'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'action': 'update-profile', 'name': newName, 'provider': provider, 'oldName': oldName, 'bio': bio}),
    );
    return jsonDecode(r.body);
  }

  static Future<bool> toggleFollow(String followerName, String followerProvider, String followingName, String followingProvider) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/profile'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'action': 'follow', 'followerName': followerName, 'followerProvider': followerProvider, 'followingName': followingName, 'followingProvider': followingProvider}),
    );
    return r.statusCode == 200;
  }

  // ── Credit Check ──
  static Future<Map<String, dynamic>> checkCredit(String userName, String userProvider, String type) async {
    final r = await http.post(
      Uri.parse('$baseUrl/api/check-credit'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userName': userName, 'userProvider': userProvider, 'type': type}),
    );
    return jsonDecode(r.body);
  }

  // ── Toss Config ──
  static Future<Map<String, dynamic>> getTossConfig() async {
    final r = await http.get(Uri.parse('$baseUrl/api/toss-config'));
    return jsonDecode(r.body);
  }

  // ── Notifications ──
  static Future<List<Map<String, dynamic>>> getNotifications(String userName, String userProvider) async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/api/live-notify?since=0'));
      if (r.statusCode != 200) return [];
      final d = jsonDecode(r.body);
      return List<Map<String, dynamic>>.from(d['notifications'] ?? []);
    } catch (_) { return []; }
  }

  // ── Announcements ──
  static Future<Map<String, dynamic>?> getAnnouncement() async {
    try {
      final r = await http.get(Uri.parse('$baseUrl/api/announcement'));
      if (r.statusCode != 200) return null;
      final d = jsonDecode(r.body);
      if (d['active'] == true) return d;
      return null;
    } catch (_) { return null; }
  }
}
