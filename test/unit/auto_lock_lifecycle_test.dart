import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prima_bascol_app/core/config/app_config.dart';
import 'package:prima_bascol_app/features/auth/data/auth_repository.dart';
import 'package:prima_bascol_app/features/auth/domain/auth_models.dart';
import 'package:prima_bascol_app/features/auth/presentation/auth_providers.dart';
import 'package:prima_bascol_app/features/security/data/biometric_service.dart';
import 'package:prima_bascol_app/features/security/data/pattern_crypto_service.dart';
import 'package:prima_bascol_app/features/security/data/screenshot_protection_service.dart';
import 'package:prima_bascol_app/features/security/data/security_event_logger.dart';
import 'package:prima_bascol_app/features/security/data/security_storage_service.dart';
import 'package:prima_bascol_app/features/security/domain/security_config.dart';
import 'package:prima_bascol_app/features/security/domain/security_preferences.dart';
import 'package:prima_bascol_app/features/security/domain/unlock_method.dart';
import 'package:prima_bascol_app/features/security/presentation/controllers/app_lock_controller.dart';
import 'package:prima_bascol_app/features/security/presentation/controllers/security_providers.dart';
import 'package:prima_bascol_app/features/security/presentation/widgets/app_lock_gate.dart';

class MockAuthRepo implements AuthRepository {
  @override
  Future<bool> hasValidSession() async => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final Map<String, String> mockStorage = {};

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (MethodCall methodCall) async {
        final key = methodCall.arguments is Map
            ? methodCall.arguments['key']?.toString()
            : null;
        if (methodCall.method == 'read') {
          return key != null ? mockStorage[key] : null;
        } else if (methodCall.method == 'write') {
          final val = methodCall.arguments['value']?.toString() ?? '';
          if (key != null) mockStorage[key] = val;
          return null;
        } else if (methodCall.method == 'delete') {
          if (key != null) mockStorage.remove(key);
          return null;
        }
        return null;
      },
    );
  });

  tearDown(() {
    mockStorage.clear();
  });

  final testUser = UserMe(
    id: 1,
    username: 'operator',
    firstName: 'علی',
    lastName: 'رضایی',
    fullName: 'علی رضایی',
    email: 'ali@example.com',
    role: UserRole(code: 'operator', label: 'اپراتور باسکول'),
    mobile: '09120000000',
    personnelCode: 'OP-01',
    permissions: ['*'],
    isActive: true,
  );

  group('Auto Lock Lifecycle & State Preservation Tests', () {
    test('backgrounding less than timeout does not lock the app', () async {
      final storage = SecurityStorageService();
      final controller = AppLockController(
        securityStorage: storage,
        biometricService: BiometricService(),
        patternCrypto: const PatternCryptoService(),
        authRepository: MockAuthRepo(),
        eventLogger: SecurityEventLogger(),
        screenshotProtection: ScreenshotProtectionService(),
      );

      // Initialize with 1 minute (60s) timeout
      await storage.savePattern(userId: 1, hash: 'test_hash', salt: 'test_salt');
      await storage.savePreferences(
        const SecurityPreferences(
          userId: 1,
          patternEnabled: true,
          hasPattern: true,
          autoLockDuration: SecurityConfig.autoLock1Minute,
        ),
      );

      await controller.initializeForUser(testUser, isColdStart: false);
      expect(controller.state.isLocked, isFalse);

      // Simulate backgrounding 10 seconds ago (less than 60s)
      await storage.recordBackgroundTimestamp(
        DateTime.now().subtract(const Duration(seconds: 10)),
      );

      // Simulate app resumed
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.state.isLocked, isFalse);
      controller.dispose();
    });

    test('backgrounding greater than timeout locks the app', () async {
      final storage = SecurityStorageService();
      final controller = AppLockController(
        securityStorage: storage,
        biometricService: BiometricService(),
        patternCrypto: const PatternCryptoService(),
        authRepository: MockAuthRepo(),
        eventLogger: SecurityEventLogger(),
        screenshotProtection: ScreenshotProtectionService(),
      );

      // Initialize with 30s timeout
      await storage.savePattern(userId: 1, hash: 'test_hash', salt: 'test_salt');
      await storage.savePreferences(
        const SecurityPreferences(
          userId: 1,
          patternEnabled: true,
          hasPattern: true,
          autoLockDuration: SecurityConfig.autoLock30Seconds,
        ),
      );

      await controller.initializeForUser(testUser, isColdStart: false);
      expect(controller.state.isLocked, isFalse);

      // Simulate backgrounding 40 seconds ago (greater than 30s)
      await storage.recordBackgroundTimestamp(
        DateTime.now().subtract(const Duration(seconds: 40)),
      );

      // Simulate app resumed
      controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.state.isLocked, isTrue);
      controller.dispose();
    });

    testWidgets('AppLockGate preserves form data across lock/unlock cycle',
        (WidgetTester tester) async {
      final textController = TextEditingController();

      late AppLockController appLockCtrl;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepo() as dynamic),
            authControllerProvider.overrideWith((ref) {
              final ctrl = AuthController(MockAuthRepo() as dynamic);
              ctrl.state = AuthState(user: testUser);
              return ctrl;
            }),
            appLockControllerProvider.overrideWith((ref) {
              appLockCtrl = AppLockController(
                securityStorage: ref.watch(securityStorageServiceProvider),
                biometricService: ref.watch(biometricServiceProvider),
                patternCrypto: ref.watch(patternCryptoServiceProvider),
                authRepository: MockAuthRepo(),
                eventLogger: ref.watch(securityEventLoggerProvider),
                screenshotProtection: ref.watch(screenshotProtectionServiceProvider),
              );
              appLockCtrl.state = AppLockState(
                status: AppLockStatus.authenticatedUnlocked,
                user: testUser,
                preferences: const SecurityPreferences(
                  userId: 1,
                  patternEnabled: true,
                  hasPattern: true,
                  preferredUnlockMethod: UnlockMethod.pattern,
                ),
              );
              return appLockCtrl;
            }),
          ],
          child: MaterialApp(
            home: AppLockGate(
              child: Scaffold(
                body: Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    controller: textController,
                    decoration: const InputDecoration(labelText: 'شماره پلاک'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      // 1. Enter partial form data (Weighbridge plate)
      await tester.enterText(find.byType(TextField), '12B345-Iran77');
      await tester.pump();
      expect(textController.text, equals('12B345-Iran77'));

      // 2. Lock the app (simulate auto-lock triggering overlay)
      await appLockCtrl.lockApp();
      await tester.pump();

      // AppLockScreen overlay is now mounted above the form
      expect(find.text(AppConfig.appName), findsOneWidget);

      // 3. Unlock the app
      appLockCtrl.state = appLockCtrl.state.copyWith(
        status: AppLockStatus.authenticatedUnlocked,
      );
      await tester.pump();

      // Form is still present with exact input preserved!
      expect(find.text('12B345-Iran77'), findsOneWidget);
      expect(textController.text, equals('12B345-Iran77'));

      textController.dispose();
    });

    testWidgets('PrivacyOverlay renders security message and hides content in app switcher',
        (WidgetTester tester) async {
      late AppLockController appLockCtrl;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(MockAuthRepo() as dynamic),
            authControllerProvider.overrideWith((ref) {
              final ctrl = AuthController(MockAuthRepo() as dynamic);
              ctrl.state = AuthState(user: testUser);
              return ctrl;
            }),
            appLockControllerProvider.overrideWith((ref) {
              appLockCtrl = AppLockController(
                securityStorage: ref.watch(securityStorageServiceProvider),
                biometricService: ref.watch(biometricServiceProvider),
                patternCrypto: ref.watch(patternCryptoServiceProvider),
                authRepository: MockAuthRepo(),
                eventLogger: ref.watch(securityEventLoggerProvider),
                screenshotProtection: ref.watch(screenshotProtectionServiceProvider),
              );
              appLockCtrl.state = AppLockState(
                status: AppLockStatus.authenticatedUnlocked,
                user: testUser,
              );
              return appLockCtrl;
            }),
          ],
          child: const MaterialApp(
            home: AppLockGate(
              child: Scaffold(
                body: Text('اطلاعات محرمانه باسکول: 45,200 کیلوگرم'),
              ),
            ),
          ),
        ),
      );

      // Before backgrounding, content is visible
      expect(find.text('اطلاعات محرمانه باسکول: 45,200 کیلوگرم'), findsOneWidget);
      expect(find.text('سامانه به دلایل امنیتی قفل شده است'), findsNothing);

      // Simulate App entering inactive / backgrounded (e.g. App Switcher)
      appLockCtrl.didChangeAppLifecycleState(AppLifecycleState.inactive);
      await tester.pump();

      // Privacy overlay is now active
      expect(find.text('سامانه به دلایل امنیتی قفل شده است'), findsOneWidget);
      expect(find.text(AppConfig.appName), findsOneWidget);
    });
  });
}
