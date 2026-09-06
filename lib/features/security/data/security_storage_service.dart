import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../domain/lockout_state.dart';
import '../domain/security_config.dart';
import '../domain/security_preferences.dart';
import '../domain/unlock_method.dart';

class SecurityStorageService {
  final FlutterSecureStorage _storage;

  SecurityStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  static const String _keyLastUserId = 'pb_sec_last_user_id';
  static const String _keyLastBackgroundAt = 'pb_sec_last_background_at';

  String _keyBiometric(int userId) => 'pb_sec_${userId}_biometric_enabled';
  String _keyPatternEnabled(int userId) => 'pb_sec_${userId}_pattern_enabled';
  String _keyPatternHash(int userId) => 'pb_sec_${userId}_pattern_hash';
  String _keyPatternSalt(int userId) => 'pb_sec_${userId}_pattern_salt';
  String _keyPreferredMethod(int userId) => 'pb_sec_${userId}_preferred_method';
  String _keyAutoLock(int userId) => 'pb_sec_${userId}_auto_lock_duration';
  String _keyFailedAttempts(int userId) => 'pb_sec_${userId}_failed_attempts';
  String _keyLockoutUntil(int userId) => 'pb_sec_${userId}_lockout_until';
  String _keyScreenshot(int userId) => 'pb_sec_${userId}_screenshot_protection';
  String _keyReauthTimeout(int userId) => 'pb_sec_${userId}_reauth_timeout_min';
  String _keyLastUnlockedAt(int userId) => 'pb_sec_${userId}_last_unlocked_at';

  Future<void> setLastActiveUserId(int userId) async {
    try {
      await _storage.write(key: _keyLastUserId, value: userId.toString());
    } catch (_) {}
  }

  Future<int?> getLastActiveUserId() async {
    try {
      final val = await _storage.read(key: _keyLastUserId);
      return val != null ? int.tryParse(val) : null;
    } catch (_) {
      return null;
    }
  }

  Future<SecurityPreferences> loadPreferences(int userId) async {
    try {
      final bioStr = await _storage.read(key: _keyBiometric(userId));
      final patStr = await _storage.read(key: _keyPatternEnabled(userId));
      final prefMethodStr = await _storage.read(key: _keyPreferredMethod(userId));
      final autoLockStr = await _storage.read(key: _keyAutoLock(userId));
      final hash = await _storage.read(key: _keyPatternHash(userId));
      final screenshotStr = await _storage.read(key: _keyScreenshot(userId));
      final reauthTimeoutStr = await _storage.read(key: _keyReauthTimeout(userId));
      final lastUnlockedStr = await _storage.read(key: _keyLastUnlockedAt(userId));

      final bool biometricEnabled = bioStr == 'true';
      final bool patternEnabled = patStr == 'true';
      final bool hasPattern = hash != null && hash.isNotEmpty;
      final bool screenshotProtectionEnabled = screenshotStr != 'false'; // default true
      final int reauthTimeout = reauthTimeoutStr != null
          ? int.tryParse(reauthTimeoutStr) ?? SecurityConfig.defaultReauthTimeoutMinutes
          : SecurityConfig.defaultReauthTimeoutMinutes;

      DateTime? lastUnlockedAt;
      if (lastUnlockedStr != null) {
        final millis = int.tryParse(lastUnlockedStr);
        if (millis != null) {
          lastUnlockedAt = DateTime.fromMillisecondsSinceEpoch(millis);
        }
      }

      UnlockMethod preferredMethod = UnlockMethod.biometric;
      if (prefMethodStr == UnlockMethod.pattern.name) {
        preferredMethod = UnlockMethod.pattern;
      }

      final int autoLock = autoLockStr != null
          ? int.tryParse(autoLockStr) ?? SecurityConfig.autoLock1Minute
          : SecurityConfig.autoLock1Minute;

      return SecurityPreferences(
        userId: userId,
        biometricEnabled: biometricEnabled,
        patternEnabled: patternEnabled && hasPattern,
        preferredUnlockMethod: preferredMethod,
        autoLockDuration: autoLock,
        hasPattern: hasPattern,
        screenshotProtectionEnabled: screenshotProtectionEnabled,
        sensitiveActionReauthTimeoutMinutes: reauthTimeout,
        lastUnlockedAt: lastUnlockedAt,
      );
    } catch (_) {
      return SecurityPreferences(userId: userId);
    }
  }

