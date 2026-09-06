import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ScreenshotProtectionService {
  static const MethodChannel _channel = MethodChannel('prima_bascol/security');

  final MethodChannel channel;

  ScreenshotProtectionService({MethodChannel? channel})
      : channel = channel ?? _channel;

  bool get isPlatformSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<bool> setScreenshotProtection(bool enable) async {
    if (!isPlatformSupported) return false;
    try {
      final method = enable ? 'enableSecureFlag' : 'disableSecureFlag';
      final result = await channel.invokeMethod<bool>(method);
      return result ?? false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> enableScreenshotProtection() async {
    return await setScreenshotProtection(true);
  }

  Future<bool> disableScreenshotProtection() async {
    return await setScreenshotProtection(false);
  }

  Future<bool> isSupported() async {
    if (!isPlatformSupported) return false;
    try {
      final result = await channel.invokeMethod<bool>('isSecureFlagSupported');
      return result ?? false;
    } catch (_) {
      return false;
    }
  }
}
