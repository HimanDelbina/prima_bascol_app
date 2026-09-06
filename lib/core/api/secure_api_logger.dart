import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Secure API logging interceptor ensuring:
/// 1. In Release mode, all request/response bodies are completely silenced.
/// 2. In Debug mode, sensitive fields (password, tokens, cookies, patterns, salts)
///    are rigorously redacted.
/// 3. Authorization header is always masked as "Bearer **REDACTED**".
/// 4. Auth endpoints never dump raw credentials or tokens.
class SecureApiLogger extends Interceptor {
  static const Set<String> _sensitiveFields = {
    'password',
    'access',
    'refresh',
    'token',
    'authorization',
    'cookie',
    'pattern',
    'pattern_hash',
    'salt',
    'national_code',
    'national_id',
    'driver_national_code',
    'driver_mobile',
    'mobile',
    'phone',
  };

  static const List<String> _sensitiveEndpoints = [
    '/auth/token/',
    '/auth/token/refresh/',
    '/auth/verify-password/',
  ];

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kReleaseMode) {
      // In production/release, do not log payload details
      return handler.next(options);
    }

    final isSensitiveEndpoint =
        _sensitiveEndpoints.any((ep) => options.path.contains(ep));
    debugPrint('--> ${options.method} ${options.uri}');

    // Sanitize headers
    options.headers.forEach((key, value) {
      final lowerKey = key.toLowerCase();
      if (lowerKey == 'authorization') {
        debugPrint('  $key: Bearer **REDACTED**');
      } else if (lowerKey == 'cookie') {
        debugPrint('  $key: **REDACTED**');
      } else {
        debugPrint('  $key: $value');
      }
    });

    // Sanitize body
    if (options.data != null) {
      if (isSensitiveEndpoint) {
        debugPrint('  Body: [REDACTED_AUTH_PAYLOAD]');
      } else {
        final sanitized = _redactData(options.data);
        debugPrint('  Body: $sanitized');
      }
    }

    debugPrint('--> END ${options.method}');
    return handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kReleaseMode) {
      // In production/release, do not log response payloads
      return handler.next(response);
    }

    final isSensitiveEndpoint = _sensitiveEndpoints
        .any((ep) => response.requestOptions.path.contains(ep));
    debugPrint('<-- ${response.statusCode} ${response.requestOptions.uri}');

    if (response.data != null) {
      if (isSensitiveEndpoint) {
        debugPrint('  Body: [REDACTED_AUTH_PAYLOAD]');
      } else {
        final sanitized = _redactData(response.data);
        debugPrint('  Body: $sanitized');
      }
    }

    debugPrint('<-- END HTTP');
    return handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kReleaseMode) {
      // In production, only log minimal error code without payloads
      debugPrint(
          '[API Error] ${err.response?.statusCode ?? 'NETWORK_ERR'} ${err.requestOptions.method} ${err.requestOptions.path}');
      return handler.next(err);
    }

    debugPrint(
        '<-- ERROR ${err.response?.statusCode} ${err.requestOptions.uri}');
    debugPrint('  Message: ${err.message}');
    if (err.response?.data != null) {
      final isSensitiveEndpoint = _sensitiveEndpoints
          .any((ep) => err.requestOptions.path.contains(ep));
      if (isSensitiveEndpoint) {
        debugPrint('  Error Body: [REDACTED_AUTH_PAYLOAD]');
      } else {
        final sanitized = _redactData(err.response!.data);
        debugPrint('  Error Body: $sanitized');
      }
    }
    debugPrint('<-- END ERROR');
    return handler.next(err);
  }

  @visibleForTesting
  static dynamic redactDataForTesting(dynamic data) => _redactData(data);

  /// Recursively walks JSON-compatible maps/lists to redact sensitive keys
  static dynamic _redactData(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      final result = <String, dynamic>{};
      data.forEach((key, value) {
        final keyStr = key.toString();
        if (_sensitiveFields.contains(keyStr.toLowerCase())) {
          result[keyStr] = '**REDACTED**';
        } else if (value is Map || value is List) {
          result[keyStr] = _redactData(value);
        } else {
          result[keyStr] = value;
        }
      });
      return result;
    } else if (data is List) {
      return data.map(_redactData).toList();
    } else if (data is String) {
      try {
        final decoded = jsonDecode(data);
        return jsonEncode(_redactData(decoded));
      } catch (_) {
        return data;
      }
    }
    return data;
  }
}