  Future<void> savePreferences(SecurityPreferences prefs) async {
    try {
      await Future.wait([
        _storage.write(
          key: _keyBiometric(prefs.userId),
          value: prefs.biometricEnabled.toString(),
        ),
        _storage.write(
          key: _keyPatternEnabled(prefs.userId),
          value: prefs.patternEnabled.toString(),
        ),
        _storage.write(
          key: _keyPreferredMethod(prefs.userId),
          value: prefs.preferredUnlockMethod.name,
        ),
        _storage.write(
          key: _keyAutoLock(prefs.userId),
          value: prefs.autoLockDuration.toString(),
        ),
        _storage.write(
          key: _keyScreenshot(prefs.userId),
          value: prefs.screenshotProtectionEnabled.toString(),
        ),
        _storage.write(
          key: _keyReauthTimeout(prefs.userId),
          value: prefs.sensitiveActionReauthTimeoutMinutes.toString(),
        ),
      ]);
    } catch (_) {}
  }

  Future<void> savePattern({
    required int userId,
    required String hash,
    required String salt,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _keyPatternHash(userId), value: hash),
        _storage.write(key: _keyPatternSalt(userId), value: salt),
        _storage.write(key: _keyPatternEnabled(userId), value: 'true'),
      ]);
    } catch (_) {}
  }

  Future<({String? hash, String? salt})> getPatternData(int userId) async {
    try {
      final hash = await _storage.read(key: _keyPatternHash(userId));
      final salt = await _storage.read(key: _keyPatternSalt(userId));
      return (hash: hash, salt: salt);
    } catch (_) {
      return (hash: null, salt: null);
    }
  }

  Future<void> clearPattern(int userId) async {
    try {
      await Future.wait([
        _storage.delete(key: _keyPatternHash(userId)),
        _storage.delete(key: _keyPatternSalt(userId)),
        _storage.write(key: _keyPatternEnabled(userId), value: 'false'),
      ]);
    } catch (_) {}
  }

  Future<LockoutState> loadLockoutState(int userId) async {
    try {
      final attemptsStr = await _storage.read(key: _keyFailedAttempts(userId));
      final untilStr = await _storage.read(key: _keyLockoutUntil(userId));

      final attempts = attemptsStr != null ? int.tryParse(attemptsStr) ?? 0 : 0;
      DateTime? lockedUntil;
      if (untilStr != null) {
        final millis = int.tryParse(untilStr);
        if (millis != null) {
          lockedUntil = DateTime.fromMillisecondsSinceEpoch(millis);
        }
      }

      return LockoutState(
        failedAttempts: attempts,
        lockedUntil: lockedUntil,
      );
    } catch (_) {
      return const LockoutState();
    }
  }

  Future<void> saveLockoutState(int userId, LockoutState state) async {
    try {
      await _storage.write(
        key: _keyFailedAttempts(userId),
        value: state.failedAttempts.toString(),
      );
      if (state.lockedUntil != null) {
        await _storage.write(
          key: _keyLockoutUntil(userId),
          value: state.lockedUntil!.millisecondsSinceEpoch.toString(),
        );
      } else {
        await _storage.delete(key: _keyLockoutUntil(userId));
      }
    } catch (_) {}
  }

  Future<void> clearLockoutState(int userId) async {
    try {
      await Future.wait([
        _storage.delete(key: _keyFailedAttempts(userId)),
        _storage.delete(key: _keyLockoutUntil(userId)),
      ]);
    } catch (_) {}
  }

  Future<void> recordBackgroundTimestamp(DateTime timestamp) async {
    try {
      await _storage.write(
        key: _keyLastBackgroundAt,
        value: timestamp.millisecondsSinceEpoch.toString(),
      );
    } catch (_) {}
  }

  Future<DateTime?> getLastBackgroundTimestamp() async {
    try {
      final val = await _storage.read(key: _keyLastBackgroundAt);
      if (val != null) {
        final millis = int.tryParse(val);
        if (millis != null) {
          return DateTime.fromMillisecondsSinceEpoch(millis);
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clearBackgroundTimestamp() async {
    try {
      await _storage.delete(key: _keyLastBackgroundAt);
    } catch (_) {}
  }

  Future<void> recordLastUnlockedAt(int userId, DateTime timestamp) async {
    try {
      await _storage.write(
        key: _keyLastUnlockedAt(userId),
        value: timestamp.millisecondsSinceEpoch.toString(),
      );
    } catch (_) {}
  }

  Future<void> clearUserSecurity(int userId) async {
    try {
      await Future.wait([
        _storage.delete(key: _keyBiometric(userId)),
        _storage.delete(key: _keyPatternEnabled(userId)),
        _storage.delete(key: _keyPatternHash(userId)),
        _storage.delete(key: _keyPatternSalt(userId)),
        _storage.delete(key: _keyPreferredMethod(userId)),
        _storage.delete(key: _keyAutoLock(userId)),
        _storage.delete(key: _keyFailedAttempts(userId)),
        _storage.delete(key: _keyLockoutUntil(userId)),
        _storage.delete(key: _keyScreenshot(userId)),
        _storage.delete(key: _keyReauthTimeout(userId)),
        _storage.delete(key: _keyLastUnlockedAt(userId)),
      ]);
    } catch (_) {}
  }
}
