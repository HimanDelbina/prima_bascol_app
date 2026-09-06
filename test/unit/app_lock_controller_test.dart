import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prima_bascol_app/features/auth/data/auth_repository.dart';
import 'package:prima_bascol_app/features/auth/domain/auth_models.dart';
import 'package:prima_bascol_app/features/security/data/biometric_service.dart';
import 'package:prima_bascol_app/features/security/data/pattern_crypto_service.dart';
import 'package:prima_bascol_app/features/security/data/screenshot_protection_service.dart';
import 'package:prima_bascol_app/features/security/data/security_event_logger.dart';
import 'package:prima_bascol_app/features/security/data/security_storage_service.dart';
import 'package:prima_bascol_app/features/security/domain/security_preferences.dart';
import 'package:prima_bascol_app/features/security/presentation/controllers/app_lock_controller.dart';

class FakeAuthRepository implements AuthRepository {
  bool validSession = true;

  @override
  Future<bool> hasValidSession() async => validSession;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final Map<String, String> mockSecureData = {};

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        final key = methodCall.arguments is Map ? methodCall.arguments['key']?.toString() : null;
        if (methodCall.method == 'read') {
          return key != null ? mockSecureData[key] : null;
        } else if (methodCall.method == 'write') {
          final val = methodCall.arguments['value']?.toString() ?? '';
          if (key != null) mockSecureData[key] = val;
          return null;
        } else if (methodCall.method == 'delete') {
          if (key != null) mockSecureData.remove(key);
          return null;
        } else if (methodCall.method == 'deleteAll') {
          mockSecureData.clear();
          return null;
        }
        return null;
      },
    );
  });

  setUp(() {
    mockSecureData.clear();
  });

  final testUser = UserMe(
    id: 42,
    username: 'hemn',
    firstName: 'هیمن',
    lastName: 'دلبینا',
    fullName: 'هیمن دلبینا',
    email: 'hemn@example.com',
    role: UserRole(code: 'operator', label: 'اپراتور باسکول'),
    mobile: '09180000000',
    personnelCode: 'OP-42',
    permissions: ['*'],
    isActive: true,
  );

  group('AppLockController State Machine Tests', () {
    late SecurityStorageService securityStorage;
    late PatternCryptoService patternCrypto;
    late FakeAuthRepository authRepo;
    late SecurityEventLogger eventLogger;
    late ScreenshotProtectionService screenshotProtection;
    late AppLockController controller;

    setUp(() {
      securityStorage = SecurityStorageService();
      patternCrypto = const PatternCryptoService();
      authRepo = FakeAuthRepository();
      eventLogger = SecurityEventLogger();
      screenshotProtection = ScreenshotProtectionService();

      controller = AppLockController(
        securityStorage: securityStorage,
        biometricService: BiometricService(),
        patternCrypto: patternCrypto,
        authRepository: authRepo,
        eventLogger: eventLogger,
        screenshotProtection: screenshotProtection,
      );
    });

    tearDown(() {
      controller.dispose();
    });

    test('initial state is unauthenticated', () {
      expect(controller.state.status, equals(AppLockStatus.unauthenticated));
      expect(controller.state.isLocked, isFalse);
    });

    test('initializeForUser without quick unlock sets authenticatedUnlocked directly', () async {
      await controller.initializeForUser(testUser, isColdStart: true);

      expect(controller.state.status, equals(AppLockStatus.authenticatedUnlocked));
      expect(controller.state.isLocked, isFalse);
      expect(controller.state.user?.id, equals(42));
    });

    test('initializeForUser on cold start with pattern enabled sets authenticatedLocked', () async {
      // Setup pattern in storage
      final salt = patternCrypto.generateSalt();
      final hash = patternCrypto.hashPattern([0, 1, 2, 4, 6], salt);
      await securityStorage.savePattern(userId: testUser.id, hash: hash, salt: salt);
      await securityStorage.savePreferences(
        SecurityPreferences(
          userId: testUser.id,
          patternEnabled: true,
          hasPattern: true,
        ),
      );

      await controller.initializeForUser(testUser, isColdStart: true);

      expect(controller.state.status, equals(AppLockStatus.authenticatedLocked));
      expect(controller.state.isLocked, isTrue);
    });

    test('unlockWithPattern transitions to authenticatedUnlocked on correct pattern', () async {
      final pattern = [0, 1, 2, 4, 6];
      final salt = patternCrypto.generateSalt();
      final hash = patternCrypto.hashPattern(pattern, salt);
      await securityStorage.savePattern(userId: testUser.id, hash: hash, salt: salt);
      await securityStorage.savePreferences(
        SecurityPreferences(
          userId: testUser.id,
          patternEnabled: true,
          hasPattern: true,
        ),
      );

      await controller.initializeForUser(testUser, isColdStart: true);
      expect(controller.state.isLocked, isTrue);

      final success = await controller.unlockWithPattern(pattern);
      expect(success, isTrue);
      expect(controller.state.status, equals(AppLockStatus.authenticatedUnlocked));
      expect(controller.state.isLocked, isFalse);
    });

    test('unlockWithPattern fails on wrong pattern and increments lockout attempts', () async {
      final pattern = [0, 1, 2, 4, 6];
      final wrongPattern = [0, 1, 2, 4, 7];
      final salt = patternCrypto.generateSalt();
      final hash = patternCrypto.hashPattern(pattern, salt);
      await securityStorage.savePattern(userId: testUser.id, hash: hash, salt: salt);
      await securityStorage.savePreferences(
        SecurityPreferences(
          userId: testUser.id,
          patternEnabled: true,
          hasPattern: true,
        ),
      );

      await controller.initializeForUser(testUser, isColdStart: true);

      final success = await controller.unlockWithPattern(wrongPattern);
      expect(success, isFalse);
      expect(controller.state.isLocked, isTrue);
      expect(controller.state.lockoutState.failedAttempts, equals(1));
      expect(controller.state.errorMessage, contains('صحیح نیست'));
    });

    test('session expired backend failure rejects quick unlock', () async {
      final pattern = [0, 1, 2, 4, 6];
      final salt = patternCrypto.generateSalt();
      final hash = patternCrypto.hashPattern(pattern, salt);
      await securityStorage.savePattern(userId: testUser.id, hash: hash, salt: salt);
      await securityStorage.savePreferences(
        SecurityPreferences(
          userId: testUser.id,
          patternEnabled: true,
          hasPattern: true,
        ),
      );

      await controller.initializeForUser(testUser, isColdStart: true);

      // Simulate revoked session in backend
      authRepo.validSession = false;

      final success = await controller.unlockWithPattern(pattern);
      expect(success, isFalse);
      expect(controller.state.status, equals(AppLockStatus.sessionExpired));
      expect(controller.state.errorMessage, contains('منقضی'));
    });

    test('logout resets controller to unauthenticated state', () async {
      await controller.initializeForUser(testUser, isColdStart: false);
      expect(controller.state.status, equals(AppLockStatus.authenticatedUnlocked));

      await controller.handleLogout();
      expect(controller.state.status, equals(AppLockStatus.unauthenticated));
      expect(controller.state.user, isNull);
    });

    test('onInvalidateReauth is triggered on lockApp, logout, and session expiration', () async {
      int invalidateCalls = 0;
      final reauthController = AppLockController(
        securityStorage: securityStorage,
        biometricService: BiometricService(),
        patternCrypto: patternCrypto,
        authRepository: authRepo,
        eventLogger: eventLogger,
        screenshotProtection: screenshotProtection,
        onInvalidateReauth: () {
          invalidateCalls++;
        },
      );

      await securityStorage.savePreferences(
        SecurityPreferences(
          userId: testUser.id,
          patternEnabled: true,
          hasPattern: true,
        ),
      );
      await reauthController.initializeForUser(testUser, isColdStart: false);

      // Lock app
      await reauthController.lockApp();
      expect(invalidateCalls, equals(1));

      // Logout
      await reauthController.handleLogout();
      expect(invalidateCalls, equals(2));

      reauthController.dispose();
    });
  });
}
