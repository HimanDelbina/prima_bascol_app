import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(encryptedSharedPreferences: true),
          iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
        );

  static const String _keyAccessToken = 'pb_access_token';
  static const String _keyRefreshToken = 'pb_refresh_token';

  Future<void> saveTokens({required String accessToken, required String refreshToken}) async {
    try {
      await Future.wait([
        _storage.write(key: _keyAccessToken, value: accessToken).timeout(const Duration(seconds: 3)),
        _storage.write(key: _keyRefreshToken, value: refreshToken).timeout(const Duration(seconds: 3)),
      ]);
    } catch (e) {
      // Fallback or ignore
    }
  }

  Future<String?> getAccessToken() async {
    try {
      return await _storage.read(key: _keyAccessToken).timeout(const Duration(seconds: 2));
    } catch (e) {
      return null;
    }
  }

  Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _keyRefreshToken).timeout(const Duration(seconds: 2));
    } catch (e) {
      return null;
    }
  }

  Future<void> clearTokens() async {
    try {
      await Future.wait([
        _storage.delete(key: _keyAccessToken).timeout(const Duration(seconds: 2)),
        _storage.delete(key: _keyRefreshToken).timeout(const Duration(seconds: 2)),
      ]);
    } catch (e) {
      // Fallback or ignore
    }
  }
}
