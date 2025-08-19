class ApiConstants {
  // Django 서버 기본 URL
  static const String baseServer = 'http://localhost:8000';

  // Auth 관련
  static const String authBase = '$baseServer/api/auth';
  static const String tokenUrl = '$baseServer/token';
  static const String googleRedirect = 'http://localhost:51577/api/auth/oauth/google/code';

  // Settings
  static const String settingsBase = '$baseServer/api/settings';

  // Gem
  static const String gemBase = '$baseServer/api/gem';

  // OAuth provider redirect (동적 사용 가능)
  static String oauthRedirect(String provider) => 'http://localhost:51577/api/auth/oauth/$provider/code';
}
