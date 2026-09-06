import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class BiometricCapabilities {
  final bool isDeviceSupported;
  final bool canCheckBiometrics;
  final List<BiometricType> availableBiometrics;

  const BiometricCapabilities({
    required this.isDeviceSupported,
    required this.canCheckBiometrics,
    required this.availableBiometrics,
  });

  bool get hasFingerprint =>
      availableBiometrics.contains(BiometricType.fingerprint) ||
      availableBiometrics.contains(BiometricType.strong);

  bool get hasFace => availableBiometrics.contains(BiometricType.face);

  bool get isEnrolled =>
      isDeviceSupported && canCheckBiometrics && availableBiometrics.isNotEmpty;

  String get labelFa {
    if (hasFace && !hasFingerprint) {
      return 'ورود با تشخیص چهره (Face ID)';
    } else if (hasFingerprint && !hasFace) {
      return 'ورود با اثر انگشت';
    } else {
      return 'ورود با اثر انگشت / تشخیص چهره';
    }
  }

  String? get unavailabilityReasonFa {
    if (!isDeviceSupported) {
      return 'این دستگاه از احراز هویت بیومتریک پشتیبانی نمیکند.';
    }
    if (!canCheckBiometrics || availableBiometrics.isEmpty) {
      return 'ابتدا اثر انگشت یا تشخیص چهره را از تنظیمات دستگاه فعال کنید.';
    }
    return null;
  }
}

class BiometricAuthResult {
  final bool isSuccess;
  final bool isUserCancelled;
  final bool isLockout;
  final String? errorCode;
  final String? errorMessageFa;

  const BiometricAuthResult({
    required this.isSuccess,
    this.isUserCancelled = false,
    this.isLockout = false,
    this.errorCode,
    this.errorMessageFa,
  });

  factory BiometricAuthResult.success() =>
      const BiometricAuthResult(isSuccess: true);

  factory BiometricAuthResult.cancelled() => const BiometricAuthResult(
        isSuccess: false,
        isUserCancelled: true,
        errorMessageFa: 'احراز هویت توسط کاربر لغو شد.',
      );

  factory BiometricAuthResult.failure(String message, {String? code}) =>
      BiometricAuthResult(
        isSuccess: false,
        errorCode: code,
        errorMessageFa: message,
      );

  factory BiometricAuthResult.lockout(String message) => BiometricAuthResult(
        isSuccess: false,
        isLockout: true,
        errorCode: 'LockedOut',
        errorMessageFa: message,
      );
}

class BiometricService {
  final LocalAuthentication _auth;

  BiometricService({LocalAuthentication? auth})
      : _auth = auth ?? LocalAuthentication();

  Future<BiometricCapabilities> checkCapabilities() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) {
        return const BiometricCapabilities(
          isDeviceSupported: false,
          canCheckBiometrics: false,
          availableBiometrics: [],
        );
      }

      final canCheck = await _auth.canCheckBiometrics;
      final available = await _auth.getAvailableBiometrics();

      return BiometricCapabilities(
        isDeviceSupported: true,
        canCheckBiometrics: canCheck,
        availableBiometrics: available,
      );
    } catch (_) {
      return const BiometricCapabilities(
        isDeviceSupported: false,
        canCheckBiometrics: false,
        availableBiometrics: [],
      );
    }
  }

  Future<BiometricAuthResult> authenticate({
    String localizedReason = 'برای ورود به سامانه باسکول احراز هویت کنید.',
  }) async {
    try {
      final capabilities = await checkCapabilities();
      if (!capabilities.isDeviceSupported) {
        return BiometricAuthResult.failure(
          'این دستگاه از احراز هویت بیومتریک پشتیبانی نمیکند.',
        );
      }
      if (!capabilities.isEnrolled) {
        return BiometricAuthResult.failure(
          'ابتدا اثر انگشت یا تشخیص چهره را از تنظیمات دستگاه فعال کنید.',
        );
      }

      final bool didAuthenticate = await _auth.authenticate(
        localizedReason: localizedReason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (didAuthenticate) {
        return BiometricAuthResult.success();
      } else {
        return BiometricAuthResult.cancelled();
      }
    } on PlatformException catch (e) {
      if (e.code == 'UserCanceled' || e.code == 'user_canceled') {
        return BiometricAuthResult.cancelled();
      } else if (e.code == 'LockedOut') {
        return BiometricAuthResult.lockout(
          'احراز هویت بیومتریک موقتاً در دسترس نیست.',
        );
      } else if (e.code == 'PermanentlyLockedOut') {
        return BiometricAuthResult.lockout(
          'حسگر بیومتریک غیرفعال شده است. لطفاً با رمز عبور وارد شوید.',
        );
      } else if (e.code == 'NotEnrolled' || e.code == 'not_enrolled') {
        return BiometricAuthResult.failure(
          'ابتدا اثر انگشت یا تشخیص چهره را از تنظیمات دستگاه فعال کنید.',
        );
      } else if (e.code == 'NotAvailable' || e.code == 'not_available') {
        return BiometricAuthResult.failure(
          'سنسور بیومتریک در حال حاضر در دسترس نمی‌باشد.',
        );
      }
      return BiometricAuthResult.failure('احراز هویت بیومتریک ناموفق بود.');
    } catch (_) {
      return BiometricAuthResult.failure('احراز هویت بیومتریک ناموفق بود.');
    }
  }
}
