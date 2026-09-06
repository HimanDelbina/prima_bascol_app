enum ReauthMethod {
  biometric,
  pattern,
  password,
}

enum ReauthSecurityLevel {
  /// Biometric authentication (Fingerprint / Face ID)
  biometric(1),

  /// Local pattern authentication (PBKDF2-HMAC-SHA256)
  pattern(2),

  /// Authoritative backend password authentication
  backendPassword(3);

  final int rank;
  const ReauthSecurityLevel(this.rank);

  /// Returns true if this security level is equal to or higher than [requiredLevel]
  bool satisfies(ReauthSecurityLevel requiredLevel) {
    return rank >= requiredLevel.rank;
  }
}

class ReauthResult {
  final bool success;
  final ReauthMethod method;
  final ReauthSecurityLevel securityLevel;

  const ReauthResult({
    required this.success,
    required this.method,
    required this.securityLevel,
  });

  static const ReauthResult failure = ReauthResult(
    success: false,
    method: ReauthMethod.password,
    securityLevel: ReauthSecurityLevel.biometric,
  );
}

class ReauthSession {
  final DateTime authenticatedAt;
  final ReauthMethod method;
  final ReauthSecurityLevel securityLevel;
  final int userId;

  const ReauthSession({
    required this.authenticatedAt,
    required this.method,
    required this.securityLevel,
    required this.userId,
  });

  /// Checks whether this session is still active, belongs to [currentUserId],
  /// and meets the optional [minimumSecurityLevel].
  bool isValid({
    required int timeoutMinutes,
    required int currentUserId,
    ReauthSecurityLevel? minimumSecurityLevel,
  }) {
    if (userId != currentUserId) return false;
    final elapsed = DateTime.now().difference(authenticatedAt);
    if (elapsed >= Duration(minutes: timeoutMinutes)) return false;
    if (minimumSecurityLevel != null && !securityLevel.satisfies(minimumSecurityLevel)) {
      return false;
    }
    return true;
  }
}
