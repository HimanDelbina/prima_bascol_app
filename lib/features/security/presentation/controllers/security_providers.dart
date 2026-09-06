import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/presentation/auth_providers.dart';
import '../../data/biometric_service.dart';
import '../../data/pattern_crypto_service.dart';
import '../../data/security_storage_service.dart';
import '../../data/screenshot_protection_service.dart';
import '../../data/security_event_logger.dart';
import '../../data/sensitive_action_guard.dart';
import 'app_lock_controller.dart';
import 'security_settings_controller.dart';

final securityStorageServiceProvider = Provider<SecurityStorageService>((ref) {
  return SecurityStorageService();
});

final biometricServiceProvider = Provider<BiometricService>((ref) {
  return BiometricService();
});

final patternCryptoServiceProvider = Provider<PatternCryptoService>((ref) {
  return const PatternCryptoService();
});

final screenshotProtectionServiceProvider =
    Provider<ScreenshotProtectionService>((ref) {
  return ScreenshotProtectionService();
});

final securityEventLoggerProvider = Provider<SecurityEventLogger>((ref) {
  return SecurityEventLogger();
});

final sensitiveActionGuardProvider = Provider<SensitiveActionGuard>((ref) {
  return SensitiveActionGuard(
    ref: ref,
    eventLogger: ref.watch(securityEventLoggerProvider),
  );
});

final appLockControllerProvider =
    StateNotifierProvider<AppLockController, AppLockState>((ref) {
  final securityStorage = ref.watch(securityStorageServiceProvider);
  final biometricService = ref.watch(biometricServiceProvider);
  final patternCrypto = ref.watch(patternCryptoServiceProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  final eventLogger = ref.watch(securityEventLoggerProvider);
  final screenshotProtection = ref.watch(screenshotProtectionServiceProvider);

  return AppLockController(
    securityStorage: securityStorage,
    biometricService: biometricService,
    patternCrypto: patternCrypto,
    authRepository: authRepo,
    eventLogger: eventLogger,
    screenshotProtection: screenshotProtection,
    onInvalidateReauth: () {
      ref.read(sensitiveActionGuardProvider).invalidateSession();
    },
  );
});

final securitySettingsControllerProvider = StateNotifierProvider<
    SecuritySettingsController, SecuritySettingsState>((ref) {
  final securityStorage = ref.watch(securityStorageServiceProvider);
  final biometricService = ref.watch(biometricServiceProvider);
  final patternCrypto = ref.watch(patternCryptoServiceProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  final eventLogger = ref.watch(securityEventLoggerProvider);
  final screenshotProtection = ref.watch(screenshotProtectionServiceProvider);

  return SecuritySettingsController(
    storage: securityStorage,
    biometricService: biometricService,
    patternCrypto: patternCrypto,
    authRepository: authRepo,
    eventLogger: eventLogger,
    screenshotProtection: screenshotProtection,
    onPreferencesChanged: (updated) {
      ref.read(appLockControllerProvider.notifier).refreshPreferences(updated);
    },
  );
});
