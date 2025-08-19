import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:html' as html;
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
      final uri = Uri.parse(html.window.location.href);
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
    final uri = Uri.parse(html.window.location.href);
    final isOAuthCallback = uri.path == '/api/auth/oauth/google/code';

    if (!_handledOAuthCode && isOAuthCallback) {
      _handledOAuthCode = true;
      return OAuthCallbackScreen(code: _oauthCode);
    }

    return auth.accessToken == null ? const LoginScreen() : const HomeScreen();
  }
}
