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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('로그아웃 실패')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
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

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: '홈',
      showBack: false,
      appBarActions: [
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: '매칭 설정',
          onPressed: _goToMatchSettings,
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: '로그아웃',
          onPressed: _logout,
        ),
      ],
      child: Center(
        child: _isLoggingOut
            ? const CircularProgressIndicator()
            : PrimaryButton(
          text: '시작하기',
          onPressed: _goToMatchScreen,
          width: 150,
          height: 45,
          color: Colors.blueAccent,
        ),
      ),
    );
  }
}
