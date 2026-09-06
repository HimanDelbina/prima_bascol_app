import 'security_config.dart';

class LockoutState {
  final int failedAttempts;
  final DateTime? lockedUntil;

  const LockoutState({
    this.failedAttempts = 0,
    this.lockedUntil,
  });

  bool get isLocked {
    if (isPasswordRequired) return true;
    if (lockedUntil == null) return false;
    return DateTime.now().isBefore(lockedUntil!);
  }

  bool get isPasswordRequired =>
      failedAttempts >= SecurityConfig.lockoutThresholdTier3;

  int get remainingSeconds {
    if (lockedUntil == null) return 0;
    final diff = lockedUntil!.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  LockoutState recordFailedAttempt() {
    final nextAttempts = failedAttempts + 1;
    DateTime? nextLockedUntil;

    if (nextAttempts >= SecurityConfig.lockoutThresholdTier3) {
      // Permanent lockout from pattern, mandatory password login required
      nextLockedUntil = DateTime.now().add(const Duration(days: 365));
    } else if (nextAttempts >= SecurityConfig.lockoutThresholdTier2) {
      nextLockedUntil = DateTime.now().add(
        const Duration(seconds: SecurityConfig.lockoutSecondsTier2),
      );
    } else if (nextAttempts >= SecurityConfig.lockoutThresholdTier1) {
      nextLockedUntil = DateTime.now().add(
        const Duration(seconds: SecurityConfig.lockoutSecondsTier1),
      );
    }

    return LockoutState(
      failedAttempts: nextAttempts,
      lockedUntil: nextLockedUntil,
    );
  }

  LockoutState reset() {
    return const LockoutState();
  }
}
