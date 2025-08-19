class ApiConstants {
  // --------------------------------
  // 서버 기본 URL
  // --------------------------------
  static const String baseServer = 'http://localhost:8000';

  // --------------------------------
  // 프론트 리다이렉트 URL (동적)
  // 실행 시 --dart-define=BASE_FRONTEND=https://xxxx.ngrok.io
  // --------------------------------
  static const String defaultFrontendUrl = 'http://localhost:51577';
  static String get frontendUrl =>
      const String.fromEnvironment('BASE_FRONTEND', defaultValue: defaultFrontendUrl);

  // --------------------------------
  // Auth 관련
  // --------------------------------
  static String get authBase => '$baseServer/api/auth';
  static String get tokenUrl => '$baseServer/api/auth/token';
  static String get googleRedirect => '$frontendUrl/api/auth/oauth/google/code';

  // OAuth provider redirect (동적)
  static String oauthRedirect(String provider) => '$frontendUrl/api/auth/oauth/$provider/code';


  // --------------------------------
  // Settings
  // --------------------------------
  static String get settingsBase => '$baseServer/api/settings/';

  // --------------------------------
  // Gem
  // --------------------------------
  static String get gemBase => '$baseServer/api/gem/';

  // --------------------------------
  // WebSocket
  // --------------------------------
  static String matchWs(String token) => 'ws://localhost:8000/ws/match/?token=$token';
  static String voiceChatWs(String roomName, String token) =>
      'ws://localhost:8000/ws/voicechat/$roomName/?token=$token';
}
