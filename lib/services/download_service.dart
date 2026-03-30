import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'notification_service.dart';

/// 파일 다운로드 서비스 — 음악 파일 다운로드 및 저장
class DownloadService {
  static final DownloadService _instance = DownloadService._();
  factory DownloadService() => _instance;
  DownloadService._();

  final NotificationService _notif = NotificationService();
  final Map<int, bool> _activeDownloads = {};

  /// 다운로드 디렉토리 가져오기
  Future<Directory> get _downloadDir async {
    if (Platform.isAndroid) {
      // Android Downloads 폴더
      final dir = Directory('/storage/emulated/0/Download/KennyMusicStudio');
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir;
    } else {
      final appDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDir.path}/Downloads');
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir;
    }
  }

  /// 저장소 권한 요청
  Future<bool> _requestPermission() async {
    if (Platform.isAndroid) {
      // Android 13+ 는 미디어 권한, 이전은 스토리지 권한
      final status = await Permission.storage.request();
      if (status.isGranted) return true;

      // Android 13+
      final audioStatus = await Permission.audio.request();
      return audioStatus.isGranted;
    }
    return true; // iOS는 앱 샌드박스 내 저장
  }

  /// URL에서 파일 다운로드
  Future<String?> downloadFile({
    required String url,
    required String fileName,
    Function(int received, int total)? onProgress,
  }) async {
    final hasPermission = await _requestPermission();
    if (!hasPermission) return null;

    final downloadId = url.hashCode;
    _activeDownloads[downloadId] = true;

    try {
      final dir = await _downloadDir;

      // 파일명 중복 처리
      var finalName = fileName;
      var filePath = '${dir.path}/$finalName';
      var counter = 1;
      while (await File(filePath).exists()) {
        final ext = fileName.contains('.') ? '.${fileName.split('.').last}' : '';
        final name = fileName.contains('.') ? fileName.substring(0, fileName.lastIndexOf('.')) : fileName;
        finalName = '$name ($counter)$ext';
        filePath = '${dir.path}/$finalName';
        counter++;
      }

      // HTTP GET 요청 (스트리밍)
      final request = http.Request('GET', Uri.parse(url));
      final response = await http.Client().send(request);
      final totalBytes = response.contentLength ?? -1;
      var receivedBytes = 0;

      final file = File(filePath);
      final sink = file.openWrite();

      await for (final chunk in response.stream) {
        if (_activeDownloads[downloadId] != true) {
          // 다운로드 취소됨
          await sink.close();
          if (await file.exists()) await file.delete();
          return null;
        }

        sink.add(chunk);
        receivedBytes += chunk.length;

        onProgress?.call(receivedBytes, totalBytes);

        // 알림 업데이트 (매 100KB)
        if (totalBytes > 0 && receivedBytes % (100 * 1024) < chunk.length) {
          await _notif.showDownloadProgress(
            id: downloadId,
            fileName: finalName,
            progress: receivedBytes,
            maxProgress: totalBytes,
          );
        }
      }

      await sink.close();
      _activeDownloads.remove(downloadId);

      // 다운로드 완료 알림
      await _notif.showDownloadComplete(fileName: finalName, filePath: filePath);

      return filePath;
    } catch (e) {
      _activeDownloads.remove(downloadId);
      return null;
    }
  }

  /// 다운로드 취소
  void cancelDownload(String url) {
    _activeDownloads[url.hashCode] = false;
  }

  /// 다운로드된 파일 목록 가져오기
  Future<List<FileSystemEntity>> getDownloadedFiles() async {
    final dir = await _downloadDir;
    if (!await dir.exists()) return [];
    return dir.listSync()..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
  }

  /// 총 다운로드 용량
  Future<int> getTotalDownloadSize() async {
    final files = await getDownloadedFiles();
    var total = 0;
    for (final file in files) {
      if (file is File) total += await file.length();
    }
    return total;
  }

  /// 다운로드 폴더 전체 삭제
  Future<void> clearDownloads() async {
    final dir = await _downloadDir;
    if (await dir.exists()) {
      await dir.delete(recursive: true);
      await dir.create(recursive: true);
    }
  }
}
