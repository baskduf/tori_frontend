import 'package:flutter/material.dart';
import '../api_service.dart';

class HomeScreen extends StatelessWidget {
  final ApiService apiService = ApiService();

  void _logout(BuildContext context) async {
    bool success = await apiService.logout();
    if (success) {
      Navigator.pushReplacementNamed(context, '/login');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그아웃 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('홈'),
          actions: [
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () => _logout(context),
            )
          ],
        ),
        body: Center(child: Text('로그인 성공!')));
  }
}
