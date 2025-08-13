import 'package:flutter/material.dart';
import '../layouts/main_layout.dart';
import '../widgets/primary_button.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService apiService = ApiService();
  bool _isLoggingOut = false;

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
    });

    try {
      bool success = await apiService.logout();

      if (success) {
        if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: '홈',
      showBack: false,
      appBarActions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: IconButton(
            icon: const Icon(Icons.settings),
            tooltip: '매칭 설정',
            onPressed: _goToMatchSettings,
            splashRadius: 24,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: IconButton(
            icon: const Icon(Icons.logout),
            tooltip: '로그아웃',
            onPressed: _isLoggingOut ? null : _logout,
            splashRadius: 24,
            color: _isLoggingOut ? Colors.grey : null,
          ),
        ),
      ],
      child: Center(
        child: _isLoggingOut
            ? Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(strokeWidth: 3),
            SizedBox(height: 16),
            Text(
              '로그아웃 처리 중...',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
        )
            : PrimaryButton(
          text: '시작하기',
          onPressed: _goToMatchScreen,
          width: 180,
          height: 50,
          color: Colors.blueAccent,
          borderRadius: 30,
          //elevation: 6,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
