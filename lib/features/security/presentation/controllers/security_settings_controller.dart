import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/auth_repository.dart';
import '../../data/biometric_service.dart';
import '../../data/pattern_crypto_service.dart';
import '../../data/screenshot_protection_service.dart';
import '../../data/security_event_logger.dart';
import '../../data/security_storage_service.dart';
import '../../domain/security_event.dart';
import '../../domain/security_preferences.dart';
import '../../domain/unlock_method.dart';

class SecuritySettingsState {
  final bool isLoading;
  final SecurityPreferences? preferences;
  final BiometricCapabilities? capabilities;
  final String? errorMessage;
  final String? successMessage;

  const SecuritySettingsState({
    this.isLoading = false,
    this.preferences,
    this.capabilities,
    this.errorMessage,
    this.successMessage,
  });

  SecuritySettingsState copyWith({
    bool? isLoading,
    SecurityPreferences? preferences,
    BiometricCapabilities? capabilities,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return SecuritySettingsState(
      isLoading: isLoading ?? this.isLoading,
      preferences: preferences ?? this.preferences,
      capabilities: capabilities ?? this.capabilities,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class SecuritySettingsController extends StateNotifier<SecuritySettingsState> {
  final SecurityStorageService _storage;
  final BiometricService _biometricService;
  final PatternCryptoService _patternCrypto;
  final AuthRepository _authRepository;
  final SecurityEventLogger _eventLogger;
  final ScreenshotProtectionService _screenshotProtection;
  final void Function(SecurityPreferences)? onPreferencesChanged;

  SecuritySettingsController({
    required SecurityStorageService storage,
    required BiometricService biometricService,
    required PatternCryptoService patternCrypto,
    required AuthRepository authRepository,
    required SecurityEventLogger eventLogger,
    required ScreenshotProtectionService screenshotProtection,
    this.onPreferencesChanged,
  })  : _storage = storage,
        _biometricService = biometricService,
        _patternCrypto = patternCrypto,
        _authRepository = authRepository,
        _eventLogger = eventLogger,
        _screenshotProtection = screenshotProtection,
        super(const SecuritySettingsState());

  Future<void> loadSettings(int userId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final capabilities = await _biometricService.checkCapabilities();
      final preferences = await _storage.loadPreferences(userId);

      state = state.copyWith(
        isLoading: false,
        preferences: preferences,
        capabilities: capabilities,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطا در بارگذاری تنظیمات امنیتی: $e',
      );
    }
  }

  Future<bool> verifyPassword(String username, String password) async {
    try {
      final valid = await _authRepository.verifyPassword(password);
      await _eventLogger.log(
        valid
            ? SecurityEventType.passwordReauthSuccess
            : SecurityEventType.passwordReauthFailed,
        action: 'settings_verify_password',
      );
      return valid;
    } catch (_) {
      await _eventLogger.log(
        SecurityEventType.passwordReauthFailed,
        action: 'settings_verify_password_error',
      );
      return false;
    }
  }

  Future<bool> enableBiometric(int userId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final capabilities = await _biometricService.checkCapabilities();
      if (!capabilities.isDeviceSupported) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: capabilities.unavailabilityReasonFa ??
              'این دستگاه از احراز هویت بیومتریک پشتیبانی نمیکند.',
        );
        return false;
      }
      if (!capabilities.isEnrolled) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: capabilities.unavailabilityReasonFa ??
              'ابتدا اثر انگشت یا تشخیص چهره را از تنظیمات دستگاه فعال کنید.',
        );
        return false;
      }

      // Test biometric authentication
      final testResult = await _biometricService.authenticate(
        localizedReason: 'جهت فعال‌سازی، هویت بیومتریک خود را تأیید کنید.',
      );

