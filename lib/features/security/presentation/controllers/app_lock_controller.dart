import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_exception.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/domain/auth_models.dart';
import '../../data/biometric_service.dart';
import '../../data/pattern_crypto_service.dart';
import '../../data/screenshot_protection_service.dart';
import '../../data/security_event_logger.dart';
import '../../data/security_storage_service.dart';
import '../../domain/lockout_state.dart';
import '../../domain/security_config.dart';
import '../../domain/security_event.dart';
import '../../domain/security_preferences.dart';
import '../../domain/unlock_method.dart';

enum AppLockStatus {
  unauthenticated,
  authenticating,
  authenticatedLocked,
  authenticatedUnlocked,
  sessionExpired,
}

class AppLockState {
  final AppLockStatus status;
  final UserMe? user;
  final SecurityPreferences? preferences;
  final LockoutState lockoutState;
  final UnlockMethod activeUnlockMethod;
  final String? errorMessage;
  final bool isPrivacyOverlayVisible;
  final DateTime? backgroundStartedAt;

  const AppLockState({
    this.status = AppLockStatus.unauthenticated,
    this.user,
    this.preferences,
    this.lockoutState = const LockoutState(),
    this.activeUnlockMethod = UnlockMethod.biometric,
    this.errorMessage,
    this.isPrivacyOverlayVisible = false,
    this.backgroundStartedAt,
  });

  bool get isLocked => status == AppLockStatus.authenticatedLocked;
  bool get isUnlocked => status == AppLockStatus.authenticatedUnlocked;

  AppLockState copyWith({
    AppLockStatus? status,
    UserMe? user,
    SecurityPreferences? preferences,
    LockoutState? lockoutState,
    UnlockMethod? activeUnlockMethod,
    String? errorMessage,
    bool? isPrivacyOverlayVisible,
    DateTime? backgroundStartedAt,
    bool clearError = false,
    bool clearUser = false,
    bool clearBackgroundStartedAt = false,
  }) {
    return AppLockState(
      status: status ?? this.status,
      user: clearUser ? null : (user ?? this.user),
      preferences: preferences ?? this.preferences,
      lockoutState: lockoutState ?? this.lockoutState,
      activeUnlockMethod: activeUnlockMethod ?? this.activeUnlockMethod,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isPrivacyOverlayVisible:
          isPrivacyOverlayVisible ?? this.isPrivacyOverlayVisible,
      backgroundStartedAt: clearBackgroundStartedAt
          ? null
          : (backgroundStartedAt ?? this.backgroundStartedAt),
    );
  }
}

