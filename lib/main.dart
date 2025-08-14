import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:tori_frontend/screens/match_screen.dart';
import 'package:tori_frontend/screens/signup_screen.dart';
import 'package:tori_frontend/screens/login_screen.dart';
import 'package:tori_frontend/screens/home_screen.dart';
import 'package:tori_frontend/screens/match_settings_screen.dart';
import 'package:tori_frontend/themes/app_theme.dart';
import 'package:recaptcha_v3/recaptcha_v3.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // reCAPTCHA v3 초기화만 수행
    Recaptcha.ready("6LdTfKUrAAAAAKUC1-PMOS-M_WzL47GUo-0zuqQX");
  } catch (e) {
    print('reCAPTCHA 초기화 오류: $e');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '랜덤통화 매칭 앱',
      theme: appTheme,
      home: LoginScreen(),
      routes: {
        '/signup': (context) => SignUpScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/match': (context) => MatchScreen(initialStatus: MatchStatus.searching),
        '/match_settings': (context) => MatchSettingsScreen(),
      },
    );
  }
}