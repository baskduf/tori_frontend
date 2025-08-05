import 'package:flutter/material.dart';
import 'package:tori_frontend/screens/match_screen.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'screens/signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/match_settings_screen.dart';
import 'themes/app_theme.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '랜덤통화 매칭 앱',
      theme: appTheme,
      initialRoute: '/login',
      routes: {
        '/signup': (context) => SignUpScreen(),
        '/login': (context) => LoginScreen(),
        '/home': (context) => HomeScreen(),
        '/match': (context) => MatchScreen(),
        '/match_settings': (context) => MatchSettingsScreen(),
      },
    );
  }
}
