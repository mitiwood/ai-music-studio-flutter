import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import '../models/track.dart';

/// 오프라인 캐싱 서비스 (트랙 목록 + 오디오 파일)
class CacheService {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      '$dbPath/kms_cache.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tracks (
            id TEXT PRIMARY KEY,
            data TEXT NOT NULL,
            cached_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE audio_cache (
            track_id TEXT PRIMARY KEY,
            local_path TEXT NOT NULL,
            cached_at INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  /// 트랙 목록 캐시 저장
  static Future<void> cacheTracks(List<Track> tracks) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().millisecondsSinceEpoch;

    // 기존 캐시 삭제 후 새로 저장
    batch.delete('tracks');
    for (final t in tracks) {
      batch.insert('tracks', {
        'id': t.id,
        'data': jsonEncode(_trackToMap(t)),
        'cached_at': now,
      });
    }
    await batch.commit(noResult: true);
  }

  /// 캐시된 트랙 목록 불러오기
  static Future<List<Track>> getCachedTracks() async {
    try {
      final db = await database;
      final rows = await db.query('tracks', orderBy: 'cached_at DESC');
      return rows.map((r) => Track.fromJson(jsonDecode(r['data'] as String))).toList();
    } catch (_) {
      return [];
    }
  }

  /// 캐시 만료 여부 확인 (기본 30분)
  static Future<bool> isCacheExpired({int maxAgeMinutes = 30}) async {
    try {
      final db = await database;
      final rows = await db.query('tracks', limit: 1, orderBy: 'cached_at DESC');
      if (rows.isEmpty) return true;
      final cachedAt = rows.first['cached_at'] as int;
      final age = DateTime.now().millisecondsSinceEpoch - cachedAt;
      return age > maxAgeMinutes * 60 * 1000;
    } catch (_) {
      return true;
    }
  }

  /// 오디오 파일 로컬 캐싱
  static Future<String?> cacheAudio(String trackId, String audioUrl) async {
    if (audioUrl.isEmpty) return null;
    try {
      // 이미 캐시되어 있는지 확인
      final existing = await getCachedAudioPath(trackId);
      if (existing != null && File(existing).existsSync()) return existing;

      final dir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${dir.path}/audio_cache');
      if (!audioDir.existsSync()) audioDir.createSync(recursive: true);

      final ext = audioUrl.contains('.mp3') ? '.mp3' : '.m4a';
      final localPath = '${audioDir.path}/$trackId$ext';

      final response = await http.get(Uri.parse(audioUrl));
      if (response.statusCode == 200) {
        await File(localPath).writeAsBytes(response.bodyBytes);

        final db = await database;
        await db.insert('audio_cache', {
          'track_id': trackId,
          'local_path': localPath,
          'cached_at': DateTime.now().millisecondsSinceEpoch,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        return localPath;
      }
    } catch (_) {}
    return null;
  }

  /// 캐시된 오디오 파일 경로 조회
  static Future<String?> getCachedAudioPath(String trackId) async {
    try {
      final db = await database;
      final rows = await db.query('audio_cache', where: 'track_id = ?', whereArgs: [trackId]);
      if (rows.isNotEmpty) {
        final path = rows.first['local_path'] as String;
        if (File(path).existsSync()) return path;
      }
    } catch (_) {}
    return null;
  }

  /// 캐시 전체 크기 (bytes)
  static Future<int> getCacheSize() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${dir.path}/audio_cache');
      if (!audioDir.existsSync()) return 0;
      int total = 0;
      await for (final entity in audioDir.list()) {
        if (entity is File) total += await entity.length();
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  /// 캐시 전체 삭제
  static Future<void> clearCache() async {
    try {
      final db = await database;
      await db.delete('tracks');
      await db.delete('audio_cache');

      final dir = await getApplicationDocumentsDirectory();
      final audioDir = Directory('${dir.path}/audio_cache');
      if (audioDir.existsSync()) await audioDir.delete(recursive: true);
    } catch (_) {}
  }

  static Map<String, dynamic> _trackToMap(Track t) => {
    'id': t.id,
    'task_id': t.taskId,
    'title': t.title,
    'audio_url': t.audioUrl,
    'video_url': t.videoUrl,
    'image_url': t.imageUrl,
    'tags': t.tags,
    'lyrics': t.lyrics,
    'gen_mode': t.genMode,
    'owner_name': t.ownerName,
    'owner_avatar': t.ownerAvatar,
    'owner_provider': t.ownerProvider,
    'is_public': t.isPublic,
    'comm_likes': t.likes,
    'comm_dislikes': t.dislikes,
    'comm_plays': t.plays,
    'created': t.created,
  };
}
