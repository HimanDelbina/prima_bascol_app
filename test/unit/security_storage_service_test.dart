import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prima_bascol_app/features/security/data/security_storage_service.dart';
import 'package:prima_bascol_app/features/security/domain/lockout_state.dart';
import 'package:prima_bascol_app/features/security/domain/security_preferences.dart';
import 'package:prima_bascol_app/features/security/domain/unlock_method.dart';

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

  group('SecurityStorageService User Isolation Tests', () {
    final storageService = SecurityStorageService();

    test('User A preferences and pattern are completely isolated from User B', () async {
      const userAId = 101;
      const userBId = 102;

      // Save User A pattern
      await storageService.savePattern(
        userId: userAId,
        hash: 'hash_user_a',
        salt: 'salt_user_a',
      );
      await storageService.savePreferences(
        const SecurityPreferences(
          userId: userAId,
          biometricEnabled: true,
          patternEnabled: true,
          preferredUnlockMethod: UnlockMethod.pattern,
          hasPattern: true,
        ),
      );

      // Verify User A data is present
      final patternA = await storageService.getPatternData(userAId);
      expect(patternA.hash, equals('hash_user_a'));
      expect(patternA.salt, equals('salt_user_a'));

      final prefsA = await storageService.loadPreferences(userAId);
      expect(prefsA.biometricEnabled, isTrue);
      expect(prefsA.patternEnabled, isTrue);
      expect(prefsA.preferredUnlockMethod, equals(UnlockMethod.pattern));

      // Verify User B has NO pattern and default preferences (User Isolation)
      final patternB = await storageService.getPatternData(userBId);
      expect(patternB.hash, isNull);
      expect(patternB.salt, isNull);

      final prefsB = await storageService.loadPreferences(userBId);
      expect(prefsB.biometricEnabled, isFalse);
      expect(prefsB.patternEnabled, isFalse);
      expect(prefsB.hasPattern, isFalse);
      expect(prefsB.isQuickUnlockEnabled, isFalse);
    });

    test('clearPattern only removes pattern for specified user', () async {
      const userAId = 101;
      const userBId = 102;

      await storageService.savePattern(userId: userAId, hash: 'hA', salt: 'sA');
      await storageService.savePattern(userId: userBId, hash: 'hB', salt: 'sB');

      await storageService.clearPattern(userAId);

      final patternA = await storageService.getPatternData(userAId);
      final patternB = await storageService.getPatternData(userBId);

      expect(patternA.hash, isNull);
      expect(patternB.hash, equals('hB'));
    });

    test('lockout state is persisted and loaded correctly per user', () async {
      const userAId = 101;
      final lockedUntil = DateTime.now().add(const Duration(seconds: 45));

      final state = LockoutState(
        failedAttempts: 5,
        lockedUntil: lockedUntil,
      );
      await storageService.saveLockoutState(userAId, state);

      final loaded = await storageService.loadLockoutState(userAId);
      expect(loaded.failedAttempts, equals(5));
      expect(loaded.isLocked, isTrue);
      expect(loaded.remainingSeconds, greaterThan(0));

      await storageService.clearLockoutState(userAId);
      final cleared = await storageService.loadLockoutState(userAId);
      expect(cleared.failedAttempts, equals(0));
      expect(cleared.isLocked, isFalse);
    });
  });
}