class AppLockController extends StateNotifier<AppLockState>
    with WidgetsBindingObserver {
  final SecurityStorageService _securityStorage;
  final BiometricService _biometricService;
  final PatternCryptoService _patternCrypto;
  final AuthRepository _authRepository;
  final SecurityEventLogger _eventLogger;
  final ScreenshotProtectionService _screenshotProtection;
  final VoidCallback? onInvalidateReauth;
  Timer? _lockoutCountdownTimer;

  AppLockController({
    required SecurityStorageService securityStorage,
    required BiometricService biometricService,
    required PatternCryptoService patternCrypto,
    required AuthRepository authRepository,
    required SecurityEventLogger eventLogger,
    required ScreenshotProtectionService screenshotProtection,
    this.onInvalidateReauth,
  })  : _securityStorage = securityStorage,
        _biometricService = biometricService,
        _patternCrypto = patternCrypto,
        _authRepository = authRepository,
        _eventLogger = eventLogger,
        _screenshotProtection = screenshotProtection,
        super(const AppLockState()) {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lockoutCountdownTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        _handleAppBackgrounded();
        break;
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;
      case AppLifecycleState.detached:
        _handleAppBackgrounded();
        break;
    }
  }

  void _handleAppBackgrounded() {
    final now = DateTime.now();
    state = state.copyWith(
      isPrivacyOverlayVisible: true,
      backgroundStartedAt: now,
    );
    _securityStorage.recordBackgroundTimestamp(now);
  }

  Future<void> _handleAppResumed() async {
    state = state.copyWith(
      isPrivacyOverlayVisible: false,
      clearBackgroundStartedAt: true,
    );

    final bgTime = (state.backgroundStartedAt) ??
        await _securityStorage.getLastBackgroundTimestamp();
    await _securityStorage.clearBackgroundTimestamp();

    if (bgTime == null) return;
    if (state.status != AppLockStatus.authenticatedUnlocked) return;

    final prefs = state.preferences;
    if (prefs == null || !prefs.isQuickUnlockEnabled) return;

    final duration = prefs.autoLockDuration;
    if (duration == SecurityConfig.autoLockAppCloseOnly) {
      return;
    }

    final elapsedSeconds = DateTime.now().difference(bgTime).inSeconds;
    if (duration == SecurityConfig.autoLockImmediately ||
        elapsedSeconds >= duration) {
      await lockApp();
    }
  }

  Future<void> initializeForUser(UserMe user, {bool isColdStart = false}) async {
    if (state.user != null && state.user!.id != user.id) {
      onInvalidateReauth?.call();
    }
    final prefs = await _securityStorage.loadPreferences(user.id);
    final lockout = await _securityStorage.loadLockoutState(user.id);
    await _securityStorage.setLastActiveUserId(user.id);

    // Apply screenshot protection setting
    await _screenshotProtection.setScreenshotProtection(prefs.screenshotProtectionEnabled);

    UnlockMethod initialMethod = prefs.preferredUnlockMethod;
    if (initialMethod == UnlockMethod.biometric && !prefs.biometricEnabled) {
      initialMethod = UnlockMethod.pattern;
    } else if (initialMethod == UnlockMethod.pattern && !prefs.patternEnabled) {
      initialMethod = UnlockMethod.biometric;
    }

    AppLockStatus targetStatus = AppLockStatus.authenticatedUnlocked;
    if (isColdStart && prefs.isQuickUnlockEnabled) {
      onInvalidateReauth?.call();
      targetStatus = AppLockStatus.authenticatedLocked;
      await _eventLogger.log(
        SecurityEventType.appLocked,
        userId: user.id,
        action: 'cold_start',
      );
    }

    state = state.copyWith(
      status: targetStatus,
      user: user,
      preferences: prefs,
      lockoutState: lockout,
      activeUnlockMethod: initialMethod,
      clearError: true,
    );

    _checkLockoutTimer();
  }

  Future<void> lockApp() async {
    onInvalidateReauth?.call();
    if (state.status == AppLockStatus.unauthenticated) return;
    final prefs = state.preferences;
    if (prefs == null || !prefs.isQuickUnlockEnabled) return;

    UnlockMethod initialMethod = prefs.preferredUnlockMethod;
    if (initialMethod == UnlockMethod.biometric && !prefs.biometricEnabled) {
      initialMethod = UnlockMethod.pattern;
    } else if (initialMethod == UnlockMethod.pattern && !prefs.patternEnabled) {
      initialMethod = UnlockMethod.biometric;
    }

    state = state.copyWith(
      status: AppLockStatus.authenticatedLocked,
      activeUnlockMethod: initialMethod,
      clearError: true,
    );

    await _eventLogger.log(
      SecurityEventType.appLocked,
      userId: state.user?.id,
      action: 'auto_lock',
    );

    _checkLockoutTimer();
  }

  void switchUnlockMethod(UnlockMethod method) {
    state = state.copyWith(activeUnlockMethod: method, clearError: true);
  }

  Future<bool> unlockWithBiometric() async {
    final user = state.user;
    if (user == null) return false;

    state = state.copyWith(clearError: true);
    final result = await _biometricService.authenticate(
      localizedReason: 'برای ورود به سامانه باسکول احراز هویت کنید.',
    );

    if (result.isSuccess) {
      return await _completeUnlock();
    } else {
      await _eventLogger.log(
        SecurityEventType.biometricFailed,
        userId: user.id,
        action: result.errorCode,
      );

      if (result.isLockout) {
        state = state.copyWith(
          errorMessage:
              'احراز هویت بیومتریک موقتاً در دسترس نیست. لطفاً از الگو یا رمز عبور استفاده کنید.',
          activeUnlockMethod: state.preferences?.patternEnabled == true
              ? UnlockMethod.pattern
              : UnlockMethod.biometric,
        );
      } else if (!result.isUserCancelled) {
        state = state.copyWith(
          errorMessage: result.errorMessageFa ?? 'احراز هویت بیومتریک ناموفق بود.',
        );
      }
      return false;
    }
  }

  Future<bool> unlockWithPattern(List<int> pattern) async {
    final user = state.user;
    if (user == null) return false;

    if (state.lockoutState.isLocked) {
      if (state.lockoutState.isPasswordRequired) {
        state = state.copyWith(
          errorMessage:
              'تعداد دفعات ورود اشتباه بیش از حد مجاز است. لطفاً با رمز عبور وارد شوید.',
        );
      } else {
        state = state.copyWith(
          errorMessage:
              'قفل موقت! لطفاً ${state.lockoutState.remainingSeconds} ثانیه دیگر صبر کنید.',
        );
      }
      return false;
    }

    final patternData = await _securityStorage.getPatternData(user.id);
    if (patternData.hash == null || patternData.salt == null) {
      state = state.copyWith(errorMessage: 'الگوی قفل تعریف نشده است.');
      return false;
    }

    final isValid = _patternCrypto.verifyPattern(
      pattern: pattern,
      storedHash: patternData.hash!,
      storedSalt: patternData.salt!,
    );

    if (isValid) {
      await _securityStorage.clearLockoutState(user.id);
      state = state.copyWith(lockoutState: const LockoutState());
      _lockoutCountdownTimer?.cancel();
      return await _completeUnlock();
    } else {
      await _eventLogger.log(
        SecurityEventType.patternFailed,
        userId: user.id,
      );

      final updatedLockout = state.lockoutState.recordFailedAttempt();
      await _securityStorage.saveLockoutState(user.id, updatedLockout);

      if (updatedLockout.isLocked) {
        await _eventLogger.log(
          SecurityEventType.patternLockout,
          userId: user.id,
          action: 'tier_${updatedLockout.failedAttempts}',
        );
      }

      state = state.copyWith(
        lockoutState: updatedLockout,
        errorMessage: updatedLockout.isPasswordRequired
            ? 'تعداد دفعات اشتباه بیش از حد مجاز (۱۵ بار). الزام ورود با رمز عبور.'
            : updatedLockout.isLocked
                ? 'الگوی اشتباه! قفل موقت به مدت ${updatedLockout.remainingSeconds} ثانیه.'
                : 'الگوی واردشده صحیح نیست. (${updatedLockout.failedAttempts} تلاش ناموفق)',
      );
      _checkLockoutTimer();
      return false;
    }
  }

  Future<bool> _completeUnlock() async {
    state = state.copyWith(status: AppLockStatus.authenticating);
    try {
      final hasSession = await _authRepository.hasValidSession();
      if (!hasSession) {
        onInvalidateReauth?.call();
        await _eventLogger.log(
          SecurityEventType.sessionExpired,
          userId: state.user?.id,
        );
        state = state.copyWith(
          status: AppLockStatus.sessionExpired,
          errorMessage: 'نشست شما منقضی شده است. لطفاً دوباره وارد شوید.',
        );
        return false;
      }

      final now = DateTime.now();
      if (state.user != null) {
        await _securityStorage.recordLastUnlockedAt(state.user!.id, now);
        final updatedPrefs = state.preferences?.copyWith(lastUnlockedAt: now);
        if (updatedPrefs != null) {
          state = state.copyWith(preferences: updatedPrefs);
        }
      }

      await _eventLogger.log(
        SecurityEventType.appUnlocked,
        userId: state.user?.id,
      );

      state = state.copyWith(
        status: AppLockStatus.authenticatedUnlocked,
        clearError: true,
      );
      return true;
    } on ApiException catch (e) {
      if (e.statusCode == 401 || e.statusCode == 403) {
        onInvalidateReauth?.call();
        await _eventLogger.log(
          SecurityEventType.sessionExpired,
          userId: state.user?.id,
          action: 'http_${e.statusCode}',
        );
        state = state.copyWith(
          status: AppLockStatus.sessionExpired,
          errorMessage: 'نشست شما در سرور باطل شده یا حساب کاربری غیرفعال است.',
        );
        return false;
      }
      state = state.copyWith(
        status: AppLockStatus.authenticatedUnlocked,
        clearError: true,
      );
      return true;
    } catch (_) {
      state = state.copyWith(
        status: AppLockStatus.authenticatedUnlocked,
        clearError: true,
      );
      return true;
    }
  }

  void _checkLockoutTimer() {
    _lockoutCountdownTimer?.cancel();
    if (state.lockoutState.isLocked && !state.lockoutState.isPasswordRequired) {
      _lockoutCountdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        if (!state.lockoutState.isLocked) {
          timer.cancel();
          state = state.copyWith(clearError: true);
        } else {
          state = state.copyWith(lockoutState: state.lockoutState);
        }
      });
    }
  }

  Future<void> handleLogout() async {
    onInvalidateReauth?.call();
    _lockoutCountdownTimer?.cancel();
    await _eventLogger.log(
      SecurityEventType.logout,
      userId: state.user?.id,
    );
    state = const AppLockState(status: AppLockStatus.unauthenticated);
  }

  void refreshPreferences(SecurityPreferences newPrefs) {
    state = state.copyWith(preferences: newPrefs);
    _screenshotProtection.setScreenshotProtection(newPrefs.screenshotProtectionEnabled);
  }
}
