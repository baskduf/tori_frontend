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


  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: '홈',
      showBack: false,
      child: Center(
        child: _isLoggingOut
            ? const CircularProgressIndicator()
            : PrimaryButton(
          text: '로그아웃',
          onPressed: _logout,
          width: 150,
          height: 45,
          color: Colors.redAccent,
        ),
      ),
    );
  }
}
