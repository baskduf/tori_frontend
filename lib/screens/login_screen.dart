import 'package:flutter/material.dart';
import '../layouts/main_layout.dart';
import '../services/auth_service.dart';
import '../widgets/logo_widget.dart';
import 'package:tori_frontend/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:google_sign_in/google_sign_in.dart';

import 'package:flutter/foundation.dart';

import 'dart:js' as js;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _apiService = ApiService();

// Google 로그인 버튼 클릭 시
  void _handleGoogleLoginWeb() {
    final clientId = '946190465802-87b8ua61njftieqp6q4lhkme255q2tqa.apps.googleusercontent.com';
    final redirectUri = 'http://localhost:51577/api/auth/oauth/google/code';

    // GIS 팝업 실행
    js.context.callMethod('googleLoginPopup', [clientId, redirectUri]);
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

  void _onTapDown(TapDownDetails details) {
    _buttonController.reverse();
  }

  void _onTapUp(TapUpDetails details) {
    _buttonController.forward();
  }

  void _onTapCancel() {
    _buttonController.forward();
  }





  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final result = await authProvider.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );

    setState(() => _isLoading = false);

    if (result == 'success') {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          backgroundColor: const Color(0xFF121212),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  BoxDecoration _neumorphicDecoration({bool isFocused = false}) {
    final baseColor = const Color(0xFF2E2E2E);
    final shadowColorDark = Colors.black.withOpacity(0.8);
    final shadowColorLight = Colors.grey.shade800;

    return BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(20),
      boxShadow: isFocused
          ? [
        BoxShadow(
          color: Colors.blueAccent.withOpacity(0.7),
          offset: const Offset(-5, -5),
          blurRadius: 15,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: shadowColorDark,
          offset: const Offset(5, 5),
          blurRadius: 15,
          spreadRadius: 1,
        ),
      ]
          : [
        BoxShadow(
          color: shadowColorLight,
          offset: const Offset(-5, -5),
          blurRadius: 10,
          spreadRadius: 1,
        ),
        BoxShadow(
          color: shadowColorDark,
          offset: const Offset(5, 5),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = const Color(0xFF1E1E1E);

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

                // 소셜 로그인 버튼
                // 소셜 로그인 버튼
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
                            _handleGoogleLoginWeb();
                          } else {
                            // 모바일용 google_sign_in 제거
                            // 이제 Web에서만 GIS 팝업 사용
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





                    // Apple도 동일하게 구현 가능
                  ],
                ),


                const SizedBox(height: 24),


              ],
            ),
          ),
        ),
      ),
    );
  }
}
