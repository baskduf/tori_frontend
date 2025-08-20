import 'dart:ui';
// 웹 플랫폼에서만 임포트
import 'dart:html' as html show window;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/api_client.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../services/gem_api.dart';
import '../widgets/logo_widget.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final ApiService apiService = ApiService();
  bool _isLoggingOut = false;
  late GemApi _api;
  int? _balance; // 젬 잔액


  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _bootstrap(); // 초기화 시 잔액 가져오기

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      bool success = await apiService.logout();

      if (success) {
        if (!mounted) return;

        // 방법 1: 완전한 페이지 새로고침과 함께 이동 (추천)
        if (kIsWeb) {
          html.window.location.href = '/login';
          return; // 페이지가 새로고침되므로 아래 코드는 실행되지 않음
        }

        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      } else {
        if (!mounted) return;
        _showSnackBar('로그아웃 실패');
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('오류 발생: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoggingOut = false;
        });
      }
    }
  }

  void _goToMatchSettings() {
    Navigator.pushNamed(context, '/match_settings');
  }

  void _goToMatchScreen() {
    Navigator.pushNamed(context, '/match');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        backgroundColor: Colors.redAccent.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _bootstrap() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final token = auth.accessToken;
    if (token == null) {
      _snack('로그인 후 이용해주세요.');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final apiClient = ApiClient(authProvider: authProvider, navigatorKey: navigatorKey);
    _api = GemApi(apiClient: apiClient);
    try {
      final bal = await _api.fetchWallet(); // 서버에서 현재 젬 잔액 가져오기
      setState(() => _balance = bal);      // 가져온 잔액을 화면에 반영
    } catch (e) {
      _snack('잔액 조회 실패: 세션이 만료되었습니다.');          // 에러 발생 시 사용자에게 안내
    }
    // if (!kIsWeb) await _initMobileStore();
  }

  void _snack(String message, {SnackBarAction? action}) {
    if (!mounted) return; // 비동기 이후 안전 가드
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,   // AppBar/SafeArea와 겹침 방지
        duration: const Duration(seconds: 3),
        action: action,
        margin: const EdgeInsets.all(12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color(0xFF121212);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(' '),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // 💎 젬 잔액 UI
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white24, width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.diamond, color: Colors.amber, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    "${_balance ?? 0}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/gem_store'),
                    child: Container(
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.amber,
                      ),
                      padding: const EdgeInsets.all(2),
                      child: const Icon(Icons.add, size: 18, color: Colors.black87),
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '매칭 설정',
            onPressed: _goToMatchSettings,
            splashRadius: 24,
            color: Colors.white70,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: _isLoggingOut ? null : _logout,
            splashRadius: 24,
            color: _isLoggingOut ? Colors.grey : Colors.white70,
          ),
        ],
      ),
      backgroundColor: backgroundColor,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 배경 그라데이션
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0B0B0B), Color(0xFF1E1E1E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Glassmorphism + Pulse 애니메이션 버튼
          Align(
            alignment: const Alignment(0, 0.6),
            child: ScaleTransition(
              scale: _pulseAnimation,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    width: 220,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.25),
                        width: 1.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.18),
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.6),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: _isLoggingOut
                        ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.2,
                            valueColor: AlwaysStoppedAnimation(Colors.white70),
                          ),
                        ),
                        SizedBox(width: 14),
                        Text(
                          '로그아웃 처리 중...',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                            shadows: [
                              Shadow(
                                color: Colors.black38,
                                offset: Offset(1, 1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                        : TextButton(
                      onPressed: _goToMatchScreen,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(32),
                        ),
                      ).copyWith(
                        overlayColor: MaterialStateProperty.resolveWith<Color?>(
                              (states) {
                            if (states.contains(MaterialState.pressed)) {
                              return Colors.white24;
                            }
                            return null;
                          },
                        ),
                      ),
                      child: const Text(
                        '시작하기',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              offset: Offset(1, 2),
                              blurRadius: 3,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // LogoWidget
          Align(
            alignment: const Alignment(0, -0.5),
            child: const Logo(),
          ),

          // ⚙ 매칭 설정 말풍선 (AppBar 밖에서 표시)
          Positioned(
            top: MediaQuery.of(context).padding.top + 50,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "조건에 맞는 매칭을 설정하세요 ",
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  Text("😊", style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }


}
