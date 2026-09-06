import 'security_config.dart';
import 'unlock_method.dart';

class SecurityPreferences {
  final int userId;
  final bool biometricEnabled;
  final bool patternEnabled;
  final UnlockMethod preferredUnlockMethod;
  final int autoLockDuration; // in seconds, -1 means app close only
  final DateTime? lastBackgroundAt;
  final bool hasPattern;
  final bool screenshotProtectionEnabled;
  final int sensitiveActionReauthTimeoutMinutes;
  final DateTime? lastUnlockedAt;

  const SecurityPreferences({
    required this.userId,
    this.biometricEnabled = false,
    this.patternEnabled = false,
    this.preferredUnlockMethod = UnlockMethod.biometric,
    this.autoLockDuration = SecurityConfig.autoLock1Minute,
    this.lastBackgroundAt,
    this.hasPattern = false,
    this.screenshotProtectionEnabled = true,
    this.sensitiveActionReauthTimeoutMinutes = SecurityConfig.defaultReauthTimeoutMinutes,
    this.lastUnlockedAt,
  });

  SecurityMode get securityMode {
    if (biometricEnabled && patternEnabled) {
      return SecurityMode.biometricOrPattern;
    } else if (biometricEnabled) {
      return SecurityMode.biometricOnly;
    } else if (patternEnabled) {
      return SecurityMode.patternOnly;
    } else {
      return SecurityMode.off;
    }
  }

  bool get isQuickUnlockEnabled => securityMode.isQuickUnlockEnabled;

  SecurityPreferences copyWith({
    int? userId,
    bool? biometricEnabled,
    bool? patternEnabled,
    UnlockMethod? preferredUnlockMethod,
    int? autoLockDuration,
    DateTime? lastBackgroundAt,
    bool? hasPattern,
    bool? screenshotProtectionEnabled,
    int? sensitiveActionReauthTimeoutMinutes,
    DateTime? lastUnlockedAt,
    bool clearBackgroundAt = false,
  }) {
    return SecurityPreferences(
      userId: userId ?? this.userId,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      patternEnabled: patternEnabled ?? this.patternEnabled,
      preferredUnlockMethod: preferredUnlockMethod ?? this.preferredUnlockMethod,
      autoLockDuration: autoLockDuration ?? this.autoLockDuration,
      lastBackgroundAt: clearBackgroundAt ? null : (lastBackgroundAt ?? this.lastBackgroundAt),
      hasPattern: hasPattern ?? this.hasPattern,
      screenshotProtectionEnabled:
          screenshotProtectionEnabled ?? this.screenshotProtectionEnabled,
      sensitiveActionReauthTimeoutMinutes:
          sensitiveActionReauthTimeoutMinutes ?? this.sensitiveActionReauthTimeoutMinutes,
      lastUnlockedAt: lastUnlockedAt ?? this.lastUnlockedAt,
    );
  }
}
