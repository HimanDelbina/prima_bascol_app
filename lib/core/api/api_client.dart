import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../storage/secure_storage_service.dart';
import 'api_endpoints.dart';
import 'api_exception.dart';
import 'secure_api_logger.dart';

typedef OnSessionExpiredCallback = void Function();

class ApiClient {
  late final Dio dio;
  final SecureStorageService _secureStorage;
  OnSessionExpiredCallback? onSessionExpired;
  bool _isRefreshing = false;
  final List<Completer<String?>> _refreshCompleters = [];

  ApiClient({
    required SecureStorageService secureStorage,
    this.onSessionExpired,
    String? customBaseUrl,
  }) : _secureStorage = secureStorage {
    dio = Dio(
      BaseOptions(
        baseUrl: customBaseUrl ?? AppConfig.apiBaseUrl,
        connectTimeout: const Duration(milliseconds: AppConfig.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeoutMs),
        sendTimeout: const Duration(milliseconds: AppConfig.sendTimeoutMs),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add Access Token if available and not public endpoint
          final isPublic = options.path.contains('/auth/token/') || options.path.contains('/health/');
          if (!isPublic) {
            final token = await _secureStorage.getAccessToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Handle 401 Unauthorized -> Refresh Token
          if (error.response?.statusCode == 401 && !error.requestOptions.path.contains('/auth/token/')) {
            final refreshedToken = await _handleRefreshToken();
            if (refreshedToken != null) {
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $refreshedToken';
              try {
                final response = await dio.fetch(opts);
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            } else {
              await _secureStorage.clearTokens();
              onSessionExpired?.call();
            }
          }
          return handler.next(error);
        },
      ),
    );

    dio.interceptors.add(SecureApiLogger());
  }

  Future<String?> _handleRefreshToken() async {
    if (_isRefreshing) {
      final completer = Completer<String?>();
      _refreshCompleters.add(completer);
      return completer.future;
    }

    _isRefreshing = true;
    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _resolveRefreshQueue(null);
        return null;
      }

      final refreshDio = Dio(
        BaseOptions(
          baseUrl: dio.options.baseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      final response = await refreshDio.post(
        ApiEndpoints.tokenRefresh,
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200 && response.data != null) {
        final newAccess = response.data['access']?.toString();
        final newRefresh = response.data['refresh']?.toString() ?? refreshToken;
        if (newAccess != null) {
          await _secureStorage.saveTokens(accessToken: newAccess, refreshToken: newRefresh);
          _resolveRefreshQueue(newAccess);
          return newAccess;
        }
      }
      _resolveRefreshQueue(null);
      return null;
    } catch (e) {
      _resolveRefreshQueue(null);
      return null;
    } finally {
      _isRefreshing = false;
    }
  }

  void _resolveRefreshQueue(String? token) {
    for (var c in _refreshCompleters) {
      if (!c.isCompleted) {
        c.complete(token);
      }
    }
    _refreshCompleters.clear();
  }

  // Generic Request Helper with Exception Translation
  Future<Response<T>> request<T>(
    String path, {
    String method = 'GET',
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final opts = options ?? Options();
      opts.method = method;

      return await dio.request<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: opts,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _parseDioError(e);
    } catch (e) {
      throw ApiException(message: "خطای ناشناخته در ارتباط: ${e.toString()}");
    }
  }

  ApiException _parseDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return ApiException(
        message: "مهلت زمانی ارتباط با سرور به پایان رسید. لطفاً مجدداً تلاش کنید.",
        code: "TIMEOUT_ERROR",
        statusCode: e.response?.statusCode,
      );
    }

    if (e.type == DioExceptionType.connectionError) {
      return ApiException(
        message: "ارتباط با سرور برقرار نیست. لطفاً اتصال اینترنت خود را بررسی نمایید.",
        code: "NETWORK_ERROR",
        statusCode: e.response?.statusCode,
      );
    }

    if (e.response != null && e.response?.data != null) {
      if (e.response!.data is Map<String, dynamic>) {
        return ApiException.fromResponse(e.response!.data, e.response?.statusCode);
      } else if (e.response!.data is List<int>) {
        try {
          final decoded = utf8.decode(e.response!.data as List<int>);
          final parsed = jsonDecode(decoded);
          if (parsed is Map<String, dynamic>) {
            return ApiException.fromResponse(parsed, e.response?.statusCode);
          }
        } catch (_) {}
      } else if (e.response!.data is String) {
        try {
          final parsed = jsonDecode(e.response!.data as String);
          if (parsed is Map<String, dynamic>) {
            return ApiException.fromResponse(parsed, e.response?.statusCode);
          }
        } catch (_) {}
      }
    }

    return ApiException(
      message: e.message ?? "خطای ناشناخته رخ داده است.",
      code: "UNKNOWN_ERROR",
      statusCode: e.response?.statusCode,
    );
  }
}
