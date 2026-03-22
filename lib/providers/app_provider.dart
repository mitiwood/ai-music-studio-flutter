import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user.dart';
import '../models/track.dart';
import '../services/api_service.dart';
import '../services/audio_service.dart';

class AppProvider extends ChangeNotifier {
  AppUser? _user;
  List<Track> _communityTracks = [];
  List<Track> _myTracks = [];
  List<Track> _history = [];
  bool _isLoading = false;
  int _currentTab = 0;
  ThemeMode _themeMode = ThemeMode.dark;
  Map<String, dynamic>? _attendance;
  Map<String, dynamic>? _tossConfig;
  final AudioPlayerService _audio = AudioPlayerService();

  AppUser? get user => _user;
  List<Track> get communityTracks => _communityTracks;
  List<Track> get myTracks => _myTracks;
  List<Track> get history => _history;
  bool get isLoading => _isLoading;
  int get currentTab => _currentTab;
  ThemeMode get themeMode => _themeMode;
  Map<String, dynamic>? get attendance => _attendance;
  Map<String, dynamic>? get tossConfig => _tossConfig;
  AudioPlayerService get audio => _audio;
  bool get isLoggedIn => _user != null && !_user!.isGuest;

  // ── Init ──
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('kms_user');
    if (userJson != null) {
      _user = AppUser.fromJson(jsonDecode(userJson));
    }
    final theme = prefs.getString('kms_theme') ?? 'dark';
    _themeMode = theme == 'light' ? ThemeMode.light : ThemeMode.dark;
    // Load history from local storage
    final histJson = prefs.getString('kms_history');
    if (histJson != null) {
      final list = jsonDecode(histJson) as List;
      _history = list.map<Track>((j) => Track.fromJson(j)).toList();
    }
    notifyListeners();
    // Background loads
    loadCommunityTracks();
    loadTossConfig();
    if (isLoggedIn) loadAttendance();
  }

  // ── Auth ──
  Future<void> setUser(AppUser user) async {
    _user = user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kms_user', jsonEncode(user.toJson()));
    notifyListeners();
    loadAttendance();
  }

  Future<void> logout() async {
    _user = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('kms_user');
    notifyListeners();
  }

  // ── Theme ──
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kms_theme', _themeMode == ThemeMode.light ? 'light' : 'dark');
    notifyListeners();
  }

  // ── Tab ──
  void setTab(int index) { _currentTab = index; notifyListeners(); }

  // ── Community Tracks ──
  Future<void> loadCommunityTracks() async {
    try {
      _communityTracks = await ApiService.getTracks(publicOnly: true);
      _communityTracks.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
      notifyListeners();
    } catch (e) { debugPrint('[loadCommunity] $e'); }
  }

  // ── My Tracks ──
  Future<void> loadMyTracks() async {
    if (_user == null) return;
    try {
      final all = await ApiService.getTracks(publicOnly: false);
      _myTracks = all.where((t) => t.ownerName == _user!.name && t.ownerProvider == _user!.provider).toList();
      _myTracks.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
      notifyListeners();
    } catch (e) { debugPrint('[loadMyTracks] $e'); }
  }

  // ── History ──
  Future<void> addToHistory(Track track) async {
    _history.removeWhere((t) => t.id == track.id);
    _history.insert(0, track);
    if (_history.length > 200) _history = _history.sublist(0, 200);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('kms_history', jsonEncode(_history.map((t) => t.toJson()).toList()));
    notifyListeners();
  }

  // ── Player ──
  Future<void> playTrack(Track track) async {
    if (track.audioUrl == null || track.audioUrl!.isEmpty) return;
    await _audio.play(track.audioUrl!, trackId: track.id, title: track.title, imageUrl: track.imageUrl);
    addToHistory(track);
    notifyListeners();
  }

  // ── Like ──
  Future<void> toggleLike(Track track) async {
    if (_user == null) return;
    final newLiked = !track.liked;
    track.liked = newLiked;
    if (newLiked) track.disliked = false;
    notifyListeners();
    await ApiService.likeTrack(track.id, _user!.name, _user!.provider, type: newLiked ? 'like' : 'unlike');
  }

  // ── Attendance ──
  Future<void> loadAttendance() async {
    if (_user == null || _user!.isGuest) return;
    try {
      _attendance = await ApiService.getAttendance(_user!.name, _user!.provider);
      notifyListeners();
    } catch (_) {}
  }

  Future<Map<String, dynamic>> doCheckIn() async {
    if (_user == null) return {'ok': false};
    final result = await ApiService.checkIn(_user!.name, _user!.provider);
    if (result['ok'] == true) await loadAttendance();
    return result;
  }

  // ── Toss Config ──
  Future<void> loadTossConfig() async {
    try {
      _tossConfig = await ApiService.getTossConfig();
      notifyListeners();
    } catch (_) {}
  }
}
