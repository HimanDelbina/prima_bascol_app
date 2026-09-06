class SecurityConfig {
  // Pattern Constraints
  static const int minPatternPoints = 4;
  static const int recommendedPatternPoints = 5;

  // Brute Force Lockout Tiers
  static const int lockoutThresholdTier1 = 5;
  static const int lockoutSecondsTier1 = 30; // 30 seconds

  static const int lockoutThresholdTier2 = 10;
  static const int lockoutSecondsTier2 = 120; // 2 minutes

  static const int lockoutThresholdTier3 = 15; // Mandatory Password Login

  // PBKDF2 Hardening parameters
  static const int legacyPbkdf2Iterations = 10000;
  static const int defaultPbkdf2Iterations = 30000; // Hardened for mobile/POS terminals (~270ms desktop, ~700ms mobile)
  static const int highSecurityPbkdf2Iterations = 60000;
  static const int saltByteLength = 16;
  static const int derivedKeyLength = 32;
  static const String currentHashAlgorithm = 'pbkdf2_sha256_v1';

  /// Configurable iteration count (allows runtime tuning by device benchmark or admin policy)
  static int pbkdf2Iterations = defaultPbkdf2Iterations;

  // Auto-Lock Durations (in seconds, -1 means app close only)
  static const int autoLockImmediately = 0;
  static const int autoLock30Seconds = 30;
  static const int autoLock1Minute = 60;
  static const int autoLock5Minutes = 300;
  static const int autoLock15Minutes = 900;
  static const int autoLockAppCloseOnly = -1;

  static const List<int> autoLockOptions = [
    autoLockImmediately,
    autoLock30Seconds,
    autoLock1Minute,
    autoLock5Minutes,
    autoLock15Minutes,
    autoLockAppCloseOnly,
  ];

  static String autoLockDurationLabelFa(int seconds) {
    switch (seconds) {
      case autoLockImmediately:
        return 'بلافاصله';
      case autoLock30Seconds:
        return 'بعد از ۳۰ ثانیه';
      case autoLock1Minute:
        return 'بعد از ۱ دقیقه';
      case autoLock5Minutes:
        return 'بعد از ۵ دقیقه';
      case autoLock15Minutes:
        return 'بعد از ۱۵ دقیقه';
      case autoLockAppCloseOnly:
        return 'فقط بعد از بسته شدن برنامه';
      default:
        return '$seconds ثانیه';
    }
  }

  // Re-authentication Session Timeout (in minutes)
  static const int defaultReauthTimeoutMinutes = 5;
  static const List<int> reauthTimeoutOptions = [1, 5, 10, 15, 30];

  static String reauthTimeoutLabelFa(int minutes) {
    return '$minutes دقیقه';
  }
}
