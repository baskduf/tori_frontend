import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // --------------------------------
  // 서버 기본 URL
  // --------------------------------
  static final String baseServer = _getBaseServer();

  static String _getBaseServer() {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else if (Platform.isAndroid) {
      return 'http://10.0.2.2:8000';
    } else {
      return 'http://localhost:8000';
    }
  }

  // --------------------------------
  // 프론트 리다이렉트 URL (동적)
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
  static String get googleMobileLogin => '$baseServer/api/auth/mobile/google-login/';

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
  // Rewarded Ad
  // --------------------------------
  static String get rewardedAd => '${gemBase}rewarded_ad/';

  // --------------------------------
  // WebSocket
  // --------------------------------
  static String matchWs(String token) => 'ws://${_wsHost()}:8000/ws/match/?token=$token';
  static String voiceChatWs(String roomName, String token) =>
      'ws://${_wsHost()}:8000/ws/voicechat/$roomName/?token=$token';

  static String _wsHost() {
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) return '10.0.2.2';
    return 'localhost';
  }
}
