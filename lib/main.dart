import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:tori_frontend/screens/match_screen.dart';
import 'package:tori_frontend/screens/signup_screen.dart';
import 'package:tori_frontend/screens/login_screen.dart';
import 'package:tori_frontend/screens/home_screen.dart';
import 'package:tori_frontend/screens/match_settings_screen.dart';
import 'package:tori_frontend/themes/app_theme.dart';
import 'package:recaptcha_v3/recaptcha_v3.dart';
import 'package:tori_frontend/services/auth_service.dart';
import 'package:tori_frontend/providers/auth_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    Recaptcha.ready("6LdTfKUrAAAAAKUC1-PMOS-M_WzL47GUo-0zuqQX");
  } catch (e) {
    print('reCAPTCHA 초기화 오류: $e');
  }

  final apiService = ApiService();
  final authProvider = AuthProvider(apiService: apiService);

  // 여기서 init() 완료까지 대기
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    return MaterialApp(
      title: 'TORI - 새로운 인연과의 만남',
      theme: appTheme,
      home: auth.accessToken == null
          ? const LoginScreen()
          : const HomeScreen(),
      routes: {
        '/signup': (context) => const SignUpScreen(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
        '/match': (context) => const MatchScreen(initialStatus: MatchStatus.searching),
        '/match_settings': (context) => const MatchSettingsScreen(),
      },
    );
  }
}
