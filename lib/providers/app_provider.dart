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
    _loginLoading = true;
    notifyListeners();
    try {
      final user = await AuthService.loginWithGoogle();
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

  // --- Community Tracks ---
  Future<void> loadCommunityTracks() async {
    _tracksLoading = true;
    notifyListeners();
    try {
      _communityTracks = await ApiService.getCommunityTracks();
    } catch (_) {}
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
    await ApiService.likeTrack(trackId);
    await loadCommunityTracks();
  }

  // --- Player ---
  void setCurrentPlayingTrack(Track? track) {
    _currentPlayingTrack = track;
    notifyListeners();
  }

  Future<void> playTrack(Track track) async {
    _currentPlayingTrack = track;
    notifyListeners();
    await audioService.play(track.audioUrl, trackId: track.id);
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
