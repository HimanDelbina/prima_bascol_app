import 'package:flutter_test/flutter_test.dart';
import 'package:prima_bascol_app/features/security/domain/lockout_state.dart';
import 'package:prima_bascol_app/features/security/domain/security_config.dart';

void main() {
  group('LockoutState Tests', () {
    test('initial state has 0 failed attempts and is not locked', () {
      const state = LockoutState();
      expect(state.failedAttempts, equals(0));
      expect(state.isLocked, isFalse);
      expect(state.isPasswordRequired, isFalse);
      expect(state.remainingSeconds, equals(0));
    });

    test('1 to 4 failed attempts increment count without locking', () {
      var state = const LockoutState();
      for (int i = 1; i <= 4; i++) {
        state = state.recordFailedAttempt();
        expect(state.failedAttempts, equals(i));
        expect(state.isLocked, isFalse);
      }
    });

    test('5 failed attempts triggers Tier 1 temporary lockout (30 seconds)', () {
      var state = const LockoutState();
      for (int i = 1; i <= 5; i++) {
        state = state.recordFailedAttempt();
      }
      expect(state.failedAttempts, equals(SecurityConfig.lockoutThresholdTier1));
      expect(state.isLocked, isTrue);
      expect(state.isPasswordRequired, isFalse);
      expect(state.remainingSeconds, greaterThan(0));
      expect(state.remainingSeconds, lessThanOrEqualTo(SecurityConfig.lockoutSecondsTier1));
    });

    test('10 failed attempts triggers Tier 2 lockout (120 seconds)', () {
      var state = const LockoutState();
      for (int i = 1; i <= 10; i++) {
        state = state.recordFailedAttempt();
      }
      expect(state.failedAttempts, equals(SecurityConfig.lockoutThresholdTier2));
      expect(state.isLocked, isTrue);
      expect(state.remainingSeconds, greaterThan(SecurityConfig.lockoutSecondsTier1));
      expect(state.remainingSeconds, lessThanOrEqualTo(SecurityConfig.lockoutSecondsTier2));
    });

    test('15 failed attempts triggers Tier 3 mandatory password login', () {
      var state = const LockoutState();
      for (int i = 1; i <= 15; i++) {
        state = state.recordFailedAttempt();
      }
      expect(state.failedAttempts, equals(SecurityConfig.lockoutThresholdTier3));
      expect(state.isLocked, isTrue);
      expect(state.isPasswordRequired, isTrue);
    });

    test('reset clears failed attempts and unlocks', () {
      var state = const LockoutState();
      for (int i = 1; i <= 6; i++) {
        state = state.recordFailedAttempt();
      }
      expect(state.isLocked, isTrue);

      final resetState = state.reset();
      expect(resetState.failedAttempts, equals(0));
      expect(resetState.isLocked, isFalse);
      expect(resetState.isPasswordRequired, isFalse);
    });
  });
}
