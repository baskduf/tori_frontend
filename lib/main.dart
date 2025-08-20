import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'providers/auth_provider.dart';
import 'api/api_client.dart';
import 'services/match_service.dart';
import 'screens/signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/match_screen.dart';
import 'screens/match_settings_screen.dart';
import 'screens/gem_store_screen.dart';
import 'widgets/google_oauth_callback.dart';
import 'themes/app_theme.dart';
import 'package:recaptcha_v3/recaptcha_v3.dart';
import 'api/api_constants.dart'; // ApiConstants impor
import 'package:flutter_web_plugins/url_strategy.dart';// t

// --------------------
// 1️⃣ 전역 navigatorKey
// --------------------
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// --------------------
// 2️⃣ 전역 서비스
// --------------------
late final AuthProvider authProvider;
late final ApiClient apiClient;
late final MatchService matchService;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // reCAPTCHA
  try {
    Recaptcha.ready("6LdTfKUrAAAAAKUC1-PMOS-M_WzL47GUo-0zuqQX");
  } catch (e) {
    print('reCAPTCHA 초기화 오류: $e');
  }

  // 서비스 초기화
  final apiService = ApiService();
  authProvider = AuthProvider(apiService: apiService);
  await authProvider.init();

  apiClient = ApiClient(authProvider: authProvider, navigatorKey: navigatorKey);
  matchService = MatchService(apiClient: apiClient);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
        Provider.value(value: matchService),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _handledOAuthCode = false;
  String? _oauthCode;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      final uri = Uri.base; // dart:html 없이 현재 URL 가져오기
      if (uri.fragment.startsWith('code=')) {
        _oauthCode = uri.fragment.substring(5);
      } else if (uri.queryParameters.containsKey('code')) {
        _oauthCode = uri.queryParameters['code'];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'TORI - 새로운 인연과의 만남',
      theme: appTheme,
      home: _buildInitialScreen(auth),
      routes: {
        '/signup': (_) => const SignUpScreen(),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/match': (_) => const MatchScreen(initialStatus: MatchStatus.searching),
        '/match_settings': (_) => const MatchSettingsScreen(),
        '/gem_store': (_) => const GemStoreScreen(),
      },
    );
  }

  Widget _buildInitialScreen(AuthProvider auth) {
    // dart:html 없이 현재 URL 가져오기
    final uri = Uri.base;
    print(uri);

    // --------------------
    // OAuth 리디렉션 처리
    // --------------------
    final isOAuthCallback = uri.path == Uri.parse(ApiConstants.googleRedirect).path;
    if (!_handledOAuthCode && isOAuthCallback) {
      _handledOAuthCode = true;

      // fragment 또는 query parameter에서 code 추출
      String? code;
      if (uri.fragment.startsWith('code=')) {
        code = uri.fragment.substring(5);
      } else if (uri.queryParameters.containsKey('code')) {
        code = uri.queryParameters['code'];
      }

      return OAuthCallbackScreen(code: code);
    }

    // --------------------
    // 로그인 상태에 따른 초기 화면
    // --------------------
    return auth.accessToken == null ? const LoginScreen() : const HomeScreen();
  }


}