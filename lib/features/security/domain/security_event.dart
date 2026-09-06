enum SecurityEventType {
  appLocked,
  appUnlocked,
  biometricFailed,
  patternFailed,
  patternLockout,
  passwordReauthFailed,
  passwordReauthSuccess,
  sensitiveActionAuthorized,
  sessionExpired,
  logout;

  String get code {
    switch (this) {
      case SecurityEventType.appLocked:
        return 'APP_LOCKED';
      case SecurityEventType.appUnlocked:
        return 'APP_UNLOCKED';
      case SecurityEventType.biometricFailed:
        return 'BIOMETRIC_FAILED';
      case SecurityEventType.patternFailed:
        return 'PATTERN_FAILED';
      case SecurityEventType.patternLockout:
        return 'PATTERN_LOCKOUT';
      case SecurityEventType.passwordReauthFailed:
        return 'PASSWORD_REAUTH_FAILED';
      case SecurityEventType.passwordReauthSuccess:
        return 'PASSWORD_REAUTH_SUCCESS';
      case SecurityEventType.sensitiveActionAuthorized:
        return 'SENSITIVE_ACTION_AUTHORIZED';
      case SecurityEventType.sessionExpired:
        return 'SESSION_EXPIRED';
      case SecurityEventType.logout:
        return 'LOGOUT';
    }
  }

  static SecurityEventType fromCode(String code) {
    switch (code) {
      case 'APP_LOCKED':
        return SecurityEventType.appLocked;
      case 'APP_UNLOCKED':
        return SecurityEventType.appUnlocked;
      case 'BIOMETRIC_FAILED':
        return SecurityEventType.biometricFailed;
      case 'PATTERN_FAILED':
        return SecurityEventType.patternFailed;
      case 'PATTERN_LOCKOUT':
        return SecurityEventType.patternLockout;
      case 'PASSWORD_REAUTH_FAILED':
        return SecurityEventType.passwordReauthFailed;
      case 'PASSWORD_REAUTH_SUCCESS':
        return SecurityEventType.passwordReauthSuccess;
      case 'SENSITIVE_ACTION_AUTHORIZED':
        return SecurityEventType.sensitiveActionAuthorized;
      case 'SESSION_EXPIRED':
        return SecurityEventType.sessionExpired;
      case 'LOGOUT':
        return SecurityEventType.logout;
      default:
        return SecurityEventType.appLocked;
    }
  }

  String get labelFa {
    switch (this) {
      case SecurityEventType.appLocked:
        return 'قفل شدن برنامه';
      case SecurityEventType.appUnlocked:
        return 'بازگشایی قفل برنامه';
      case SecurityEventType.biometricFailed:
        return 'خطای احراز بیومتریک';
      case SecurityEventType.patternFailed:
        return 'خطای ورود الگو';
      case SecurityEventType.patternLockout:
        return 'قفل موقت بر اثر خطای الگو';
      case SecurityEventType.passwordReauthFailed:
        return 'خطای تأیید کلمه عبور';
      case SecurityEventType.passwordReauthSuccess:
        return 'تأیید موفق کلمه عبور';
      case SecurityEventType.sensitiveActionAuthorized:
        return 'مجوز عملیات حساس';
      case SecurityEventType.sessionExpired:
        return 'انقضای نشست کاربر';
      case SecurityEventType.logout:
        return 'خروج از حساب کاربری';
    }
  }
}

class SecurityEvent {
  final DateTime timestamp;
  final SecurityEventType eventType;
  final int? userId;
  final String platform;
  final String? action;

  const SecurityEvent({
    required this.timestamp,
    required this.eventType,
    this.userId,
    required this.platform,
    this.action,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'eventType': eventType.code,
      'userId': userId,
      'platform': platform,
      'action': action,
    };
  }

  factory SecurityEvent.fromJson(Map<String, dynamic> json) {
    return SecurityEvent(
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      eventType: SecurityEventType.fromCode(json['eventType']?.toString() ?? ''),
      userId: json['userId'] is int ? json['userId'] : int.tryParse(json['userId']?.toString() ?? ''),
      platform: json['platform']?.toString() ?? 'unknown',
      action: json['action']?.toString(),
    );
  }
}
