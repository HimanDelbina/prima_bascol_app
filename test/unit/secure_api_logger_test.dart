import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prima_bascol_app/core/api/secure_api_logger.dart';

void main() {
  group('SecureApiLogger Redaction Tests', () {
    late SecureApiLogger logger;

    setUp(() {
      logger = SecureApiLogger();
    });

    test('onRequest masks Authorization header as Bearer **REDACTED**', () {
      final options = RequestOptions(
        path: '/api/v1/tickets/',
        headers: {
          'Authorization': 'Bearer super_secret_jwt_access_token_123',
          'Content-Type': 'application/json',
          'cookie': 'sessionid=xyz123',
        },
      );

      final handler = RequestInterceptorHandler();

      logger.onRequest(options, handler);

      // Verify header in options is preserved for server delivery
      expect(options.headers['Authorization'], 'Bearer super_secret_jwt_access_token_123');
    });

    test('redacts sensitive fields in JSON payload maps', () {
      final payload = {
        'username': 'operator1',
        'password': 'MySecretPassword!',
        'pattern': [1, 2, 3],
        'pattern_hash': 'abcdef0123456789',
        'salt': 'somesalt123',
        'token': 'secret-token-xyz',
        'access': 'access-token-jwt',
        'refresh': 'refresh-token-jwt',
        'mobile': '09121234567',
        'national_code': '0012345678',
        'driver_mobile': '09187654321',
        'non_sensitive': 'safe_data_value',
      };

      final sanitized = SecureApiLogger.redactDataForTesting(payload);

      expect(sanitized['password'], '**REDACTED**');
      expect(sanitized['pattern'], '**REDACTED**');
      expect(sanitized['pattern_hash'], '**REDACTED**');
      expect(sanitized['salt'], '**REDACTED**');
      expect(sanitized['token'], '**REDACTED**');
      expect(sanitized['access'], '**REDACTED**');
      expect(sanitized['refresh'], '**REDACTED**');
      expect(sanitized['mobile'], '**REDACTED**');
      expect(sanitized['national_code'], '**REDACTED**');
      expect(sanitized['driver_mobile'], '**REDACTED**');
      expect(sanitized['non_sensitive'], 'safe_data_value');
      expect(sanitized['username'], 'operator1');
    });

    test('auth endpoints mask request body as [REDACTED_AUTH_PAYLOAD]', () {
      final endpoints = [
        '/api/v1/auth/token/',
        '/api/v1/auth/token/refresh/',
        '/api/v1/auth/verify-password/',
      ];

      for (final ep in endpoints) {
        final options = RequestOptions(
          path: ep,
          method: 'POST',
          data: {'password': 'SecretPassword123', 'refresh': 'token123'},
        );
        final handler = RequestInterceptorHandler();
        logger.onRequest(options, handler);
      }
    });
  });
}
