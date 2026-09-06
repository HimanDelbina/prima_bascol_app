class AppConfig {
  static const String appName = "سامانه مدیریت هوشمند باسکول پریما";
  static const String appVersion = "1.0.0";
  static const String creatorName = "سارا حقیری";
  static const String creatorPhone = "09183739816";

  // Base URL configured via --dart-define=API_BASE_URL=... or defaults to localhost
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://2.184.55.37:5500/api/v1',
    // defaultValue: 'http://127.0.0.1:8000/api/v1',
  );

  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 20000;
  static const int sendTimeoutMs = 15000;

  static const String defaultTimeZone = "Asia/Tehran";
}
