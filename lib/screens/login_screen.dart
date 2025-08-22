import 'dart:convert';

import 'package:flutter/material.dart';
import '../main.dart';
import '../services/auth_service.dart';
import '../widgets/logo_widget.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/app_footer_info_widget.dart';
import '../api/api_constants.dart';
import 'package:flutter/foundation.dart';
// import 'dart:js' as js;
import 'package:url_launcher/url_launcher.dart';
// import 'dart:html' as html;
import '../layouts/responsive_scaffold.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _apiService = ApiService();


  Future<void> _googleLoginRedirect() async {  // <-- async 추가
    final clientId = '946190465802-87b8ua61njftieqp6q4lhkme255q2tqa.apps.googleusercontent.com';
    final redirectUri = ApiConstants.googleRedirect;

    final authUrl =
        'https://accounts.google.com/o/oauth2/v2/auth'
        '?client_id=$clientId'
        '&redirect_uri=$redirectUri'
        '&response_type=code'
        '&scope=email%20profile%20openid';

    final uri = Uri.parse(authUrl);
    if (kIsWeb) {
      // 웹: 현재 창에서 열기
      if (!await launchUrl(uri, mode: LaunchMode.platformDefault)) {
        throw 'Could not launch $authUrl';
      }
    } else {
      // 모바일: 외부 브라우저
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $authUrl';
      }
    }
  }


  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  late AnimationController _buttonController;
  late Animation<double> _buttonScaleAnimation;

  FocusNode _usernameFocus = FocusNode();
  FocusNode _passwordFocus = FocusNode();

  @override
  void initState() {
    super.initState();

    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
      lowerBound: 0.95,
      upperBound: 1.0,
      value: 1.0,
    );

    _buttonScaleAnimation = _buttonController.drive(
      Tween<double>(begin: 1.0, end: 0.95),
    );

    _usernameFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFF121212);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Logo(),
                const SizedBox(height: 40),


                const SizedBox(height: 24),

                Column(
                  children: [

                    const SizedBox(height: 12),

                    // 기존 onTap 코드 일부 정리
                    GestureDetector(
                      onTap: () async {
                        setState(() => _isLoading = true);
                        try {
                          if (kIsWeb) {
                            // Flutter Web: GIS 팝업 로그인
                            _googleLoginRedirect();
                          } else {
                            // 모바일용 Google Sign-In
                            final result = await authProvider.loginWithGoogleMobile();

                            if (result == 'success') {
                              if (!mounted) return;
                              Navigator.pushReplacementNamed(context, '/home');
                            } else if (result.startsWith('signup_required:')) {
                              final payloadJson = result.substring('signup_required:'.length);
                              final payload = json.decode(payloadJson);

                              if (!mounted) return;
                              Navigator.pushReplacementNamed(
                                context,
                                '/signup',
                                arguments: {
                                  'name': payload['name'] ?? '',
                                  'profileUrl': payload['profile_url'] ?? '',
                                  'tempToken': payload['temp_token'],
                                },
                              );
                            } else {
                              // 실패 처리
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('로그인 실패: $result')),
                              );
                            }
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('구글 로그인 오류: $e')),
                          );
                        } finally {
                          setState(() => _isLoading = false);
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/icon/google_logo.svg',
                              height: 24,
                              width: 24,
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              '구글로 로그인',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  ],
                ),

                const SizedBox(height: 24),


                const AppFooterInfo(),


              ],
            ),
          ),
        ),
      ),
    );
  }
}
