import 'package:shared_preferences/shared_preferences.dart';

class LocalCacheService {
  final SharedPreferences _prefs;

  LocalCacheService(this._prefs);

  static Future<LocalCacheService> init() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalCacheService(prefs);
  }

  static const String _keyThemeMode = 'pb_theme_mode';
  static const String _keyUserCache = 'pb_user_cache';

  Future<void> setThemeMode(String mode) async {
    await _prefs.setString(_keyThemeMode, mode);
  }

  String getThemeMode() {
    return _prefs.getString(_keyThemeMode) ?? 'light';
  }

  Future<void> cacheUserData(String jsonStr) async {
    await _prefs.setString(_keyUserCache, jsonStr);
  }

  String? getCachedUserData() {
    return _prefs.getString(_keyUserCache);
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }
}
