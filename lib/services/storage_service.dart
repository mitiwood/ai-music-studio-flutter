import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

/// SharedPreferences 기반 로컬 저장소 서비스
class StorageService {
  static StorageService? _instance;
  late SharedPreferences _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    if (_instance == null) {
      _instance = StorageService._();
      _instance!._prefs = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // Theme
  String get themeMode => _prefs.getString(AppConstants.keyThemeMode) ?? 'dark';
  Future<void> setThemeMode(String mode) => _prefs.setString(AppConstants.keyThemeMode, mode);

  // Auth
  String? get authToken => _prefs.getString(AppConstants.keyAuthToken);
  Future<void> setAuthToken(String? token) {
    if (token == null) return _prefs.remove(AppConstants.keyAuthToken);
    return _prefs.setString(AppConstants.keyAuthToken, token);
  }

  String? get userId => _prefs.getString(AppConstants.keyUserId);
  Future<void> setUserId(String? id) {
    if (id == null) return _prefs.remove(AppConstants.keyUserId);
    return _prefs.setString(AppConstants.keyUserId, id);
  }

  String? get userName => _prefs.getString(AppConstants.keyUserName);
  Future<void> setUserName(String? name) {
    if (name == null) return _prefs.remove(AppConstants.keyUserName);
    return _prefs.setString(AppConstants.keyUserName, name);
  }

  // Notifications
  bool get notifEnabled => _prefs.getBool(AppConstants.keyNotifEnabled) ?? true;
  Future<void> setNotifEnabled(bool enabled) => _prefs.setBool(AppConstants.keyNotifEnabled, enabled);

  // Last URL
  String? get lastVisitedUrl => _prefs.getString(AppConstants.keyLastVisitedUrl);
  Future<void> setLastVisitedUrl(String url) => _prefs.setString(AppConstants.keyLastVisitedUrl, url);

  // App open count
  int get appOpenCount => _prefs.getInt(AppConstants.keyAppOpenCount) ?? 0;
  Future<void> incrementAppOpenCount() => _prefs.setInt(AppConstants.keyAppOpenCount, appOpenCount + 1);

  // First launch
  bool get isFirstLaunch => _prefs.getBool(AppConstants.keyFirstLaunch) ?? true;
  Future<void> setFirstLaunchDone() => _prefs.setBool(AppConstants.keyFirstLaunch, false);

  // Download path
  String? get downloadPath => _prefs.getString(AppConstants.keyDownloadPath);
  Future<void> setDownloadPath(String path) => _prefs.setString(AppConstants.keyDownloadPath, path);

  // Generic
  Future<void> clear() => _prefs.clear();
}
