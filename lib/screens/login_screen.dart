import 'package:flutter/material.dart';
import '../api_service.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _apiService = ApiService();

  final _formKey = GlobalKey<FormState>();
  String username = '';
  String password = '';

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    bool success = await _apiService.login(username: username, password: password);
    if (success) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('로그인 실패')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('로그인')),
        body: Padding(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(labelText: '아이디'),
                  onSaved: (val) => username = val ?? '',
                  validator: (val) => val == null || val.isEmpty ? '필수 입력' : null,
                ),
                TextFormField(
                  decoration: InputDecoration(labelText: '비밀번호'),
                  obscureText: true,
                  onSaved: (val) => password = val ?? '',
                  validator: (val) => val == null || val.isEmpty ? '필수 입력' : null,
                ),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _submit,
                  child: Text('로그인'),
                ),
                TextButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: Text('회원가입 하러 가기'),
                )
              ],
            ),
          ),
        ));
  }
}
