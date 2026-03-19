import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../models/track.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/audio_service.dart';
import '../services/cache_service.dart';

class AppProvider extends ChangeNotifier {
  AppUser? _currentUser;
  List<Track> _communityTracks = [];
  List<Track> _myTracks = [];
  bool _tracksLoading = false;
  bool _myTracksLoading = false;
  bool _generating = false;
  bool _loginLoading = false;
  String? _selectedGenre;
  Track? _currentPlayingTrack;
  Map<String, dynamic>? _announcement;

  final AudioService audioService = AudioService();

  // Getters
  AppUser? get currentUser => _currentUser;
  List<Track> get communityTracks => _communityTracks;
  List<Track> get myTracks => _myTracks;
  bool get tracksLoading => _tracksLoading;
  bool get myTracksLoading => _myTracksLoading;
  bool get generating => _generating;
  bool get loginLoading => _loginLoading;
  String? get selectedGenre => _selectedGenre;
  Track? get currentPlayingTrack => _currentPlayingTrack;
  Map<String, dynamic>? get announcement => _announcement;
  bool get isLoggedIn => _currentUser != null && _currentUser!.isLoggedIn;
  int get credits => _currentUser?.credits ?? 2;

  AppProvider() {
    _loadSavedUser();
  }

  // --- Auth ---
  Future<void> _loadSavedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson != null) {
      try {
        _currentUser = AppUser.fromJson(jsonDecode(userJson));
        notifyListeners();
      } catch (_) {}
    }
  }

  Future<void> login(AppUser user) async {
    _currentUser = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user.toJson()));
    await ApiService.saveLoginUser(user);
    notifyListeners();
    loadMyTracks();
  }

  Future<void> logout() async {
    _currentUser = null;
    _myTracks = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user');
    notifyListeners();
  }

  /// Google 네이티브 로그인
  Future<bool> loginWithGoogle() async {
    return _socialLogin(() => AuthService.loginWithGoogle());
  }

  /// Kakao 네이티브 로그인
  Future<bool> loginWithKakao() async {
    return _socialLogin(() => AuthService.loginWithKakao());
  }

  /// Naver 네이티브 로그인
  Future<bool> loginWithNaver() async {
    return _socialLogin(() => AuthService.loginWithNaver());
  }

  Future<bool> _socialLogin(Future<AppUser?> Function() loginFn) async {
    _loginLoading = true;
    notifyListeners();
    try {
      final user = await loginFn();
      if (user != null) {
        await login(user);
        _loginLoading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {}
    _loginLoading = false;
    notifyListeners();
    return false;
  }

  // --- Community Tracks (with offline cache) ---
  Future<void> loadCommunityTracks() async {
    _tracksLoading = true;
    notifyListeners();

    // 캐시 먼저 표시
    if (_communityTracks.isEmpty) {
      final cached = await CacheService.getCachedTracks();
      if (cached.isNotEmpty) {
        _communityTracks = cached;
        _tracksLoading = false;
        notifyListeners();
      }
    }

    // 서버에서 최신 데이터 로드
    try {
      final fresh = await ApiService.getCommunityTracks();
      _communityTracks = fresh;
      // 백그라운드 캐시 갱신
      CacheService.cacheTracks(fresh);
    } catch (_) {
      // 오프라인: 캐시된 데이터 사용
      if (_communityTracks.isEmpty) {
        _communityTracks = await CacheService.getCachedTracks();
      }
    }
    _tracksLoading = false;
    notifyListeners();
  }

  List<Track> get filteredTracks {
    if (_selectedGenre == null || _selectedGenre == '전체') {
      return _communityTracks;
    }
    return _communityTracks
        .where((t) => t.tags.toLowerCase().contains(_selectedGenre!.toLowerCase()))
        .toList();
  }

  Track? get heroTrack {
    if (_communityTracks.isEmpty) return null;
    final sorted = List<Track>.from(_communityTracks)
      ..sort((a, b) => b.likes.compareTo(a.likes));
    return sorted.first;
  }

  void setGenreFilter(String? genre) {
    _selectedGenre = genre;
    notifyListeners();
  }

  // --- My Tracks ---
  Future<void> loadMyTracks() async {
    if (_currentUser == null || !isLoggedIn) return;
    _myTracksLoading = true;
    notifyListeners();
    try {
      final allTracks = await ApiService.getCommunityTracks(limit: 500);
      _myTracks = allTracks
          .where((t) =>
              t.ownerName == _currentUser!.name &&
              t.ownerProvider == _currentUser!.provider)
          .toList();
    } catch (_) {}
    _myTracksLoading = false;
    notifyListeners();
  }

  // --- Track Actions ---
  Future<void> likeTrack(String trackId) async {
    // 즉시 UI 반영
    _updateTrackLocally(trackId, (t) => Track(
      id: t.id, taskId: t.taskId, title: t.title, audioUrl: t.audioUrl,
      videoUrl: t.videoUrl, imageUrl: t.imageUrl, tags: t.tags, lyrics: t.lyrics,
      genMode: t.genMode, ownerName: t.ownerName, ownerAvatar: t.ownerAvatar,
      ownerProvider: t.ownerProvider, isPublic: t.isPublic,
      likes: t.likes + 1, dislikes: t.dislikes, plays: t.plays, created: t.created,
    ));
    await ApiService.likeTrack(trackId);
  }

  Future<void> dislikeTrack(String trackId) async {
    _updateTrackLocally(trackId, (t) => Track(
      id: t.id, taskId: t.taskId, title: t.title, audioUrl: t.audioUrl,
      videoUrl: t.videoUrl, imageUrl: t.imageUrl, tags: t.tags, lyrics: t.lyrics,
      genMode: t.genMode, ownerName: t.ownerName, ownerAvatar: t.ownerAvatar,
      ownerProvider: t.ownerProvider, isPublic: t.isPublic,
      likes: t.likes, dislikes: t.dislikes + 1, plays: t.plays, created: t.created,
    ));
    await ApiService.dislikeTrack(trackId);
  }

  Future<bool> deleteTrack(String trackId) async {
    final ok = await ApiService.deleteTrack(trackId);
    if (ok) {
      _communityTracks.removeWhere((t) => t.id == trackId);
      _myTracks.removeWhere((t) => t.id == trackId);
      notifyListeners();
    }
    return ok;
  }

  void _updateTrackLocally(String trackId, Track Function(Track) updater) {
    for (int i = 0; i < _communityTracks.length; i++) {
      if (_communityTracks[i].id == trackId) {
        _communityTracks[i] = updater(_communityTracks[i]);
        break;
      }
    }
    for (int i = 0; i < _myTracks.length; i++) {
      if (_myTracks[i].id == trackId) {
        _myTracks[i] = updater(_myTracks[i]);
        break;
      }
    }
    notifyListeners();
  }

  // --- Player ---
  void setCurrentPlayingTrack(Track? track) {
    _currentPlayingTrack = track;
    notifyListeners();
  }

  Future<void> playTrack(Track track) async {
    _currentPlayingTrack = track;
    notifyListeners();

    // 캐시된 오디오가 있으면 로컬 파일 재생
    final cachedPath = await CacheService.getCachedAudioPath(track.id);
    final url = cachedPath ?? track.audioUrl;
    await audioService.play(url, trackId: track.id);

    // 백그라운드에서 오디오 캐싱
    if (cachedPath == null && track.audioUrl.isNotEmpty) {
      CacheService.cacheAudio(track.id, track.audioUrl);
    }
  }

  Future<void> stopPlayback() async {
    await audioService.stop();
    _currentPlayingTrack = null;
    notifyListeners();
  }

  // --- Generate ---
  Future<Track?> generateTrack({
    required String title,
    String? lyrics,
    String genre = 'pop',
    String mood = 'upbeat',
    int bpm = 120,
    bool vocal = true,
    String mode = 'custom',
  }) async {
    _generating = true;
    notifyListeners();

    try {
      final body = {
        'title': title,
        'gen_mode': mode,
        'genre': genre,
        'mood': mood,
        'bpm': bpm,
        'vocal': vocal,
        if (lyrics != null && lyrics.isNotEmpty) 'lyrics': lyrics,
        'owner_name': _currentUser?.name ?? '익명',
        'owner_provider': _currentUser?.provider ?? 'guest',
        'owner_avatar': _currentUser?.avatar ?? '',
      };

      final r = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.apiKieProxy}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (r.statusCode == 200) {
        final data = jsonDecode(r.body);
        if (data['track'] != null) {
          final track = Track.fromJson(data['track']);
          _generating = false;
          notifyListeners();
          await loadCommunityTracks();
          return track;
        }
      }
    } catch (_) {}

    _generating = false;
    notifyListeners();
    return null;
  }

  // --- Announcement ---
  Future<void> checkAnnouncement() async {
    _announcement = await ApiService.getAnnouncement();
    notifyListeners();
  }

  void dismissAnnouncement() {
    _announcement = null;
    notifyListeners();
  }
}