      if (!testResult.isSuccess) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: testResult.errorMessageFa ?? 'احراز هویت بیومتریک انجام نشد.',
        );
        return false;
      }

      final currentPrefs = state.preferences ?? SecurityPreferences(userId: userId);
      final updated = currentPrefs.copyWith(biometricEnabled: true);
      await _storage.savePreferences(updated);

      onPreferencesChanged?.call(updated);

      state = state.copyWith(
        isLoading: false,
        preferences: updated,
        successMessage: 'ورود با بیومتریک با موفقیت فعال شد.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطا در فعال‌سازی بیومتریک: $e',
      );
      return false;
    }
  }

  Future<bool> disableBiometric(int userId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final currentPrefs = state.preferences ?? SecurityPreferences(userId: userId);
      final updated = currentPrefs.copyWith(biometricEnabled: false);
      await _storage.savePreferences(updated);

      onPreferencesChanged?.call(updated);

      state = state.copyWith(
        isLoading: false,
        preferences: updated,
        successMessage: 'ورود بیومتریک غیرفعال گردید.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطا در غیرفعال‌سازی: $e',
      );
      return false;
    }
  }

  Future<bool> saveNewPattern(int userId, List<int> pattern) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final salt = _patternCrypto.generateSalt();
      final hash = _patternCrypto.hashPattern(pattern, salt);

      await _storage.savePattern(userId: userId, hash: hash, salt: salt);
      await _storage.clearLockoutState(userId);

      final currentPrefs = state.preferences ?? SecurityPreferences(userId: userId);
      final updated = currentPrefs.copyWith(
        patternEnabled: true,
        hasPattern: true,
      );
      await _storage.savePreferences(updated);

      onPreferencesChanged?.call(updated);

      state = state.copyWith(
        isLoading: false,
        preferences: updated,
        successMessage: 'الگوی جدید با موفقیت ذخیره شد.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطا در ذخیره الگو: $e',
      );
      return false;
    }
  }

  Future<bool> deletePattern(int userId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _storage.clearPattern(userId);
      await _storage.clearLockoutState(userId);

      final currentPrefs = state.preferences ?? SecurityPreferences(userId: userId);
      final updated = currentPrefs.copyWith(
        patternEnabled: false,
        hasPattern: false,
        preferredUnlockMethod: UnlockMethod.biometric,
      );
      await _storage.savePreferences(updated);

      onPreferencesChanged?.call(updated);

      state = state.copyWith(
        isLoading: false,
        preferences: updated,
        successMessage: 'الگو با موفقیت حذف گردید.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'خطا در حذف الگو: $e',
      );
      return false;
    }
  }

  Future<void> updateAutoLockDuration(int seconds) async {
    final currentPrefs = state.preferences;
    if (currentPrefs == null) return;

    final updated = currentPrefs.copyWith(autoLockDuration: seconds);
    await _storage.savePreferences(updated);
    onPreferencesChanged?.call(updated);

    state = state.copyWith(preferences: updated);
  }

  Future<void> updatePreferredMethod(UnlockMethod method) async {
    final currentPrefs = state.preferences;
    if (currentPrefs == null) return;

    final updated = currentPrefs.copyWith(preferredUnlockMethod: method);
    await _storage.savePreferences(updated);
    onPreferencesChanged?.call(updated);

    state = state.copyWith(preferences: updated);
  }

  Future<void> updateScreenshotProtection(bool enabled) async {
    final currentPrefs = state.preferences;
    if (currentPrefs == null) return;

    final updated = currentPrefs.copyWith(screenshotProtectionEnabled: enabled);
    await _storage.savePreferences(updated);
    await _screenshotProtection.setScreenshotProtection(enabled);
    onPreferencesChanged?.call(updated);

    state = state.copyWith(preferences: updated);
  }

  Future<void> updateReauthTimeout(int minutes) async {
    final currentPrefs = state.preferences;
    if (currentPrefs == null) return;

    final updated = currentPrefs.copyWith(sensitiveActionReauthTimeoutMinutes: minutes);
    await _storage.savePreferences(updated);
    onPreferencesChanged?.call(updated);

    state = state.copyWith(preferences: updated);
  }

  Future<void> testBiometric() async {
    state = state.copyWith(clearError: true, clearSuccess: true);
    final result = await _biometricService.authenticate(
      localizedReason: 'تست احراز هویت بیومتریک سامانه باسکول',
    );
    if (result.isSuccess) {
      state = state.copyWith(successMessage: 'تست بیومتریک با موفقیت انجام شد.');
    } else {
      state = state.copyWith(
        errorMessage: result.errorMessageFa ?? 'تست بیومتریک ناموفق بود.',
      );
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}
