import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../widgets/login_animation_widget.dart';

class OAuthCallbackScreen extends StatefulWidget {
  final String? code; // <- 인증 코드 전달받음

  const OAuthCallbackScreen({super.key, required this.code});

  @override
  State<OAuthCallbackScreen> createState() => _OAuthCallbackScreenState();
}

class _OAuthCallbackScreenState extends State<OAuthCallbackScreen> {
  String _status = '로그인 처리 중...';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _handleOAuthCallback();
  }

  void _handleOAuthCallback() async {
    final code = widget.code;
    if (code == null || code.isEmpty) {
      setState(() {
        _status = '인증 코드가 없습니다.';
        _isLoading = false;
      });
      return;
    }

    setState(() => _status = '인증 코드 확인: $code');

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // 서버로 code 전송 → JWT 또는 temp_token 발급
      final result = await authProvider.socialLogin(
        'google',
        code,
        username: '', // 최초 로그인은 빈 값
        profileImageFile: null,
      );

      if (result == 'success' || result == 'signup_success') {
        setState(() {
          _status = '로그인 성공!';
          _isLoading = false;
        });
        if (!mounted) return;


        Navigator.pushReplacementNamed(context, '/home');
      }
      // 회원가입 추가 정보 필요
      else if (result.startsWith('signup_required:')) {
        final payloadJson = result.substring('signup_required:'.length);
        final payload = json.decode(payloadJson);

        final name = payload['name'] ?? '';
        final profileUrl = payload['profile_url'] ?? '';
        final tempToken = payload['temp_token']; // ⚡ 서버에서 내려준 temp_token

        if (!mounted) return;
        Navigator.pushReplacementNamed(
          context,
          '/signup',
          arguments: {
            'name': name,
            'profileUrl': profileUrl,
            'tempToken': tempToken, // ✅ 회원가입 시 반드시 같이 전달
          },
        );
      } else {
        setState(() {
          _status = '로그인 실패: $result';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _status = 'OAuth 처리 오류: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: LoginAnimationWidget(), // 여기서 기존 Container 대신 교체
      ),
    );
  }


}
