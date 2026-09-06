import 'dart:convert';
import '../../../core/api/api_client.dart';
import '../../../core/api/api_endpoints.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/errors/failures.dart';
import '../../../core/storage/local_cache_service.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/auth_models.dart';

class AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;
  final LocalCacheService _localCache;

  AuthRepository({
    required ApiClient apiClient,
    required SecureStorageService secureStorage,
    required LocalCacheService localCache,
  })  : _apiClient = apiClient,
        _secureStorage = secureStorage,
        _localCache = localCache;

  Future<UserMe> login(String username, String password) async {
    try {
      final response = await _apiClient.request(
        ApiEndpoints.token,
        method: 'POST',
        data: {
          'username': username.trim(),
          'password': password,
        },
      );

      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ServerFailure("پاسخ نامعتبر از سرور دریافت شد.");
      }

      final access = data['access']?.toString() ?? '';
      final refresh = data['refresh']?.toString() ?? '';
      if (access.isEmpty || refresh.isEmpty) {
        throw const ServerFailure("توکن معتبر از سرور دریافت نشد.");
      }

      await _secureStorage.saveTokens(accessToken: access, refreshToken: refresh);

      // Extract user from login payload or fetch me
      if (data.containsKey('user') && data['user'] is Map<String, dynamic>) {
        final user = UserMe.fromJson(data['user'] as Map<String, dynamic>);
        await _localCache.cacheUserData(jsonEncode(data['user']));
        return user;
      } else {
        return await fetchCurrentUser();
      }
    } on ApiException catch (e) {
      if (e.code == 'VALIDATION_ERROR') {
        throw ValidationFailure(e.message, fieldErrors: e.fieldErrors);
      } else if (e.statusCode == 401) {
        throw const AuthenticationFailure("نام کاربری یا کلمه عبور صحیح نمی‌باشد.");
      }
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(e.toString());
    }
  }

  Future<UserMe> fetchCurrentUser() async {
    try {
      final response = await _apiClient.request(
        ApiEndpoints.me,
        method: 'GET',
      );
      final user = UserMe.fromJson(response.data as Map<String, dynamic>);
      await _localCache.cacheUserData(jsonEncode(response.data));
      return user;
    } on ApiException catch (e) {
      if (e.statusCode == 401) {
        throw const AuthenticationFailure();
      }
      throw ServerFailure(e.message, code: e.code);
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure(e.toString());
    }
  }

  Future<UserMe?> getCachedUser() async {
    final cached = _localCache.getCachedUserData();
    if (cached != null && cached.isNotEmpty) {
      try {
        final map = jsonDecode(cached) as Map<String, dynamic>;
        return UserMe.fromJson(map);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<void> logout() async {
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken != null) {
        await _apiClient.request(
          ApiEndpoints.logout,
          method: 'POST',
          data: {'refresh': refreshToken},
        );
      }
    } catch (_) {
      // Ignore network errors during logout
    } finally {
      await _secureStorage.clearTokens();
      await _localCache.clearAll();
    }
  }

  Future<bool> hasValidSession() async {
    final access = await _secureStorage.getAccessToken();
    return access != null && access.isNotEmpty;
  }

  Future<bool> verifyPassword(String password) async {
    try {
      final response = await _apiClient.request(
        ApiEndpoints.verifyPassword,
        method: 'POST',
        data: {'password': password},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return data['valid'] == true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}
