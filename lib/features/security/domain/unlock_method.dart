enum UnlockMethod {
  biometric,
  pattern;

  String get labelFa {
    switch (this) {
      case UnlockMethod.biometric:
        return 'اثر انگشت / چهره';
      case UnlockMethod.pattern:
        return 'الگو (Pattern)';
    }
  }
}

enum SecurityMode {
  off,
  biometricOnly,
  patternOnly,
  biometricOrPattern;

  bool get isQuickUnlockEnabled => this != SecurityMode.off;

  String get labelFa {
    switch (this) {
      case SecurityMode.off:
        return 'غیرفعال';
      case SecurityMode.biometricOnly:
        return 'فقط بیومتریک';
      case SecurityMode.patternOnly:
        return 'فقط الگو';
      case SecurityMode.biometricOrPattern:
        return 'بیومتریک یا الگو';
    }
  }
}
