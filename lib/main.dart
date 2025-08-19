import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'providers/auth_provider.dart';
import 'widgets/google_oauth_callback.dart';
import 'screens/signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/match_screen.dart';
import 'screens/match_settings_screen.dart';
import 'screens/gem_store_screen.dart'; // ✅ 추가
import 'themes/app_theme.dart';
import 'package:recaptcha_v3/recaptcha_v3.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    Recaptcha.ready("6LdTfKUrAAAAAKUC1-PMOS-M_WzL47GUo-0zuqQX");
  } catch (e) {
    print('reCAPTCHA 초기화 오류: $e');
  }

  final apiService = ApiService();
  final authProvider = AuthProvider(apiService: apiService);
  await authProvider.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authProvider),
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
      final uri = Uri.parse(html.window.location.href);

      // 해시(#)에서 코드 추출
      if (uri.fragment.startsWith('code=')) {
        _oauthCode = uri.fragment.substring(5);
        if (kDebugMode) print('해시에서 추출한 OAuth 코드: $_oauthCode');
      }
      // 쿼리 파라미터에서 코드 추출
      else if (uri.queryParameters.containsKey('code')) {
        _oauthCode = uri.queryParameters['code'];
        if (kDebugMode) print('쿼리에서 추출한 OAuth 코드: $_oauthCode');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return MaterialApp(
      title: 'TORI - 새로운 인연과의 만남',
      theme: appTheme,
      home: _buildInitialScreen(auth),
      routes: {
        '/signup': (_) => const SignUpScreen(),
        '/login': (_) => const LoginScreen(),
        '/home': (_) => const HomeScreen(),
        '/match': (_) => const MatchScreen(initialStatus: MatchStatus.searching),
        '/match_settings': (_) => const MatchSettingsScreen(),
        '/gem_store': (_) => const GemStoreScreen(), // ✅ 추가
      },
    );
  }

  Widget _buildInitialScreen(AuthProvider auth) {
    // URL이 OAuth 콜백이면 무조건 callback 화면
    final uri = Uri.parse(html.window.location.href);
    final isOAuthCallback = uri.path == '/api/auth/oauth/google/code';

    if (!_handledOAuthCode && isOAuthCallback) {
      _handledOAuthCode = true;
      return OAuthCallbackScreen(code: _oauthCode); // 코드 없으면 null
    }

    // 로그인 상태에 따라 초기 화면 선택
    return auth.accessToken == null ? const LoginScreen() : const HomeScreen();
  }
}
