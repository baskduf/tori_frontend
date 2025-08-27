import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConstants {
  // --------------------------------
  // 서버 기본 URL (임시 배포용)
  // --------------------------------
  static final String baseServer = 'https://django-app-946190465802.us-central1.run.app';

  // --------------------------------
  // 프론트 리다이렉트 URL
  // --------------------------------
  static final String frontendUrl = 'https://tori-voice.web.app';

  // --------------------------------
  // Auth 관련
  // --------------------------------
  static String get authBase => '$baseServer/api/auth';
  static String get tokenUrl => '$baseServer/api/auth/token';
  static String get googleRedirect => '$frontendUrl/api/auth/oauth/google/code';
  static String get googleMobileLogin => '$baseServer/api/auth/mobile/google-login/';

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
  static String matchWs(String token) => 'wss://${_wsHost()}/ws/match/?token=$token';
  static String voiceChatWs(String roomName, String token) =>
      'wss://${_wsHost()}/ws/voicechat/$roomName/?token=$token';

  static String _wsHost() {
    // ngrok 백엔드는 HTTPS를 사용하므로 host만 반환
    return Uri.parse(baseServer).host;
  }

  // 실제 AdMob Rewarded 광고 단위 ID
  static String get rewardedAdUnitId {
    if (kIsWeb) {
      return ''; // 웹에서는 광고 없음
    } else if (Platform.isAndroid) {
      return 'ca-app-pub-9238483071028144/9553584981';
    } else if (Platform.isIOS) {
      return 'YOUR_IOS_AD_UNIT_ID';
    } else {
      return '';
    }
  }
}
